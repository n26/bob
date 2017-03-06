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

fileprivate extension URLRequest {
    
    var absoluteUrlString: String {
        return self.url?.absoluteString ?? ""
    }
    
}
fileprivate extension URLRequest {
    
    mutating func setBodyToMatch(parameters: [String: Any]) throws {
        let paramsData = try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions(rawValue: 0))
        self.httpBody = paramsData
    }
    
}

/// Struct representin an item in the tree - files
public struct TreeItem {
    public let path: String
    public let mode: String
    public let type: String
    public let sha: String
    public init(path: String, mode: String, type: String, sha: String) {
        self.path = path
        self.mode = mode
        self.type = type
        self.sha = sha
    }
}

/// Struct representing an author
public struct Author {
    public let name: String
    public let email: String
    public init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}

/// Struct representing a Branch.
/// Only contains name since it is the only
/// property used by current functionality
public struct Branch {
    public let name: String
    public init(name: String) {
        self.name = name
    }
}

/// Struct representing a branch name
/// Used to enforce compiler safety
public struct BranchName {
    public let name: String
    public init(_ name: String) {
        self.name = name
    }
}

/// Used for communicating with the GitHub api
public class GitHub {
    
    /// Configuration needed for authentication with the api
    public struct Configuration {
        public let username: String
        public let personalAccessToken: String
        public let repoUrl: String
        /// Initializer for the configuration
        ///
        /// - Parameters:
        ///   - username: Username of a user
        ///   - personalAccessToken: Personal access token for that user. Make sure it has repo read/write for the repo you intend to use
        ///   - repoUrl: Url of the repo. Alogn the lines of https://api.github.com/repos/{owner}/{repo}
        public init(username: String, personalAccessToken: String, repoUrl: String) {
            self.username = username
            self.personalAccessToken = personalAccessToken
            self.repoUrl = repoUrl
        }
    }
    
    private let base64LoginData: String
    private let repoUrl: String
    public init(config: Configuration) {
        let authString = config.username + ":" + config.personalAccessToken
        self.base64LoginData = authString.data(using: .utf8)!.base64EncodedString()
        self.repoUrl = config.repoUrl
    }
    
