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
        var ranges = [Range<String.Index>]()
        
        var range: Range<String.Index>? = Range<String.Index>(uncheckedBounds: (lower: text.startIndex, upper: text.endIndex))
        
        while range != nil {
            let newRange = text.range(of: regexString, options: .regularExpression, range: range)
            
            if let `newRange` = newRange {
                ranges.append(newRange)
                range = Range<String.Index>(uncheckedBounds: (lower: newRange.upperBound, upper: text.endIndex))
            } else {
                range = nil
            }
        }
        
        var matches = [String]()
        
        ranges.forEach {
            matches.append(String(text.substring(with: $0)))
        }
        
        return matches
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
