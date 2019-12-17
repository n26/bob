//
//  TravisTypes.swift
//  Bob
//
//  Created by Jan Chaloupecky on 03.12.19.
//

import Foundation
import Vapor

public extension TravisCI {
    /// https://developer.travis-ci.com/resource/requests#Requests
    struct Requests: Codable {
        /// POST /requests
        public struct Response: Content {
            /// The travis POSTed Travis Request
            public struct Request: Content {
                public typealias ID = Int
                public let id: ID
                public let branch: String
            }
            public let request: Request
        }

        let requests: [Request]
    }

    /**
        https://developer.travis-ci.com/resource/request

        When the Travis Request is "loading", t does not contain the "branch_name", "commit" and "builds".
        The same response does contain those properties when it's not "loading".
        We use the `State` enum here to have a type safe object
    */
    struct Request: Codable {
        public enum State {
            case pending
            case complete(Complete)
        }

        /**
         The Resquest object when it's in a non "loading" state
         */
        public struct Complete: Decodable {
            public let id: ID
            public let branchName: String
            public let commit: Commit
            public let builds: [Build]
        }

        enum CodingKeys: String, CodingKey {
            case state
            case id
            case branchName
            case builds
            case commit
        }

        public typealias ID = Int
        public let id: ID
        public let stateRaw: String
        public let state: State

        // MARK: - Decodable
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(ID.self, forKey: .id)
            stateRaw = try container.decode(String.self, forKey: .state)
            switch stateRaw {
            case "pending":
                state = .pending
            default:
                let singleContainer = try decoder.singleValueContainer()
                state = .complete(try singleContainer.decode(Complete.self))
            }
        }

        // MARK: - Encodable
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(stateRaw, forKey: .state)
            switch state {
            case .pending:
                break
            case .complete(let complete):
                try container.encode(complete.branchName, forKey: .branchName)
                try container.encode(complete.builds, forKey: .builds)
                try container.encode(complete.commit, forKey: .commit)
            }
        }
    }

    /// https://developer.travis-ci.com/resource/build#Build
    struct Build: Content {
        public typealias ID = Int
        public let href: String
        public let id: ID

        enum CodingKeys: String, CodingKey {
            case href = "@href"
            case id
        }
    }

    struct Commit: Content {
        public let message: String
    }
}
