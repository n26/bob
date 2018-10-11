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
    public let date: String
    public init(name: String, email: String, date: String? = nil) {
        self.name = name
        self.email = email
        
        if let date = date {
            self.date = date
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
            self.date = dateFormatter.string(from: Date()).appending("Z")
        }
    }

    private let serverFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    
    public func dateValue() throws -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = serverFormat
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let dateValue = dateFormatter.date(from: date) else {
            throw "Error: Author date does not match format: `\(serverFormat)`"
        }
        return dateValue
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
    public let url: String
    public let message: String
    public let author: Author
    public let committer: Author
    
    public init(sha: String, url: String, message: String, author: Author, committer: Author) {
        self.sha = sha
        self.url = url
        self.message = message
        self.author = author
        self.committer = committer
    }
}

public enum GitContent {
    case unrecognised
    case file(name: String, data: Data?)
    case directory(name: String)
    case symlink(name: String, targetPath: String)
    case submodule(name: String, url: URL)
    
    public var name: String {
        switch self {
        case .unrecognised:
            return "<unknown>"
        case .file(let name, _):
            return name
        case .directory(let name):
            return name
        case .symlink(let name,_):
            return name
        case .submodule(let name,_):
            return name
        }
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
        let uri = self.uri(at: "/branches?per_page=100")
        let json = try self.resource(at: uri)
        
        guard let array = json.array else { throw "Expected an array from `\(uri)`" }
        
        return try array.map({
            guard let name = $0.object?["name"]?.string else {
                throw "Expected `branch` object to contain a `name` property in the response from `\(uri)`"
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
    
    /// Returns a list of commits in reverse chronological order
    ///
    /// - Parameters:
    ///   - sha: Starting commit
    ///   - page: Index of the requested page
    ///   - perPage: Number of commits per page
    ///   - path: Directory within repository (optional). Only commits with files touched within path will be returned
    /// - Returns: Commits after sha in reverse chronological order (with files touched below path, when specified)
    /// - Throws: When expected properties are missing in API response
    public func commits(after sha: String, page: Int, perPage: Int, path: String? = nil) throws -> [Commit] {
        let pathQuery: String
        if let path = path {
            pathQuery = "&path=" + path
        } else {
            pathQuery = ""
        }
        let uri = self.uri(at: "/commits?sha=" + sha + "&page=" + String(page) + "&per_page=" + String(perPage) + pathQuery)
        let json = try self.resource(at: uri)
        
        guard let array = json.array else { throw "Error: Expected an array from \(uri)" }
        
        return try array.map({
            guard let sha = $0.object?["sha"]?.string else { throw "Missing `sha` property in \(uri)" }
            guard let url = $0.object?["html_url"]?.string else { throw "Expected `html_url` in dictionary" }
            guard let commit = $0.object?["commit"]?.object else { throw "Expected `commit` dictionary" }
            guard let message = commit["message"]?.string else { throw "Expected `message` in `commit` dictionary" }
            guard let authorName = commit["author"]?["name"]?.string else { throw "Expected `author.name` in `commit` dictionary"}
            guard let authorEmail = commit["author"]?["email"]?.string else { throw "Expected `author.email` in `commit` dictionary"}
            guard let authorDate = commit["author"]?["date"]?.string else { throw "Expected `author.date` in `commit` dictionary"}
            guard let committerName = commit["committer"]?["name"]?.string else { throw "Expected `committer.name` in `commit` dictionary"}
            guard let committerEmail = commit["committer"]?["email"]?.string else { throw "Expected `committer.email` in `commit` dictionary"}
            guard let committerDate = commit["committer"]?["date"]?.string else { throw "Expected `committer.date` in `commit` dictionary"}
            return Commit(sha: sha,
                          url: url,
                          message: message,
                          author: Author(name: authorName, email: authorEmail, date: authorDate),
                          committer: Author(name: committerName, email: committerEmail, date: committerDate))
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
        
        let author = try JSON(node: [
            "name": author.name,
            "email": author.email
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
    
    public func directoryContents(at path: String, on branch: BranchName) throws -> [GitContent] {
        let uri = self.uri(at: "/contents/\(path)?ref=" + branch.name)
        let json = try self.resource(at: uri)
        
        guard let array = json.array else { throw "Error: Expected an array from \(uri)" }
        
        return try array.map {
            guard let name = $0.object?["name"]?.string else { throw "Missing or invalid `name` field in directory contents of `\(uri)`." }
            guard let type = $0.object?["type"]?.string else { throw "Missing or invalid `type` field in directory contents of `\(uri)`." }
            
            switch type {
            case "file":
                return .file(name: name, data: nil)
            case "dir":
                return .directory(name: name)
            case "symlink":
                guard let targetPath = $0.object?["targetPath"]?.string else { throw "Missing or invalid `targetPath` field in directory contents of `\(uri)`." }
                return .symlink(name: name, targetPath: targetPath)
            case "submodule":
                guard let urlString = $0.object?["submodule_git_url"]?.string,
                    let url = URL(string: urlString) else {
                        throw "Missing or invalid `submodule_git_url` field in directory contents of `\(uri)`."
                }
                return .submodule(name: name, url: url)
            default:
                return .unrecognised
            }

        }
    }
    
    public func fileContents(with path: String, on branch: BranchName) throws -> GitContent {
        let uri = self.uri(at: "/contents/\(path)?ref=" + branch.name)
        let json = try self.resource(at: uri)
        
            guard let name = json.object?["name"]?.string else { throw "Missing or invalid `name` field in directory contents of `\(uri)`." }
            guard let type = json.object?["type"]?.string else { throw "Missing or invalid `type` field in directory contents of `\(uri)`." }
            
            switch type {
            case "file":
                guard let content = json.object?["content"]?.string else { throw "Missing or invalid `content` field in directory contents of `\(uri)`."}
                guard let data = Data(base64Encoded: content, options: .ignoreUnknownCharacters) else { throw "Could not decode base64 encoded `content` field from `\(uri)`."}
                return .file(name: name, data:data)
            default:
                throw "Unexpected file type at path: `\(uri)`."
            }
    }

}
