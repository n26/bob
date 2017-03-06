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
import Dispatch

public protocol ItemUpdater {
    
    func itemsToUpdate(from items: [TreeItem]) -> [TreeItem]
    func update(_ item: TreeItem, content: String) throws -> String
    
}

fileprivate class BatchItemUpdater {
    
    private let items: [TreeItem]
    private let updater: ItemUpdater
    init(items: [TreeItem], updater: ItemUpdater) {
        self.items = items
        self.updater = updater
    }
    
    func update(using api: GitHub, success: @escaping (_ updatedItems: [TreeItem]) -> Void, failure: @escaping (_ error: Error) -> Void) {
        
        var updatedItems: [TreeItem] = []
        var anyError: Error? = nil
        let group = DispatchGroup()
        
        let itemsToUpdate = self.updater.itemsToUpdate(from: self.items)
        let updater = self.updater
        for item in itemsToUpdate {
            group.enter()
            api.content(forBlobWith: item.sha, success: { (content) in
                do {
                    let newContent = try updater.update(item, content: content)
                    
                    api.newBlob(with: newContent, success: { (newBlobSHA) in
                        let newItem = TreeItem(path: item.path, mode: item.mode, type: item.type, sha: newBlobSHA)
                        updatedItems.append(newItem)
                        group.leave()
                        
                    }, failure: { (error) in
                        anyError = error
                    })
                } catch {
                    anyError = error
                }
            }, failure: { (error) in
                anyError = error
            })
        }
        group.notify(queue: DispatchQueue.global()) {
            if let error = anyError {
                failure(error)
            } else {
                success(updatedItems)
            }
        }
        
    }
    
}

public extension GitHub {
    
    public func newCommit(updatingItemsWith updater: ItemUpdater, on branch: BranchName, by author: Author, message: String, success: @escaping () -> Void, failure: @escaping (_ error: Error) -> Void) {
        
        let api = self
        
        api.assertBranchExists(branch, success: {
            api.currentCommitSHA(on: branch, success: { (currentCommitSHA) in
                api.treeSHA(forCommitWith: currentCommitSHA, success: { (treeSHA) in
                    api.treeItems(forTreeWith: treeSHA, success: { (items) in
                        BatchItemUpdater(items: items, updater: updater).update(using: api, success: { (updatedItems) in
                            api.newTree(withBaseSHA: treeSHA, items: updatedItems, success: { (newTreeSHA) in
                                api.newCommit(by: author, message: message, parentSHA: currentCommitSHA, treeSHA: newTreeSHA, success: { (newCommitSHA) in
                                    api.updateRef(to: newCommitSHA, on: branch, success: {
                                        success()
                                    }, failure: failure)
                                }, failure: failure)
                            }, failure: failure)
                        }, failure: failure)
                    }, failure: failure)
                }, failure: failure)
            }, failure: failure)
        }, failure: failure)
    }
    
}
