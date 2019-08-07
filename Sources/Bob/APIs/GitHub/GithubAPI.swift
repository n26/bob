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

public struct GitAPI {

    /// Struct representing an author
    public struct Author: Content {
        public let name: String
        public let email: String
        public let date: Date
    }


    /// https://developer.github.com/v3/git/
    public struct Git {

        public struct Commit: Content {
            public typealias SHA = String

            public struct Tree: Content {
                public typealias SHA = String
                
                public let sha: SHA
                public let url: URL
            }

            public let message: String
            public let author: Author
            public let committer: Author
            public let tree: Tree
        }

        public struct Tree: Content {
            public typealias SHA = String
            
            public let tree: [TreeItem]
        }
        /// Struct representin an item in the tree - files
        public struct TreeItem: Content {
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

        public struct Commit: Content {
            public typealias SHA = String

            public let sha: SHA
            public let url: URL
            public let commit: GitAPI.Git.Commit

            //    enum CodingKeys: String, CodingKey {
            //        case sha
            //        case url
            //        case commit
            //    }
            //    enum NestedCommitKeys: String, CodingKey {
            //        case author
            //        case comitter
            //        case message
            //    }
            //
            //    public init(from decoder: Decoder) throws {
            //        let container = try decoder.container(keyedBy: CodingKeys.self)
            //        sha = try container.decode(String.self, forKey: .sha)
            //        url = try container.decode(URL.self, forKey: .url)
            //
            //        let commitContainer = try container.nestedContainer(keyedBy: NestedCommitKeys.self, forKey: .commit)
            //        author = try commitContainer.decode(Author.self, forKey: .author)
            //        committer = try commitContainer.decode(Author.self, forKey: .author)
            //        message = try commitContainer.decode(String.self, forKey: .message)
            //    }
            //
            //    public func encode(to encoder: Encoder) throws {
            //        fatalError("not implemented")
            //    }
        }

    }
}
