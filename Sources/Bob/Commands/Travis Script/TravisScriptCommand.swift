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

/// Struct used to map targets to scripts
public struct TravisTarget {
    /// Name used in the command parameters
    public let name: String
    /// Script to trigger
    public let script: Script
    public init(name: String, script: Script) {
        self.name = name
        self.script = script
    }
}


/// Command executing a script on TravisCI
/// Script are provided via `TravisTarget`s. In case 
/// only 1 traget is provided, the user does not have 
/// to type in the target name
public class TravisScriptCommand {
    
    public let name: String
    fileprivate let travis: TravisCI
    fileprivate let targets: [TravisTarget]
    fileprivate let defaultBranch: BranchName
    fileprivate let gitHub: GitHub?
    
    /// Initializer for the command
    ///
    /// - Parameters:
    ///   - name: Command name to use
    ///   - travis: TravisCI instance
    ///   - targets: Array of possible targets the user can use
    ///   - gitHub: If GitHub config is provided, the command will perform a branch check before invoking TravisCI api
    public init(name: String, travis: TravisCI, targets: [TravisTarget], defaultBranch: BranchName, gitHub: GitHub? = nil) {
        self.name = name
        self.travis = travis
        self.targets = targets
        self.defaultBranch = defaultBranch
        self.gitHub = gitHub
    }
    
}

extension TravisScriptCommand: Command {

    struct Constants {
        static let branchSpecifier: String = "-b"
    }

    public var usage: String {
        let target = self.targets.count == 1 ? "" : " {{target}}"
        var message = "Triger a script by saying `\(self.name + target) \(Constants.branchSpecifier) {{branch}}`. I'll do the job for you. `branch` parameter is optional and it defaults to `\(self.defaultBranch)`"

        if self.targets.count != 1 {
            message += "\nAvailable targets:"
            self.targets.forEach({ message += "\n• " + $0.name})
        }

        return message
    }

    public func execute(with parameters: [String], replyingTo sender: MessageSender) throws {

        var params = parameters
        /// Resolve target
        var target: TravisTarget!
        if self.targets.count == 1 {
            /// Only 1 possible target, the user doesn't have to specify
            target = self.targets[0]
        } else {
            /// More possible targets, resolve which one needs to be used
            guard params.count > 0 else { throw "No parameters provided. See `\(self.name) usage` for instructions on how to use this command" }
            let targetName = params[0]
            params.remove(at: 0)
            guard let existingTarget = self.targets.first(where: { $0.name == targetName }) else { throw "Unknown target `\(targetName)`." }
            target = existingTarget
        }

        /// Resolve branch
        var branch: BranchName = self.defaultBranch
        if let branchSpecifierIndex = params.index(where: { $0 == Constants.branchSpecifier }) {
            guard params.count > branchSpecifierIndex + 1 else { throw "Branch name not specified after `\(Constants.branchSpecifier)`" }
            branch = BranchName(params[branchSpecifierIndex + 1])
            params.remove(at: branchSpecifierIndex + 1)
            params.remove(at: branchSpecifierIndex)
        }

        guard params.count == 0 else { throw "To many parameters. See `\(self.name) usage` for instructions on how to use this command" }

        let _ = try self.assertGitHubBranchIfPossible(branch).flatMap {
            return try self.travis.execute(target.script, on: branch)
        }.map { success  in
            if success {
                sender.send("Got it! Executing target *" + target.name + "* on branch *" + branch + "*")
            } else {
                sender.send("Executing target *" + target.name + "* on branch *" + branch + "* failed")
            }

        }.catch { error in
            sender.send("Command failed with error ```\(error)```")
        }
    }

    private func assertGitHubBranchIfPossible(_ branch: BranchName) throws -> Future<Void> {
        guard let gitHub = self.gitHub else {
            return travis.worker.future()
        }
        return try gitHub.assertBranchExists(branch)
    }
}