    private func request(for path: String) -> URLRequest {
        let urlString = self.repoUrl + path
        let url = URL(string: urlString)!
        
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    private func execute<T>(_ request: URLRequest, process: @escaping (Any) throws -> T, success: @escaping (T) -> Void, failure: @escaping (Error) -> Void) {
        URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    let object = try process(json)
                    success(object)
                } catch {
                    failure(error)
                }
            } else if let error = error {
                failure(error)
            } else {
                failure("Inconsistent response from `\(request.absoluteUrlString)`: data == null, error == null")
            }
            }.resume()
    }
    
    public func existingBranches(success: @escaping (_ branches: [Branch]) -> Void, failure: @escaping (_ error: Error) -> Void) {
        let request = self.request(for: "/branches")
        
        self.execute(request, process: { (response) -> [Branch] in
            guard let json = response as? [[String: Any]] else { throw "Expected an array of dictionaries from `\(request.absoluteUrlString)`" }
            let branches = try json.map({ (dict) -> Branch in
                guard let name = dict["name"] as? String else { throw "Expected `branch` object to contain a `name` peoperty in the response from `\(request.absoluteUrlString)`" }
                return Branch(name: name)
            })
            return branches
        }, success: success, failure: failure)
    }
    
    public func currentCommitSHA(on branch: BranchName, success: @escaping (_ commitSHA: String) -> Void, failure: @escaping (_ error: Error) -> Void) {
        let request = self.request(for: "/branches/" + branch.name)
        
        self.execute(request, process: { (response) -> String in
            guard let json = response as? [String: Any] else { throw "Expected a dictionary from `\(request.absoluteUrlString)`" }
            guard let commit = json["commit"] as? [String: Any] else { throw "Missing or invalid `commit` field in response from `\(request.absoluteUrlString)`" }
            guard let commitSHA = commit["sha"] as? String else { throw "Missing or invalid `sha` field in the `commit` object of the response from `\(request.absoluteUrlString)`" }
            return commitSHA
        }, success: success, failure: failure)
    }
    
    public func treeSHA(forCommitWith commitSHA: String, success: @escaping (_ treeSHA: String) -> Void, failure: @escaping (_ error: Error) -> Void) {
        let request = self.request(for: "/git/commits/" + commitSHA)
        
        self.execute(request, process: { (response) -> String in
            guard let json = response as? [String: Any] else { throw "Expected a dictionary from `\(request.absoluteUrlString)`" }
            guard let tree = json["tree"] as? [String: Any] else { throw "Missing or invalid `tree` field in response from `\(request.absoluteUrlString)`" }
            guard let treeSHA = tree["sha"] as? String else { throw "Missing or invalid `sha` field in the `tree` object of the response from `\(request.absoluteUrlString)`" }
            return treeSHA
        }, success: success, failure: failure)
        
    }
    
    public func treeItems(forTreeWith treeSHA: String, success: @escaping (_ items: [TreeItem]) -> Void, failure: @escaping (_ error: Error) -> Void) {
        let request = self.request(for: "/git/trees/" + treeSHA + "?recursive=1")
        
        self.execute(request, process: { (response) -> [TreeItem] in
            guard let json = response as? [String: Any] else { throw "Expected a dictionary from `\(request.absoluteUrlString)`" }
            guard let tree = json["tree"] as? [[String: Any]] else { throw "Missing or invalid `tree` field in response from `\(request.absoluteUrlString)`" }
            let items = try tree.map({ (dict) throws -> TreeItem in
                guard let path = dict["path"] as? String else { throw "Missing or invalid `path` field in one of the tree items in the response for `\(request.absoluteUrlString)`.\nRaw item: `\(dict)`" }
                guard let mode = dict["mode"] as? String else { throw "Missing or invalid `mode` field in one of the tree items in the response for `\(request.absoluteUrlString)`.\nRaw item: `\(dict)`" }
                guard let type = dict["type"] as? String else { throw "Missing or invalid `type` field in one of the tree items in the response for `\(request.absoluteUrlString)`.\nRaw item: `\(dict)`" }
                guard let sha = dict["sha"] as? String else { throw "Missing or invalid `sha` field in one of the tree items in the response for `\(request.absoluteUrlString)`.\nRaw item: `\(dict)`" }
                return TreeItem(path: path, mode: mode, type: type, sha: sha)
            })
            
            return items
        }, success: success, failure: failure)
    }
    
    public func content(forBlobWith blobSHA: String, success: @escaping (_ content: String) -> Void, failure: @escaping (_ error: Error) -> Void) {
        let request = self.request(for: "/git/blobs/" + blobSHA)
        
        self.execute(request, process: { (response) -> String in
            guard let json = response as? [String: Any] else { throw "Expected a dictionary from `\(request.absoluteUrlString)`" }
            guard var contentBase64 = json["content"] as? String else { throw "Missing or invalid `content` field in response from `\(request.absoluteUrlString)`" }
            /*
             * Remove pretty formatting Github applies
             */
            contentBase64 = contentBase64.replacingOccurrences(of: "\n", with: "", options: [])
            
            guard let contentData = Data(base64Encoded: contentBase64) else { throw "Invalid base64 string from `\(request.absoluteUrlString)`\n\(contentBase64)" }
            guard let content = String(data: contentData, encoding: .utf8) else { throw "Cannot create a string from base64 content retrieved from `\(request.absoluteUrlString)`\n\(contentBase64)" }
            
            return content
        }, success: success, failure: failure)
        
    }
    
    public func newBlob(with content: String, success: @escaping (_ blobSHA: String) -> Void, failure: @escaping (_ error: Error) -> Void) {
        var request = self.request(for: "/git/blobs")
        
        do {
            try request.setBodyToMatch(parameters: ["content": content])
            request.httpMethod = "POST"
            
            self.execute(request, process: { (response) -> String in
                guard let json = response as? [String: Any] else { throw "Expected a dictionary from `\(request.absoluteUrlString)`" }
                guard let sha = json["sha"] as? String else { throw "Missing or invalid `sha` field in response from `\(request.absoluteUrlString)`" }
                return sha
            }, success: success, failure: failure)
            
        } catch {
            failure(error)
        }
    }
    
    public func newTree(withBaseSHA baseSHA: String, items: [TreeItem], success: @escaping (_ treeSHA: String) -> Void, failure: @escaping (_ error: Error) -> Void) {
        var request = self.request(for: "/git/trees")
        do {
            let tree = items.map { (item) -> [String: Any] in
                return [
                    "path": item.path,
                    "mode": item.mode,
                    "type": item.type,
                    "sha": item.sha
                ]
            }
            let parameters: [String: Any] = ["base_tree": baseSHA, "tree": tree]
            try request.setBodyToMatch(parameters: parameters)
            request.httpMethod = "POST"
            
            self.execute(request, process: { (response) -> String in
                guard let json = response as? [String: Any] else { throw "Expected a dictionary from `\(request.absoluteUrlString)`" }
                guard let sha = json["sha"] as? String else { throw "Missing or invalid `sha` field in response from `\(request.absoluteUrlString)`" }
                return sha
            }, success: success, failure: failure)
            
        } catch {
            failure(error)
        }
        
    }
    
    public func newCommit(by author: Author, message: String, parentSHA: String, treeSHA: String, success: @escaping (_ commitSHA: String) -> Void, failure: @escaping (_ error: Error) -> Void) {
        
        var request = self.request(for: "/git/commits")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let date = dateFormatter.string(from: Date()).appending("Z")
        let author: [String: Any] = [
            "name": author.name,
            "email": author.email,
            "date": date
        ]
        
        let parameters: [String: Any] = [
            "message": message,
            "tree": treeSHA,
            "parents": [parentSHA],
            "author": author
        ]
        
        do {
            try request.setBodyToMatch(parameters: parameters)
            request.httpMethod = "POST"
            
            self.execute(request, process: { (response) -> String in
                guard let json = response as? [String: Any] else { throw "Expected a dictionary from `\(request.absoluteUrlString)`" }
                guard let sha = json["sha"] as? String else { throw "Missing or invalid `sha` field in response from `\(request.absoluteUrlString)`" }
                return sha
            }, success: success, failure: failure)
            
        } catch {
            failure(error)
        }
        
    }
    
    public func updateRef(to commitSHA: String, on branch: BranchName, success: @escaping () -> Void, failure: @escaping (_ error: Error) -> Void) {
        var request = self.request(for: "/git/refs/heads/" + branch.name)
        
        let parameters: [String: Any] = ["sha": commitSHA]
        do {
            try request.setBodyToMatch(parameters: parameters)
            request.httpMethod = "PATCH"
            
            self.execute(request, process: { _ in return () }, success: success, failure: failure)
            
        } catch {
            failure(error)
        }
        
    }
    
}
