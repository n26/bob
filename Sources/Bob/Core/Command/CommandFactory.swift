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

class CommandFactory {
    enum CommandFactoryError: Error {
        case register(String)
    }
    
    internal private(set) var commands: [Command] = []
    init(commands: [Command]) {
        self.commands = commands
    }
    
    func register(_ command: Command) throws {
        let existingCommand = self.command(withName: command.name)
        guard existingCommand == nil else { throw CommandFactoryError.register("Command with name `\(command.name)` already exists: \(existingCommand!)") }
        self.commands.append(command)
    }
    
    func command(withName name: String) -> Command? {
        let lowercasedName = name.lowercased()
        return self.commands.first(where: { $0.name.lowercased() == lowercasedName })
    }
}
