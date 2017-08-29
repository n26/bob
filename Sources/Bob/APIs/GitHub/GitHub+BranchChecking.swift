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

public extension GitHub {
    
    public func branchExists(_ branch: BranchName) throws -> (branchExists: Bool, possibleMatches: [Branch]) {
        let branches = try self.existingBranches()
        var branchExists = false
        let possibleMatches = branches.filter({ (remoteBranch) -> Bool in
            if remoteBranch.name == branch.name {
                branchExists = true
            } else {
                let distance = remoteBranch.name.levenshtein(to: branch.name)
                if Double(distance)/Double(branch.name.characters.count) < 0.25 {
                    return true
                }
            }
            return false
        })
        return (branchExists, possibleMatches)
    }
    
    public func assertBranchExists(_ branch: BranchName) throws {
        let data = try self.branchExists(branch)
        if !data.branchExists {
            var message = "Branch `\(branch.name)` doesn't exist."
            if data.possibleMatches.count > 0 {
                let branchesString = data.possibleMatches.reduce("") { $0 + "\n • " + $1.name }
                message = message + " Did you mean one of these:" + branchesString
            }
            throw message
        }
    }
    
}
