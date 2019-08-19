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

public extension GitHub {
    public func branchExists(_ branch: BranchName) throws -> Future<(branchExists: Bool, possibleMatches: [Branch])> {
        return try self.branches().map { branches -> (branchExists: Bool, possibleMatches: [Branch])  in
            var branchExists = false
            let possibleMatches = branches.filter { remoteBranch -> Bool in
                    if remoteBranch.name == branch {
                        branchExists = true
                    } else {
                        let distance = remoteBranch.name.levenshtein(to: branch)
                        if Double(distance) / Double(branch.count) < 0.25 {
                            return true
                        }
                    }
                    return false
            }
            return (branchExists, possibleMatches)
        }
    }

    /**
        Helper method to assert that the specified branch exists.
        The Future's `futureResult` is called when the branch does exist otherwise it's `.failure`

        ```
         try gitHub.assertBranchExists(branch).map {
            // do something with the branch
         }.catch { error in
            // branch does not exists
         }
         ```
    */
    public func assertBranchExists(_ branch: BranchName) throws -> Future<Void> {
        return try branchExists(branch).map { result  in
            if !result.branchExists {
                throw GitHubError.invalidBranch(name: branch)
            }
        }
    }
}
