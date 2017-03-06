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
    /// Initializes the object with provided configuration
    ///
    /// - Parameter config: Configuration to use
    public init(config: Configuration) {
        self.config = config
    }
    
    
    /// Triggers a TravisCI job executing a script named `script`
    ///
    /// - Parameters:
    ///   - script: Script to execute. The script should be in the repo
    ///   - branch: Branch to use when executing the script
    ///   - completion: Closure called when the job is triggered. An error is passed if it happens
    public func execute(_ script: Script, on branch: BranchName, completion: @escaping (_ error: Error?) -> Void) {
        var config = script.config
        config["script"] = script.content
        let body: [String: Any] = [
            "request": [
                "branch": branch.name,
                "config": config
                ] as [String: Any]
        ]
        /// Convert is to `NSDictionary` so that the serialization 
        /// doesn't fail
        let nsBody = NSDictionary(dictionary: body)
        
        guard let url = URL(string: self.config.repoUrl)?.appendingPathComponent("requests") else {
            completion("Invalid travis repo URL \(self.config.repoUrl)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("token " + self.config.token, forHTTPHeaderField: "Authorization")
        request.addValue("3", forHTTPHeaderField: "Travis-API-Version")
        request.httpBody = try! JSONSerialization.data(withJSONObject: nsBody, options: .prettyPrinted)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            completion(error)
        })
        task.resume()
    }
    
}
