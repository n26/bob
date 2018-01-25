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
import Vapor
import HTTP

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
    func makeJSON() throws -> JSON {
        var result: [String: NodeRepresentable] = [:]
        for (key, value) in self {
            guard let keyString = key as? String else { throw "Key is not a string" }
            if let stringValue = value as? String {
                result.updateValue(stringValue, forKey: keyString)
            } else if let dictValue = value as? [String: Any] {
                result.updateValue(try dictValue.makeJSON(), forKey: keyString)
            } else if let arrayValue = value as? [[String: Any]] {
                let array = try arrayValue.map({ try $0.makeJSON() })
                result.updateValue(try JSON(node: array), forKey: keyString)
            } else {
                throw "Unsupported type: \(value)"
            }
        }
        return try JSON(node: result)
    }
}

/// Used for communication with TravisCI api
public final class TravisCI {
    
    
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
    private let client: ClientFactoryProtocol
    /// Initializes the object with provided configuration
    ///
    /// - Parameter config: Configuration to use
    /// - Parameter client: HTTP Client factory to use
    public init(config: Configuration, client: ClientFactoryProtocol) {
        self.config = config
        self.client = client
    }
    
    
    /// Triggers a TravisCI job executing a script named `script`
    ///
    /// - Parameters:
    ///   - script: Script to execute. The script should be in the repo
    ///   - branch: Branch to use when executing the script
    public func execute(_ script: Script, on branch: BranchName) throws {
        let uri = self.config.repoUrl + "/requests"
        var config = script.config
        config["script"] = script.content
        
        let parameters = try JSON(node: [
            "request": try JSON(node: [
                "branch": branch.name,
                "config": try config.makeJSON()
                ])
            ])
        
        let request = Request(method: .post, uri: uri, body: parameters.makeBody())
        request.headers[HeaderKey("Authorization")] = "token " + self.config.token
        request.headers[HeaderKey("Travis-API-Version")] = "3"
        request.headers[HeaderKey("Content-Type")] = "application/json"
        
        let response = try self.client.respond(to: request)
        if !response.status.isSuccessfulRequest {
            throw "Error: `" + request.uri.description + "` - " + response.status.reasonPhrase
        }
    }
}


extension Config {
    /// Resolves configured Travis CI configuration
    func resolveTravisConfiguration() throws -> TravisCI.Configuration {
        guard let url = self[Bob.configFile, "travis-repo-url"]?.string else {
            throw "Unable to find Travis CI repo URL. It should be found in \" Configs/bob.json\" under the key \"travis-repo-url\"."
        }

        guard let token = self[Bob.configFile, "travis-token"]?.string else {
            throw "Unable to find Travis CI access token. It should be found in \" Configs/bob.json\" under the key \"travis-token\"."
        }
        return TravisCI.Configuration(repoUrl: url, token: token)
    }
}

extension TravisCI: ConfigInitializable {
    public convenience init(config: Config) throws {
        let configuration = try config.resolveTravisConfiguration()
        let client = try config.resolveClient()
        self.init(config: configuration, client: client)
    }
}
