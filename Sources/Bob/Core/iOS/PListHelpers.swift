//
//  PListHelpers.swift
//  BobPackageDescription
//
//  Created by Daniel Peter on 13.04.18.
//

import Foundation

class PListHelpers {
    
    static let versionRegexString: String = "<key>CFBundleShortVersionString<\\/key>\\s*<string>(\\S+)<\\/string>"
    static let versionKey: String = "CFBundleShortVersionString"
    static let buildNumberRegexString: String = "<key>CFBundleVersion<\\/key>\\s*<string>(\\S+)<\\/string>"
    static let buildNumberKey: String = "CFBundleVersion"
    
    static func extractStringValue(from text: String) -> String {
        let matches = RegexMatcher(text: text).matches(stringMatching: "<string>(.+?)</string>")
        
        guard matches.count > 0 else {
            return ""
        }
        
        return matches[0].replacingOccurrences(of: "<string>", with: "").replacingOccurrences(of: "</string>", with: "")
    }
    
    static func replacementString(for key: String, value: String) -> String {
        return "<key>" + key + "<\\/key>\n\t<string>" + value + "<\\/string>"
    }

    static func version(fromPlistContent content: String) throws -> (version: String, build: String) {

        let matcher = RegexMatcher(text: content)

        let versions = matcher.matches(stringMatching: PListHelpers.versionRegexString)
        guard let version = versions.first else {
            throw "Failed to bump version. Could not find version number in Plist file."
        }
        let versionString = PListHelpers.extractStringValue(from: version)

        let buildNumbers = matcher.matches(stringMatching: PListHelpers.buildNumberRegexString)
        guard let first = buildNumbers.first else {
            throw "Failed to bump version. Could not find build number in Plist file."
        }
        let buildNumberText = PListHelpers.extractStringValue(from: first)

        return (version: versionString, build: buildNumberText)
    }
}
