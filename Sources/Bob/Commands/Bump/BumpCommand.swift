/*
 * Copyright (c) 2018 N26 GmbH.
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
    public init(gitHub: GitHub, defaultBranch: BranchName, plistPaths: [String], author: Author, message: String = "[General] Aligns version to <version>") {
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
        guard plistPaths.count > 0 else {
            throw "Failed to bump. Misconfiguration of the `bump` command. Missing Plist file paths."
        }
        
        var params = parameters
        
        var branch: BranchName = self.defaultBranch
        if let branchSpecifierIndex = params.index(where: { $0 == Constants.branchSpecifier }) {
            guard params.count > branchSpecifierIndex + 1 else { throw "Branch name not specified after `\(Constants.branchSpecifier)`" }
            branch = BranchName(params[branchSpecifierIndex + 1])
            params.remove(at: branchSpecifierIndex + 1)
            params.remove(at: branchSpecifierIndex)
        }
        
        sender.send("One sec...")
        let versionFiles = try self.gitHub.currentState(on: branch).items.filter { $0.path == plistPaths[0] }
        
        guard let versionAndBuildNumber = try versionFiles.first.map ({ item -> (String, String) in
            
            let content = try self.gitHub.content(forBlobWith: item.sha)
            
            let matcher = RegexMatcher(text: content)
            var output = ("","")
            
            let versions = matcher.matches(stringMatching: PListHelpers.versionRegexString)
            if let version = versions.first {
                let versionString = PListHelpers.extractStringValue(from: version)
                output.0 = versionString
            } else {
                throw "Failed to bump version. Could not find version number in Plist file."
            }
            
            let buildNumbers = matcher.matches(stringMatching: PListHelpers.buildNumberRegexString)
            
            if let first = buildNumbers.first {
                let buildNumberText = PListHelpers.extractStringValue(from: first)
                output.1 = buildNumberText
            } else {
                throw "Failed to bump version. Could not find build number in Plist file."
            }
            
            return output
        }) else {
            sender.send("Failed to extract build number.")
            return
        }
        
        guard let numericBuildNumber = Int(versionAndBuildNumber.1) else {
            sender.send("Could not bump up build number because it's not numeric. Current value is *\(versionAndBuildNumber.1)*.")
            return
        }
        
        let newBuildNumber = String(numericBuildNumber + 1)
        let align = VersionUpdater(plistPaths: plistPaths, version: versionAndBuildNumber.0, buildNumber: newBuildNumber)
        
        let versionString = "\(versionAndBuildNumber.0) (\(newBuildNumber))"
        let message = self.message.replacingOccurrences(of: "<version>", with: versionString)
        
        try self.gitHub.newCommit(updatingItemsWith: align, on: branch, by: self.author, message: message)
        
        sender.send("Done. Build number bumped up. New version is \(versionAndBuildNumber.0) (\(newBuildNumber)).")
    }
}
