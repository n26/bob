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

public protocol Command {
    /// The name used to idenitfy a command (`hello`, `version` etc.). Case insensitive
    var name: String { get }
    
    /// String describing how to use the command.
    var usage: String { get }
    
    /// Executes the command
    ///
    /// - Parameters:
    ///   - parameters: parameters passed to the command
    ///   - sender: object used to send feedback to the user
    ///   - completion: block to be called when the command finishes. In case of an error, pass it in
    /// - Throws: An error is thrown if something goes wrong while executing the command, usualy while parsing the parameters
    func execute(with parameters: [String], replyingTo sender: MessageSender) throws
}
