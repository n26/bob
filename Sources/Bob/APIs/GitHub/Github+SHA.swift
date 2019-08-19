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

import Foundation
import Vapor

extension GitHub {
    /// Helper methods that returns the latest commit sha on the specified branch
    public func currentCommitSHA(on branch: GitHub.Repos.Branch.BranchName) throws -> Future<GitHub.Repos.Commit.SHA> {
        return try self.branch(branch).map(to: String.self) { branchDetail in
            return branchDetail.commit.sha
        }
    }

    /// Helper methods that returns the tree sha for the specified commit sha
    public func treeSHA(forCommitSHA sha: GitHub.Git.Commit.SHA) throws -> Future<GitHub.Git.Tree.SHA> {
        return try self.gitCommit(sha: sha).map(to: GitHub.Git.Tree.SHA.self) { singleCommit   in
            return singleCommit.tree.sha
        }
    }
}
