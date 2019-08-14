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


enum GitHubError: Error {
    case invalidParam(String)
    case decoding(String)
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

    // MARK: Repository APIs

    public func branches() throws -> Future<[GitHub.Repos.Branch]> {
        return try get(uri(at: "/branches?per_page=100"))
    }

    
    public func branch(_ branch: GitHub.Repos.Branch.BranchName) throws -> Future<GitHub.Repos.BranchDetail> {
        return try get(uri(at: "/branches/" + branch))
    }

    /// Lists the content of a directory
    public func contents(at path: String, on branch: GitHub.Repos.Branch.BranchName) throws -> Future<[GitHub.Repos.GitContent]> {
        return try get(uri(at: "/contents/\(path)?ref=" + branch))
    }

    /// Content of a single file
    public func content(at path: String, on branch: GitHub.Repos.Branch.BranchName) throws -> Future<GitHub.Repos.GitContent> {
        return try get(uri(at: "/contents/\(path)?ref=" + branch))
    }

    /// Returns a list of commits in reverse chronological order
    ///
    /// - Parameters:
    ///   - sha: Starting commit
    ///   - page: Index of the requested page
    ///   - perPage: Number of commits per page
    ///   - path: Directory within repository (optional). Only commits with files touched within path will be returned
    public func commits(after sha: String? = nil, page: Int? = nil, perPage: Int? = nil, path: String? = nil) throws -> Future<[GitHub.Repos.Commit]> {

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

        return try get(uri)
    }

    // MARK: - Git APIs

    public func gitCommit(sha: GitHub.Git.Commit.SHA) throws -> Future<GitHub.Git.Commit> {
        return try get(uri(at: "git/commits/" + sha))
    }

    public func gitBlob(sha: Git.TreeItem.SHA) throws -> Future<GitHub.Git.Blob> {
        return try get(uri(at: "/git/blobs/" + sha))
    }

    public func newBlob(data: String) throws -> Future<GitHub.Git.Blob> {
        let blob = GitHub.Git.Blob.New(content: data)
        return try post(body: blob, to: uri(at: "/git/blobs/"))
    }


    public func trees(for treeSHA: GitHub.Git.Tree.SHA) throws -> Future<GitHub.Git.Tree> {
        let uri = self.uri(at: "/git/trees/" + treeSHA + "?recursive=1")
        return try self.get(uri)
    }

    public func newTree(tree: Tree.New) throws -> Future<Tree> {
        return try post(body: tree, to: uri(at: "/git/trees"))
    }


    // MARK: - Private

    private func perform<T: Content>(_ request: HTTPRequest, using decoder: JSONDecoder = JSONDecoder()) throws -> Future<T> {
        let req = Request(http: request, using: app)
        req.http.headers.basicAuthorization = authorization

        let futureResult = try app.client().send(req)
        let featureContent = futureResult.flatMap { response -> EventLoopFuture<T> in
            let futureDecode =  try response.content.decode(json: T.self, using: decoder)
            futureDecode.whenFailure { error in
                print("\(request.method.string) \(request.url): \(error)")
            }
            return futureDecode
        }

        return featureContent
    }

    private func get<T: Content>(_ uri: String, using decoder: JSONDecoder = GitHub.decoder) throws -> Future<T> {
        let request = HTTPRequest(method: .GET, url: uri)
        return try perform(request, using: decoder)
    }

    private func post<Body: Content, T: Content>(body: Body, to uri: String, encoder: JSONEncoder = GitHub.encoder, using decoder: JSONDecoder = GitHub.decoder) throws -> Future<T> {
        var request = HTTPRequest(method: .POST, url: uri)
        let data  = try encoder.encode(body)
        request.body = HTTPBody(data: data)
        return try perform(request, using: decoder)
    }


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


}
