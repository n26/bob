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

class CommandProcessor {
    struct ProcessingError: Error {
        let commandName: String
    }
    
    private let factory: CommandFactory
    init(factory: CommandFactory) {
        self.factory = factory
    }
    
    /// Returns an array of commands parsed from the message
    ///
    /// - Parameter message: message to parse
    /// - Returns: array of commands.
    /// - Throws: Throws `CommandProcessor.ProcessingError` if a command for specified name does not exist
    func executableCommands(from message: String) throws -> [ExecutableCommand] {
        var commands: [ExecutableCommand] = []
        let commandLines = message.components(separatedBy: "|").map({ $0.trimmingCharacters(in: .whitespaces) })
        
        for commandLine in commandLines {
            var parameters = commandLine.components(separatedBy: " ")
            guard parameters.count > 0 else { continue }
            let commandName = parameters[0]
            parameters.remove(at: 0) // Remove the first 'commandName' element
            
            let command = self.factory.command(withName: commandName)
            
            if let command = command {
                commands.append(ExecutableCommand(command: command, parameters: parameters))
            } else {
                throw ProcessingError(commandName: commandName)
            }
        }
        
        return commands
    }
}
