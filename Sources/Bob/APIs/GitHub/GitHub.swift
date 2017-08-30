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

extension Status {
    
    var isSuccessfulRequest: Bool {
        return self.statusCode >= 200 && self.statusCode < 300
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

public struct Commit {
    public let sha: String
    public let message: String
    public init(sha: String, message: String) {
        self.sha = sha
        self.message = message
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
    private let drop: Droplet
    public init(config: Configuration, droplet: Droplet) {
        let authString = config.username + ":" + config.personalAccessToken
        self.base64LoginData = authString.data(using: .utf8)!.base64EncodedString()
        self.repoUrl = config.repoUrl
        self.drop = droplet
    }
    
    private func uri(at path: String) -> String {
        return self.repoUrl + path
    }
    
    private func perform(_ request: Request) throws -> JSON {
        request.headers[HeaderKey("Authorization")] = "Basic " + self.base64LoginData
        let response = try self.drop.client.respond(to: request)
        if response.status.isSuccessfulRequest {
            if let json = response.json {
                return json
            } else {
                throw "Error: Expected JSON from `" + request.uri.description + "`"
            }
        } else {
            throw "Error: `" + request.uri.description + "` - " + response.status.reasonPhrase
        }
    }
    
    private func resource(at uri: String) throws -> JSON {
        let request = Request(method: .get, uri: uri)
        return try self.perform(request)
    }
    
    public func existingBranches() throws -> [Branch] {
        let uri = self.uri(at: "/branches")
        let json = try self.resource(at: uri)
        
        guard let array = json.array else { throw "Expected an array from `\(uri)`" }
        
        return try array.map({
            guard let name = $0.object?["name"]?.string else {
                throw "Expected `branch` object to contain a `name` peoperty in the response from `\(uri)`"
            }
            return Branch(name: name)
        })
        
    }
    
    public func currentCommitSHA(on branch: BranchName) throws -> String  {
        let uri = self.uri(at: "/branches/" + branch.name)
        let json = try self.resource(at: uri)
        
        guard let commitSHA = json["commit"]?["sha"]?.string else {
            throw "Missing or invalid `sha` field in the `commit` object of the response from `\(uri)`"
        }
        return commitSHA
    }
    
    public func commits(after sha: String, page: Int, perPage: Int) throws -> [Commit] {
        let uri = self.uri(at: "/commits?sha=" + sha + "&page=" + String(page) + "&per_page=" + String(perPage))
        let json = try self.resource(at: uri)
        
        guard let array = json.array else { throw "Error: Expected an array from \(uri)" }
        
        return try array.map({
            guard let sha = $0.object?["sha"]?.string else { throw "Missin `sha` property in \(uri)" }
            guard let commit = $0.object?["commit"]?.object else { throw "Expected `commit` dictionary" }
            guard let message = commit["message"]?.string else { throw "Expected `message` in `commit` dictionary" }
            return Commit(sha: sha, message: message)
        })
    }
    
    public func treeSHA(forCommitWith commitSHA: String) throws -> String {
        let uri = self.uri(at: "/git/commits/" + commitSHA)
        let json = try self.resource(at: uri)
        
        guard let treeSHA = json["tree"]?.object?["sha"]?.string else {
            throw "Missing or invalid `sha` field in the `tree` object of the response from `\(uri)`"
        }
        return treeSHA
    }
    
    public func treeItems(forTreeWith treeSHA: String) throws -> [TreeItem] {
        let uri = self.uri(at: "/git/trees/" + treeSHA + "?recursive=1")
        let json = try self.resource(at: uri)
        
        guard let array = json["tree"]?.array else { throw "Missing or invalid `tree` field in response from `\(uri)`" }
        
        return try array.map({
            guard let path = $0.object?["path"]?.string else { throw "Missing or invalid `path` field in one of the tree items in the response for `\(uri)`." }
            guard let mode = $0.object?["mode"]?.string else { throw "Missing or invalid `mode` field in one of the tree items in the response for `\(uri)`." }
            guard let type = $0.object?["type"]?.string else { throw "Missing or invalid `type` field in one of the tree items in the response for `\(uri)`." }
            guard let sha = $0.object?["sha"]?.string else { throw "Missing or invalid `sha` field in one of the tree items in the response for `\(uri)`." }
            return TreeItem(path: path, mode: mode, type: type, sha: sha)

        })
    }
    
    public func content(forBlobWith blobSHA: String) throws -> String {
        let uri = self.uri(at: "/git/blobs/" + blobSHA)
        let json = try self.resource(at: uri)
        
        guard let content = json["content"]?.string else { throw "Missing or invalid `content` field in response from `\(uri)`" }
        
        /*
         * Remove pretty formatting Github applies
         */
        let contentBase64 = content.replacingOccurrences(of: "\n", with: "", options: [])
        
        guard let contentData = Data(base64Encoded: contentBase64) else { throw "Invalid base64 string from `\(uri)`\n\(contentBase64)" }
        guard let blob = String(data: contentData, encoding: .utf8) else { throw "Cannot create a string from base64 content retrieved from `\(uri)`\n\(contentBase64)" }
        
        return blob

    }
    
    public func newBlob(with content: String) throws -> String {
        let uri = self.uri(at: "/git/blobs")
        let parameters = try JSON(node: [
            "content": content
            ])
        let request = Request(method: .post, uri: uri, body: parameters.makeBody())
        let json = try self.perform(request)
        
        guard let sha = json["sha"]?.string else { throw "Missing or invalid `sha` field in response from `\(uri)`" }
        return sha
    }
    
    public func newTree(withBaseSHA baseSHA: String, items: [TreeItem]) throws -> String {
        let uri = self.uri(at: "/git/trees")
        let tree = try items.map({
            return try JSON(node: [
                    "path": $0.path,
                    "mode": $0.mode,
                    "type": $0.type,
                    "sha": $0.sha
                ])
        })
        let parameters = try JSON(node: [
            "base_tree": baseSHA,
            "tree": JSON(node: tree)
        ])
        let request = Request(method: .post, uri: uri, body: parameters.makeBody())
        let json = try self.perform(request)
        
        guard let sha = json["sha"]?.string else { throw "Missing or invalid `sha` field in response from `\(uri)`" }
        return sha
    }
    
    public func newCommit(by author: Author, message: String, parentSHA: String, treeSHA: String) throws -> String {
        let uri = self.uri(at: "/git/commits")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = dateFormatter.string(from: Date()).appending("Z")
        
        let author = try JSON(node: [
            "name": author.name,
            "email": author.email,
            "date": date
        ])
        let parameters = try JSON(node: [
            "message": message,
            "tree": treeSHA,
            "parents": JSON(node: [parentSHA]),
            "author": author
        ])
        
        let request = Request(method: .post, uri: uri, body: parameters.makeBody())
        let json = try self.perform(request)
        
        guard let sha = json["sha"]?.string else { throw "Missing or invalid `sha` field in response from `\(uri)`" }
        return sha
    }
    
    public func updateRef(to commitSHA: String, on branch: BranchName) throws {
        let uri = self.uri(at: "/git/refs/heads/" + branch.name)
        let parameters = try JSON(node: [
            "sha": commitSHA
        ])
        let request = Request(method: .patch, uri: uri, body: parameters.makeBody())
        _ = try self.perform(request)
    }
    
}
