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

class BumpUpdater: GitHub.CommitMessageUpdater {
    
    struct Constants {
        static let versionRegexString: String = "<key>CFBundleShortVersionString<\\/key>\\s*<string>(\\S+)<\\/string>"
        static let versionKey: String = "CFBundleShortVersionString"
        static let buildNumberRegexString: String = "<key>CFBundleVersion<\\/key>\\s*<string>(\\S+)<\\/string>"
        static let buildNumberKey: String = "CFBundleVersion"
    }
    
    private let plistPaths: [String]
    init(plistPaths: [String]) {
        self.plistPaths = plistPaths
        super.init()
        self.output = [:]
    }
    
    override func itemsToUpdate(from items: [TreeItem]) -> [TreeItem] {
        return items.filter({ self.plistPaths.contains($0.path) })
    }
    
    override func update(_ item: TreeItem, content: String) throws -> String {
        let matcher = RegexMatcher(text: content)
        
        let versions = matcher.matches(stringMatching: Constants.versionRegexString)
        if let version = versions.first {
            let versionString = extractValue(from: version)
            output?["version"] = versionString
        }
        
        let buildNumbers = matcher.matches(stringMatching: Constants.buildNumberRegexString)
        
        if let first = buildNumbers.first {
            let buildNumberText = extractValue(from: first)
            if let currentBuildNumber = Int(buildNumberText) {
                let newBuildNumber = String(currentBuildNumber + 1)
                output?["buildNumber"] = newBuildNumber
                matcher.replace(stringMatching: Constants.buildNumberRegexString, with: self.replacementString(for: Constants.buildNumberKey, value: newBuildNumber))
            } else {
                throw "Could not bump up build number. Maybe the current build number is not a number (Value: \(buildNumberText))?"
            }
        }
        
        return matcher.result
    }
    
    private func replacementString(for key: String, value: String) -> String {
        return "<key>" + key + "<\\/key>\n\t<string>" + value + "<\\/string>"
    }
    
    private func extractValue(from text: String) -> String {
        let matches = RegexMatcher(text: text).matches(stringMatching: "<string>(.+?)</string>")
        
        guard matches.count > 0 else {
            return ""
        }

        return matches[0].replacingOccurrences(of: "<string>", with: "").replacingOccurrences(of: "</string>", with: "")
    }
}
