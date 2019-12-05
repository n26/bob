/*
 * Copyright (c) 2017 N26 GmbH.
 *
 * This file is part of Bob.
 *
 * Bob is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Bob is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Bob.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import HTTP
import Vapor

/// Struct representing a script
/// Additional config can also be provided
/// and it will be passed to TravisCI API
public struct Script {
    let content: String
    let config: [String: Any]
    public init(_ content: String, config: [String: Any] = [:]) {
        self.content = content
        self.config = config
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    func makeJSON() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self, options: [])
    }
}

public struct BuildParams {
    public enum Config {
        case script(Script)
        case env([String: Any])

        func dict() -> [String: Any] {
            switch self {
            case .script(let script):
                var config = script.config
                config["script"] = script.content
                return config
            case .env(let env):
                return env
            }
        }
    }

    let branch: String
    let config: Config

    public init(branch: String, config: Config) {
        self.branch = branch
        self.config = config
    }
}

/// Used for communication with TravisCI api
public class TravisCI {
    /// Configuration needed for authentication with the api
    public struct Configuration {
        /// Url of the repo. Along the lines of https://api.travis-ci.com/repo/{owner%2Frepo}
        public let repoUrl: String

        public var dashboardUrl: String {
            return (repoUrl.removingPercentEncoding ?? repoUrl)
                .replacingOccurrences(of: "api.", with: "")
                .replacingOccurrences(of: "/repo", with: "")
        }
        /// Access token
        public let token: String
        public init(repoUrl: String, token: String) {
            self.repoUrl = repoUrl
            self.token = token
        }
    }
    
    private let config: Configuration
    private let container: Container

    public var worker: Worker {
        return container
    }

    private lazy var headers: HTTPHeaders = {
        var headers = HTTPHeaders()
        headers.add(name: HTTPHeaderName.accept, value: "application/json")
        headers.add(name: HTTPHeaderName.authorization, value: "token \(config.token)")
        headers.add(name: "Travis-API-Version", value: "3")
        headers.add(name: HTTPHeaderName.contentType, value: "application/json")
        return headers
    }()

    /// Initializes the object with provided configuration
    ///
    /// - Parameter config: Configuration to use
    public init(config: Configuration, container: Container) {
        self.config = config
        self.container = container
    }
    
    /// Triggers a TravisCI job executing a script named `script`
    ///
    /// - Parameters:
    ///   - script: Script to execute. The script should be in the repo
    ///   - branch: Branch to use when executing the script
    public func execute(_ script: Script, on branch: String) throws -> Future<TravisCI.Requests.Response> {
        let uri = self.config.repoUrl + "/requests"
        var config = script.config
        config["script"] = script.content

        let body: [String: Any] = [
            "request": [
                "branch": branch,
                "config": config
            ]
        ]

        let futureResponse = try container.client().post(uri, headers: headers) { request in
            request.http.body = HTTPBody(data: try body.makeJSON())
        }

        return futureResponse.flatMap { response in
            return try self.container.client().decode(response: response, using: .travis)
        }
    }

    public func execute(title: String, buildParameters: BuildParams) throws -> Future<TravisCI.Requests.Response> {
        let uri = self.config.repoUrl + "/requests"

        let body = [
            "request": [
                "message": title,
                "branch": buildParameters.branch,
                "config": buildParameters.config.dict()
            ]
        ]

        let futureResponse = try container.client().post(uri, headers: headers) { request in
            request.http.body = HTTPBody(data: try body.makeJSON())
        }

        return futureResponse.flatMap { response in
            return try self.container.client().decode(response: response, using: .travis)
        }
    }

    /// GET /requests
    public func requests() throws -> Future<TravisCI.Requests> {
        return try get(uri(at: "/requests"))
    }

    /// GET /request/{requestId}
    public func request(id: Request.ID) throws -> Future<TravisCI.Request> {
        return try get(uri(at: "/request/\(id)"))
    }

    public enum Poll<PollResult> {
        case `continue`
        case stop(PollResult)
    }

    /// Polls the /request/{requestId} endpoint until the the `until` returns `.stop`
    ///
    /// ```
    ///     try self.travis.poll(requestId: 123) { request -> TravisCI.Poll<String> in
    ///         switch request.state {
    ///         case .pending:
    ///            return .continue
    ///         case .complete(let completedRequest):
    ///             return .stop(completedRequest.commit.message)
    ///         }
    ///     }.map { result in
    ///         print("Travis request commit is \(result)")
    ///     }
    /// ```
    ///
    /// - Parameter id: The id of the Travis request
    /// - Parameter until: Closure called on each poll call. Return `.continue` if a next poll should be set or `.stop` with an associated generic value of the polling should stop

    public func poll<PollResult>(requestId: Request.ID, until: @escaping (TravisCI.Request) -> Poll<PollResult>) throws -> Future<PollResult> {
        let promise = container.eventLoop.newPromise(PollResult.self)
        try doPoll(requestId: requestId, until: until, promise: promise)
        return promise.futureResult
    }

    private func doPoll<PollResult>(requestId id: Request.ID, until: @escaping (TravisCI.Request) -> Poll<PollResult>, promise: Promise<PollResult>) throws {
        _ = try request(id: id).map { request in
            let poll = until(request)
            switch poll {
            case .continue:
                self.container.eventLoop.scheduleTask(in: TimeAmount.seconds(TimeAmount.Value(1))) {
                    try self.doPoll(requestId: id, until: until, promise: promise)
                }
            case .stop(let result):
                promise.succeed(result: result)
            }
        }.catch { error in
            promise.fail(error: error)
        }
    }

    public func buildURL(from build: TravisCI.Build) -> URL {
        let url = URL(string: config.dashboardUrl + "/builds/\(build.id)")!
        return url
    }
    // MARK: - Private

    private func uri(at path: String) -> String {
        return self.config.repoUrl + path
    }

    private func get<T: Decodable>(_ uri: String) throws -> Future<T> {
        return try container.client().get(uri, using: .travis, headers: headers)
    }
}
