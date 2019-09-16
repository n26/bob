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

/// Used for communication with TravisCI api
public class TravisCI {
    /// Configuration needed for authentication with the api
    public struct Configuration {
        /// Url of the repo. Along the lines of https://api.travis-ci.com/repo/{owner%2Frepo}
        public let repoUrl: String
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
        headers.add(name: HTTPHeaderName.accept, value: "")
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
    public func execute(_ script: Script, on branch: String) throws -> Future<Bool> {
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

        return futureResponse.map { response in
            return response.http.status.isSuccessfulRequest
        }
    }
}
