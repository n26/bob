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

import XCTest
@testable import Bob


class PListHelpersTests: XCTestCase {

    func test_parseVersion_givenValidString_returnsVersion() throws {
        let plist = """
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundleVersion</key>
            <string>1</string>
        """
        let (version, build) = try PListHelpers.version(fromPlistContent: plist)

        XCTAssertEqual(version, "1.0")
        XCTAssertEqual(build, "1")
    }
}
