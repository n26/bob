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

struct Version {
    struct Build {
        public let value: String
        public init(_ value: String) {
            self.value = value
        }

        func bump() throws -> Build {
            let newBuildNumber: String
            if let numericBuildNumber = Int(value) {
                newBuildNumber = String(numericBuildNumber + 1)
            } else if let numericBuildString = RegexMatcher(text: value).matches(stringMatching: "[0-9]{1,}$").last,
                let numericBuildNumber = Int(numericBuildString) {
                let prefix = value.dropLast(numericBuildString.count)
                newBuildNumber = prefix + String(numericBuildNumber + 1)
            } else {
                throw "Could not bump up build number '\(value)' because it's not numeric."
            }
            return Build(newBuildNumber)
        }
    }

    let version: String
    let build: Build

    init(fromPlistContent content: String) throws {
        let (version, build) = try PListHelpers.version(fromPlistContent: content)
        self.version = version
        self.build = Build(build)
    }

    init(version: String, build: String) {
        self.init(version: version, build: Build(build))
    }

    init(version: String, build: Build) {
        self.version = version
        self.build = build
    }

    /// Bumps the build version only
    func bump() throws -> Version {
        return Version(version: version, build: try build.bump())
    }

    /// version + build number
    var fullVersion: String {
        return "\(version) (\(build.value))"
    }
    /// Commit message using the version and build number
    ///
    /// - Parameter template: Optional template where `<version>` will be replaced with the version string
    /// - Returns: e.g. `Version 3.2.0 123`
    func commitMessage(template: String? = nil) -> String {
        guard let template = template else {
            return fullVersion
        }
        return template.replacingOccurrences(of: "<version>", with: fullVersion)
    }
}
