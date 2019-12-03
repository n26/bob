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
import Vapor

public class Bob {
    static let version: String = "2.1.5"
    
    /// Struct containing all properties needed for Bob to function
    public struct Configuration {
        public let slackToken: String
        
        /// Initializer
        ///
        /// - Parameter slackToken: Bot API token used to connect to slack
        public init(slackToken: String) {
            self.slackToken = slackToken
        }
    }
    
    private let slackClient: SlackClient
    private let factory: CommandFactory
    private let processor: CommandProcessor
    private let executor: CommandExecutor
    
    /// Initializer
    ///
    /// - Parameter configuration: Configuration for setup
    /// - Parameter app: Application
    public init(config: Configuration, app: Application) {
        self.slackClient = SlackClient(token: config.slackToken, app: app)
        self.factory = CommandFactory(commands: [HelloCommand(), VersionCommand()])
        self.processor = CommandProcessor(factory: self.factory)
        self.executor = CommandExecutor()
    }
    
    /// Registers commands so they become available for usage
    ///
    /// - Parameter commands: Commands to register
    /// - Throws: Throws an error if a command with the same name is already registered
    public func register(_ commands: Command...) throws {
        for command in commands {
            try self.factory.register(command)
        }
    }
    
    /// Starts listening to messages and processing them
    ///
    /// - Throws: Throws an error if it occurs
    public func start() throws {
        try self.slackClient.connect { message, sender in
            do {
                let commands = try self.processor.executableCommands(from: message)
                if commands.count > 0 {
                    self.executor.execute(commands, replyingTo: sender)
                } else {
                    let message = "Did not quite understand that.\n" + self.factory.availableCommands
                    sender.send(message)
                }
            } catch {
                if let processingError = error as? CommandProcessor.ProcessingError {
                    let errorMessage = "Could not find command with name `\(processingError.commandName)`.\n"
                    + self.factory.availableCommands
                    + "\nIf you want to know more about a command, you can do:\n`{{command}} usage`"
                    sender.send(errorMessage)
                } else {
                    sender.send(error.userFriendlyMessage)
                }
            }
        }
    }
}

fileprivate extension CommandFactory {
    var availableCommands: String {
        var string = "Available commands:"
        self.commands.forEach({ string += "\n• " + $0.name })
        return string
    }
}
