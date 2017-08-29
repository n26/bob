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

/// Command used to change the version and build numbers directly on GitHub
public class AlignVersionCommand {
    
    struct Constants {
        static let defaultBuildNumber: String = "1"
        static let branchSpecifier: String = "-b"
    }
    
    fileprivate let config: GitHub.Configuration
    fileprivate let defaultBranch: BranchName
    fileprivate let plistPaths: [String]
    fileprivate let messageFormat: String
    fileprivate let author: Author
    /// Initializer
    ///
    /// - Parameters:
    ///   - config: Configuration to use to connect to github
    ///   - defaultBranch: Default branch
    ///   - plistPaths: Paths to .plist files to update. Path relative from the root of the repository
    ///   - author: Commit author. Shows up in GitHub
    ///   - messageFormat: Format for the commit message. `<version>` will be replaced with the version string
    public init(config: GitHub.Configuration, defaultBranch: BranchName, plistPaths: [String], author: Author ,messageFormat: String = "[General] Aligns version to <version>") {
        self.config = config
        self.defaultBranch = defaultBranch
        self.plistPaths = plistPaths
        self.messageFormat = messageFormat
        self.author = author
    }
    
    
}

extension AlignVersionCommand: Command {
    
    public var name: String {
        return "align"
    }
    
    public var usage: String {
        return "Change version and build number by typing `align {version} {build number}`. Build number defaults to `\(Constants.defaultBuildNumber)` if not specified. Specify a branch by typing `\(Constants.branchSpecifier) {branch}`, defaults to `" + self.defaultBranch.name + "`"
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
        
        guard params.count > 0 else { throw "Please specify a `version` parameter. See `\(self.name) usage` for instructions on how to use this command" }
        
        let version = params[0]
        params.remove(at: 0)
        
        let buildNumber: String
        if params.count > 0 {
            buildNumber = params[0]
            params.remove(at: 0)
        } else {
            buildNumber = Constants.defaultBuildNumber
        }
        
        guard params.count == 0 else { throw "To many parameters. See `\(self.name) usage` for instructions on how to use this command" }
        
        let api = GitHub(config: self.config)
        
        sender.send("One sec...")
        let updater = VersionUpdater(plistPaths: self.plistPaths, version: version, buildNumber: buildNumber)
        let versionString = "\(version) (\(buildNumber))"
        let message = self.messageFormat.replacingOccurrences(of: "<version>", with: versionString)
        
        try api.newCommit(updatingItemsWith: updater, on: branch, by: self.author, message: message)
        sender.send("Done. Version aligned to *" + versionString + "* on branch *" + branch.name + "*")
    }
    
}
