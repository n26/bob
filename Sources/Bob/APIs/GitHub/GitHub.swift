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

enum GitHubError: Error {
    case invalidParam(String)
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
    
    private let authorization: BasicAuthorization
    private let repoUrl: String
    private let app: Application

    public init(config: Configuration, app: Application) {
        self.authorization = BasicAuthorization(username: config.username, password: config.personalAccessToken)
        self.repoUrl = config.repoUrl
        self.app = app
    }
    
    private func uri(at path: String) -> String {
        return self.repoUrl + path
    }

    public func branches() throws -> Future<[GitAPI.Repos.Branch]> {
        return try resource(at: uri(at: "/branches?per_page=100"))
    }

    
    public func branch(_ branch: GitAPI.Repos.Branch.BranchName) throws -> Future<GitAPI.Repos.BranchDetail> {
        return try resource(at: uri(at: "/branches/" + branch))
    }

    public func gitCommit(sha: GitAPI.Git.Commit.SHA) throws -> Future<GitAPI.Git.Commit> {
        return try resource(at: uri(at: "git/commits/" + sha))
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
    public func commits(after sha: String? = nil, page: Int? = nil, perPage: Int? = nil, path: String? = nil) throws -> Future<[GitAPI.Repos.Commit]> {

        var components = URLComponents(string: "")!
        var items = [URLQueryItem]()
        components.path = "/commits"

        if let sha = sha {
            items.append(URLQueryItem(name: "sha", value: sha))
        }
        if let page = page {
            items.append(URLQueryItem(name: "page", value: "\(page)"))
        }

        if let perPage = perPage {
            items.append(URLQueryItem(name: "per_page", value: "\(perPage)"))
        }

        if let path = path {
            items.append(URLQueryItem(name: "path", value: "\(path)"))
        }
        components.queryItems = items
        guard let url = components.url else { throw GitHubError.invalidParam("Could not create commit URL") }
        let uri = self.uri(at: url.absoluteString)

        return try resource(at: uri)
    }

    public func trees(for treeSHA: GitAPI.Git.Tree.SHA) throws -> Future<GitAPI.Git.Tree> {
        let uri = self.uri(at: "/git/trees/" + treeSHA + "?recursive=1")
        return try self.resource(at: uri)
    }

    // MARK: - Private

    private func perform<T: Content>(_ request: HTTPRequest) throws -> Future<T> {
        let req = Request(http: request, using: app)
        req.http.headers.basicAuthorization = authorization

        let futureResult = try app.client().send(req)
        let featureContent = futureResult.flatMap { response -> EventLoopFuture<T> in
            let futureDecode =  try response.content.decode(T.self)
            futureDecode.whenFailure { error in
                print("\(request.method.string) \(request.url): \(error)")
            }
            return futureDecode
        }

        return featureContent
    }

    private func resource<T: Content>(at uri: String) throws -> Future<T> {
        let request = HTTPRequest(method: .GET, url: uri)
        return try perform(request)
    }


//
//    public func content(forBlobWith blobSHA: String) throws -> String {
//        let uri = self.uri(at: "/git/blobs/" + blobSHA)
//        let json = try self.resource(at: uri)
//
//        guard let content = json["content"]?.string else { throw "Missing or invalid `content` field in response from `\(uri)`" }
//
//        /*
//         * Remove pretty formatting Github applies
//         */
//        let contentBase64 = content.replacingOccurrences(of: "\n", with: "", options: [])
//
//        guard let contentData = Data(base64Encoded: contentBase64) else { throw "Invalid base64 string from `\(uri)`\n\(contentBase64)" }
//        guard let blob = String(data: contentData, encoding: .utf8) else { throw "Cannot create a string from base64 content retrieved from `\(uri)`\n\(contentBase64)" }
//
//        return blob
//
//    }
//
//    public func newBlob(with content: String) throws -> String {
//        let uri = self.uri(at: "/git/blobs")
//        let parameters = try JSON(node: [
//            "content": content
//            ])
//        let request = Request(method: .post, uri: uri, body: parameters.makeBody())
//        let json = try self.perform(request)
//
//        guard let sha = json["sha"]?.string else { throw "Missing or invalid `sha` field in response from `\(uri)`" }
//        return sha
//    }
//
//    public func newTree(withBaseSHA baseSHA: String, items: [TreeItem]) throws -> String {
//        let uri = self.uri(at: "/git/trees")
//        let tree = try items.map({
//            return try JSON(node: [
//                    "path": $0.path,
//                    "mode": $0.mode,
//                    "type": $0.type,
//                    "sha": $0.sha
//                ])
//        })
//        let parameters = try JSON(node: [
//            "base_tree": baseSHA,
//            "tree": JSON(node: tree)
//        ])
//        let request = Request(method: .post, uri: uri, body: parameters.makeBody())
//        let json = try self.perform(request)
//
//        guard let sha = json["sha"]?.string else { throw "Missing or invalid `sha` field in response from `\(uri)`" }
//        return sha
//    }
//
//    public func newCommit(by author: Author, message: String, parentSHA: String, treeSHA: String) throws -> String {
//        let uri = self.uri(at: "/git/commits")
//
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
//        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
//        let date = dateFormatter.string(from: Date()).appending("Z")
//
//        let author = try JSON(node: [
//            "name": author.name,
//            "email": author.email,
//            "date": date
//        ])
//        let parameters = try JSON(node: [
//            "message": message,
//            "tree": treeSHA,
//            "parents": JSON(node: [parentSHA]),
//            "author": author
//        ])
//
//        let request = Request(method: .post, uri: uri, body: parameters.makeBody())
//        let json = try self.perform(request)
//
//        guard let sha = json["sha"]?.string else { throw "Missing or invalid `sha` field in response from `\(uri)`" }
//        return sha
//    }
//
//    public func updateRef(to commitSHA: String, on branch: BranchName) throws {
//        let uri = self.uri(at: "/git/refs/heads/" + branch.name)
//        let parameters = try JSON(node: [
//            "sha": commitSHA
//        ])
//        let request = Request(method: .patch, uri: uri, body: parameters.makeBody())
//        _ = try self.perform(request)
//    }
//
//    public func directoryContents(at path: String, on branch: BranchName) throws -> [GitContent] {
//        let uri = self.uri(at: "/contents/\(path)?ref=" + branch.name)
//        let json = try self.resource(at: uri)
//
//        guard let array = json.array else { throw "Error: Expected an array from \(uri)" }
//
//        return try array.map {
//            guard let name = $0.object?["name"]?.string else { throw "Missing or invalid `name` field in directory contents of `\(uri)`." }
//            guard let type = $0.object?["type"]?.string else { throw "Missing or invalid `type` field in directory contents of `\(uri)`." }
//
//            switch type {
//            case "file":
//                return .file(name: name, data: nil)
//            case "dir":
//                return .directory(name: name)
//            case "symlink":
//                guard let targetPath = $0.object?["targetPath"]?.string else { throw "Missing or invalid `targetPath` field in directory contents of `\(uri)`." }
//                return .symlink(name: name, targetPath: targetPath)
//            case "submodule":
//                guard let urlString = $0.object?["submodule_git_url"]?.string,
//                    let url = URL(string: urlString) else {
//                        throw "Missing or invalid `submodule_git_url` field in directory contents of `\(uri)`."
//                }
//                return .submodule(name: name, url: url)
//            default:
//                return .unrecognised
//            }
//
//        }
//    }
//
//    public func fileContents(with path: String, on branch: BranchName) throws -> GitContent {
//        let uri = self.uri(at: "/contents/\(path)?ref=" + branch.name)
//        let json = try self.resource(at: uri)
//
//            guard let name = json.object?["name"]?.string else { throw "Missing or invalid `name` field in directory contents of `\(uri)`." }
//            guard let type = json.object?["type"]?.string else { throw "Missing or invalid `type` field in directory contents of `\(uri)`." }
//
//            switch type {
//            case "file":
//                guard let content = json.object?["content"]?.string else { throw "Missing or invalid `content` field in directory contents of `\(uri)`."}
//                guard let data = Data(base64Encoded: content, options: .ignoreUnknownCharacters) else { throw "Could not decode base64 encoded `content` field from `\(uri)`."}
//                return .file(name: name, data:data)
//            default:
//                throw "Unexpected file type at path: `\(uri)`."
//            }
//    }

}
