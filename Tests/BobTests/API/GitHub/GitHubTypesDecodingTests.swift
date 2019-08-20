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
import XCTest
@testable import Bob


let decoder = GitHub.decoder

func AssertDecodes<T: Response>(model: T.Type, file: StaticString = #file, line: UInt = #line) {
    do {
        let model = try decoder.decode(T.self, from: model.response)
        print(model)
    } catch {
        XCTFail("Decoding failed: \(error)", file: file, line: line)
    }
}

class GitHubTypesDecodingTests: XCTestCase {

    func test_gitCommit_decodes() throws {
        AssertDecodes(model: GitHub.Git.Commit.self)
    }

    func test_gitTree_decodes() throws {
        AssertDecodes(model: GitHub.Git.Tree.self)
    }

    func test_repoCommit_decodes() throws {
        AssertDecodes(model: GitHub.Repos.Commit.self)
    }
}
