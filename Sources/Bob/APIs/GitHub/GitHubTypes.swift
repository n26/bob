/*
 * Copyright (c) 2019 N26 GmbH.
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
import Vapor

public typealias TreeItem = GitHub.Git.TreeItem
public typealias Tree = GitHub.Git.Tree
public typealias GitCommit = GitHub.Git.Commit
public typealias GitContent = GitHub.Repos.GitContent
public typealias RepoCommit = GitHub.Repos.Commit
public typealias Branch = GitHub.Repos.Branch
public typealias BranchName = GitHub.Repos.Branch.BranchName
public typealias Author = GitHub.Author

extension GitHub {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dataDecodingStrategy  = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let content64 = try container.decode(String.self)
            guard let data = Data(base64Encoded: content64, options: .ignoreUnknownCharacters) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Encountered Data is not valid Base64.")
            }
            return data
        }

        decoder.dateDecodingStrategy = .formatted(GitHub.dateFormatter)
        return decoder
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .formatted(GitHub.dateFormatter)
        
        return encoder
    }()
    
    /// Struct representing an author
    public struct Author: Content {
        public let name: String
        public let email: String
        public let date: Date

        public init(name: String, email: String, date: Date = Date()) {
            self.name = name
            self.email = email
            self.date = date
        }
    }

    /// https://developer.github.com/v3/git/
    public struct Git {
        public struct Commit: Content {
            public typealias SHA = String

            public struct New: Content {
                let message: String
                let tree: Tree.SHA
                let parents: [Commit.SHA]
                let author: Author
            }

            public struct Tree: Content {
                public typealias SHA = String
                
                public let sha: SHA
                public let url: URL
            }

            public let sha: SHA
            public let message: String
            public let author: Author
            public let committer: Author
            public let tree: Tree
            public let url: URL
        }

        public struct Tree: Content {
            public typealias SHA = String

            public let sha: SHA
            public let tree: [TreeItem]

            public struct New: Content {
                let baseTree: SHA
                public let tree: [TreeItem]
            }
        }
        /// Struct representin an item in the tree - files
        public struct TreeItem: Content {
            public typealias SHA = String

            public let path: String
            public let mode: String
            public let type: String
            public let sha: TreeItem.SHA
            public init(path: String, mode: String, type: String, sha: TreeItem.SHA) {
                self.path = path
                self.mode = mode
                self.type = type
                self.sha = sha
            }
        }

        // https://developer.github.com/v3/git/blobs/#response
        public struct Blob: Content {
            public typealias SHA = String
            public let content: Data
            public let sha: SHA

            public struct New: Content {
                public let content: String

                public struct Response: Content {
                    public let sha: SHA
                }
            }

            public var string: String? {
                return String(data: content, encoding: .utf8)
            }
        }

        public struct Reference: Content {
            let ref: String
            let nodeId: String
            let url: URL

            public struct Patch: Content {
                let sha: String
            }
        }
    }

    /// https://developer.github.com/v3/repos/
    public struct Repos {
        /// Struct representing a Branch.
        /// Only contains name since it is the only
        /// property used by current functionality
        public struct Branch: Content {
            public typealias BranchName = String

            public let name: BranchName
            public init(name: BranchName) {
                self.name = name
            }
        }

        public struct BranchDetail: Content {
            let name: Branch.BranchName
            let commit: Commit
        }

        /// https://developer.github.com/v3/repos/commits/#get-a-single-commit
        public struct Commit: Content {
            public typealias SHA = String

            public struct Details: Content {
                public let message: String
                public let author: Author
                public let committer: Author
            }

            public let sha: SHA
            public let htmlUrl: URL
            public let details: Details

            enum CodingKeys: String, CodingKey {
                case sha
                case htmlUrl
                case details = "commit"
            }
        }

        /// https://developer.github.com/v3/repos/#list-tags
        public struct Tag: Content {
            public let name: String
            public let commit: Commit.SHA

            enum CodingKeys: String, CodingKey {
                case name
                case commit
            }
            enum CommitKeys: String, CodingKey {
                case sha
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                name = try container.decode(String.self, forKey: .name)

                let commitContainer = try container.nestedContainer(keyedBy: CommitKeys.self, forKey: .commit)
                commit = try commitContainer.decode(String.self, forKey: .sha)
            }
        }

        public enum GitContent: Content {
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: RawKeys.self)

                try container.encode(name, forKey: .name)

                switch self {
                case .file(_, let data):
                    try container.encode(data, forKey: .content)
                case .symlink(_, let targetPath):
                    try container.encode(targetPath, forKey: .target)
                case .submodule(_, let url):
                    try container.encode(url, forKey: .submoduleGitUrl)
                default:
                    break
                }
            }

            case file(name: String, data: Data?)
            case directory(name: String)
            case symlink(name: String, targetPath: String)
            case submodule(name: String, url: URL)

            public var name: String {
                switch self {
                case .file(let name, _):
                    return name
                case .directory(let name):
                    return name
                case .symlink(let name, _):
                    return name
                case .submodule(let name, _):
                    return name
                }
            }

            private enum RawType: String, Decodable {
                case file
                case dir
                case symlink
                case submodule
            }

            enum RawKeys: String, CodingKey {
                case type
                case name

                /// the content's path
                case path

                /// File's base64 content
                case content

                /// symlink target path
                case target

                case submoduleGitUrl
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: RawKeys.self)
                let type = try container.decode(RawType.self, forKey: .type)

                let name = try container.decode(String.self, forKey: .name)
                switch type {
                case .file:
                    let data = try container.decodeIfPresent(Data.self, forKey: .content)
                    self = .file(name: name, data: data)
                case .dir:
                    self = .directory(name: name)
                case .symlink:
                    let targetPath = try container.decode(String.self, forKey: .target)
                    self = .symlink(name: name, targetPath: targetPath)

                case .submodule:
                    let url = try container.decode(URL.self, forKey: .submoduleGitUrl)
                    self = .submodule(name: name, url: url)
                }
            }
        }
    }
}
