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

import Dispatch
import Foundation
import Vapor

public protocol ItemUpdater {
    /// Filters the items to be updated
    ///
    /// - Parameter items: All the items in the three
    /// - Returns: The items that should be updated.
    func itemsToUpdate(from items: [TreeItem]) -> [TreeItem]

    /// Updates the filtered
    ///
    /// - Parameters:
    ///   - item: The three item
    ///   - content: The content of the three item as
    /// - Returns: The new content of the tree item that will be comitted
    func update(_ item: TreeItem, content: String) throws -> String
}

private class BatchItemUpdater {
    private let updater: ItemUpdater
    private let github: GitHub

    init(github: GitHub, updater: ItemUpdater) {
        self.github = github
        self.updater = updater
    }

    /// Each item is passed to the `ItemUpdater` to determine if it should be updated.
    /// For `ThreeItem` that the `ItemUpdater` wants to update, the content is fetched and passed again to the `ItemUpdater`
    /// The new content returned from by the `ItemUpdater` creates a new GitBlob its corresponding `TreeItem`
    ///
    /// - Parameter items: The list of items passed to the Updater
    /// - Returns: A future list of `ThreeItem` that were updated
    func update(items: [TreeItem], on worker: Worker) throws -> Future<[TreeItem]> {
        var updatedFutureItems = [Future<TreeItem>]()
        for item in updater.itemsToUpdate(from: items) {
            updatedFutureItems.append(try update(item: item))
        }

        // wait for all items
        return updatedFutureItems.flatten(on: worker)
    }

    private func update(item: TreeItem) throws -> Future<TreeItem> {
        let result = try github.gitBlob(sha: item.sha).map(to: String.self) { blob in
            guard let content = blob.string else { throw "Could not convert blob content to string" }
            return try self.updater.update(item, content: content)
        }.flatMap { newContent in
            try self.github.newBlob(data: newContent)
        }.map { newBlob in
            return TreeItem(path: item.path, mode: item.mode, type: item.type, sha: newBlob.sha)
        }
        return result
    }
}

public extension GitHub {
    struct CurrentState {
        let items: [TreeItem]
        let currentCommitSHA: GitHub.Repos.Commit.SHA
        let treeSHA: Git.Tree.SHA
    }

    public func currentState(on branch: BranchName) throws -> Future<CurrentState> {
        return try assertBranchExists(branch).flatMap { _ -> Future<CurrentState> in
            let commitSha = try self.currentCommitSHA(on: branch)

            let treeSha = commitSha.flatMap { sha in
                try self.treeSHA(forCommitSHA: sha)
            }

            let tree = treeSha.flatMap { sha in
                try self.trees(for: sha)
            }

            return map(commitSha, treeSha, tree) { commitSha, treeSha, tree in
                return CurrentState(items: tree.tree, currentCommitSHA: commitSha, treeSHA: treeSha)
            }
        }
    }

    /**
        Helper methods that passes the latest files on a specified branch to a ItemUpdate and creates a new commit with the update items/

        It
        - fetches the current repo at the specified branch
        - Passes the file list to the file updater
        - Creates a new tree with the update files
        - Creates a new commit
    */
    public func newCommit(updatingItemsWith updater: ItemUpdater, on branch: BranchName, by author: Author, message: String) throws -> Future<GitHub.Git.Reference> {
        // Get the repo state
        let respositoryState = try currentState(on: branch)

        // Pass the items to the updater
        let updatedItems = respositoryState.flatMap(to: [TreeItem].self) { respositoryState in
            let batchUpdater = BatchItemUpdater(github: self, updater: updater)
            return try batchUpdater.update(items: respositoryState.items, on: self.worker)
        }

        // wait for both repo state and updated items to create a new tree
        let newTree = flatMap(to: Tree.self, respositoryState, updatedItems) { respositoryState, updatedItems in

            if updatedItems.isEmpty {
                throw "The updater \(updater) did not match any items to update"
            }
            return try self.newTree(tree: Tree.New(baseTree: respositoryState.treeSHA, tree: updatedItems))
        }

        // wait for both repo state and the new tree
        let commit = map(respositoryState, newTree) { state, newTree in
            return (state.currentCommitSHA, newTree.sha)
        }.flatMap { parentSHA, treeSHA in
            // to create a new commit
            return try self.newCommit(by: author, message: message, parentSHA: parentSHA, treeSHA: treeSHA)
        }.flatMap { newCommit in
            // and update the ref
            return try self.updateRef(to: newCommit.sha, on: branch)
        }
        return commit
    }
}
