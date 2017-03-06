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

class CommandExecutor {
    
    func execute(_ commands: [ExecutableCommand], replyingTo sender: MessageSender) {
        self.execute(commandAt: 0, from: commands, replyingTo: sender)
    }
    
    private func execute(commandAt index: Int, from commands: [ExecutableCommand], replyingTo originalSender: MessageSender) {
        guard index < commands.count else { return }
        let executable = commands[index]
        
        var sender = originalSender
        if commands.count > 1 {
            sender = PrefixedMessageSender(prefix: "[\(executable.command.name)]", sender: originalSender)
        }
        
        if executable.parameters.first == .some("usage") {
            sender.send(executable.command.usage)
            self.execute(commandAt: index + 1, from: commands, replyingTo: originalSender)
        } else {
            do {
                try executable.command.execute(with: executable.parameters, replyingTo: sender, completion: { (error) in
                    if let error = error {
                        sender.send(error.userFriendlyMessage)
                    } else {
                        self.execute(commandAt: index + 1, from: commands, replyingTo: originalSender)
                    }
                })
            } catch {
                sender.send(error.userFriendlyMessage)
            }
        }
        
    }
    
}
