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

public class RegexMatcher {
    
    private var text: String
    public init(text: String) {
        self.text = text
    }
    
    /// Returns groups matching a regex
    ///
    /// - Parameters:
    ///   - regexString: Regex to match
    public func matches(stringMatching regexString: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regexString)
            let matches = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return matches.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch {
            return []
        }
    }
    
    /// Replaces group matching regex with a replacement
    ///
    /// - Parameters:
    ///   - regexString: Regex to match
    ///   - replacement: Replacement string
    public func replace(stringMatching regexString: String, with replacement: String) {
        self.text = self.text.replacingOccurrences(of: regexString, with: replacement, options: .regularExpression)
    }
    
    public var result: String {
        return self.text
    }
    
}
