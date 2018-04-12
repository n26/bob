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

// Command used to bump up build numbers directly on GitHub
public class BumpCommand {
    
    struct Constants {
        static let branchSpecifier: String = "-b"
    }
    
    fileprivate let gitHub: GitHub
    fileprivate let defaultBranch: BranchName
    fileprivate let plistPaths: [String]
    fileprivate let message: String
    fileprivate let author: Author
    /// Initializer
    ///
    /// - Parameters:
    ///   - config: Configuration to use to connect to github
    ///   - defaultBranch: Default branch
    ///   - plistPaths: Paths to .plist files to update. Path relative from the root of the repository
    ///   - author: Commit author. Shows up in GitHub
    ///   - messageFormat: Format for the commit message. `<version>` will be replaced with the version string
    public init(gitHub: GitHub, defaultBranch: BranchName, plistPaths: [String], author: Author, message: String = "[General] Bumps version to <version> (<buildNumber>).") {
        self.gitHub = gitHub
        self.defaultBranch = defaultBranch
        self.plistPaths = plistPaths
        self.message = message
        self.author = author
    }
}

extension BumpCommand: Command {
    
    public var name: String {
        return "bump"
    }
    
    public var usage: String {
        return "Bump up build number by typing `bump`. Specify a branch by typing `\(Constants.branchSpecifier) {branch}`, defaults to `" + self.defaultBranch.name + "`."
    }
    
    public func execute(with parameters: [String], replyingTo sender: MessageSender) throws {
        var params = parameters
        
        var branch: BranchName = self.defaultBranch
        if let branchSpecifierIndex = params.index(where: { $0 == Constants.branchSpecifier }) {
            guard params.count > branchSpecifierIndex + 1 else { throw "Branch name not specified after `\(Constants.branchSpecifier)`" }
            branch = BranchName(params[branchSpecifierIndex + 1])
            params.remove(at: branchSpecifierIndex + 1)
            params.remove(at: branchSpecifierIndex)
        }
        
        sender.send("One sec...")
        let updater = BumpUpdater(plistPaths: self.plistPaths)
        
        try self.gitHub.newCommit(updatingItemsWith: updater, on: branch, by: self.author, message: self.message, completion: { output in
            guard let version = output?["version"], let buildNumber = output?["buildNumber"] else {
                sender.send("Done. Build number bumped up.")
                return
            }
            sender.send("Done. Build number bumped up. New version is \(version) (\(buildNumber)).")
        })
    }
}
