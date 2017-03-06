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

class VersionUpdater: ItemUpdater {
    
    struct Constants {
        static let versionRegexString: String = "<key>CFBundleShortVersionString<\\/key>\\s*<string>(\\S+)<\\/string>"
        static let versionKey: String = "CFBundleShortVersionString"
        static let buildNumberRegexString: String = "<key>CFBundleVersion<\\/key>\\s*<string>(\\S+)<\\/string>"
        static let buildNumberKey: String = "CFBundleVersion"
    }
    
    private let plistPaths: [String]
    private let version: String
    private let buildNumber: String
    init(plistPaths: [String], version: String, buildNumber: String) {
        self.plistPaths = plistPaths
        self.version = version
        self.buildNumber = buildNumber
    }
    
    func itemsToUpdate(from items: [TreeItem]) -> [TreeItem] {
        return items.filter({ self.plistPaths.contains($0.path) })
    }
    
    func update(_ item: TreeItem, content: String) throws -> String {
        let matcher = RegexMatcher(text: content)
        matcher.replace(stringMatching: Constants.versionRegexString, with: self.replacementString(for: Constants.versionKey, value: self.version))
        matcher.replace(stringMatching: Constants.buildNumberRegexString, with: self.replacementString(for: Constants.buildNumberKey, value: self.buildNumber))
        return matcher.result
    }
    
    private func replacementString(for key: String, value: String) -> String {
        return "<key>" + key + "<\\/key>\n\t<string>" + value + "<\\/string>"
    }
    
}
