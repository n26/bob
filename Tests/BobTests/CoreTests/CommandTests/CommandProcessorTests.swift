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

import XCTest
@testable import Bob

fileprivate struct MockCommand: Command {
    
    let name: String
    let usage: String
    
    func execute(with parameters: [String], replyingTo sender: MessageSender, completion: @escaping (_ error: Error?) -> Void) throws { }
}

class CommandProcessorTests: XCTestCase {
    
    static var allTests : [(String, (CommandProcessorTests) -> () throws -> Void)] {
        return [
            ("testProcessorShouldReturnAlignExecutableCommand", testProcessorShouldReturnAlignExecutableCommand),
            ("testProcessorShouldThrowOnUnknownExecutableCommand", testProcessorShouldThrowOnUnknownExecutableCommand),
            ("testProcessorShouldProperlyChainCommands", testProcessorShouldProperlyChainCommands),
            ("testProcessorShouldAppendCorrectParametersToCommand", testProcessorShouldAppendCorrectParametersToCommand)
        ]
    }
    
    var alignCommand: Command!
    var buildCommand: Command!
    var factory: CommandFactory!
    var processor: CommandProcessor!
    
    override func setUp() {
        self.alignCommand = MockCommand(name: "align", usage: "usage")
        self.buildCommand = MockCommand(name: "build", usage: "usage")
        self.factory = CommandFactory(commands: [self.alignCommand, self.buildCommand])
        self.processor = CommandProcessor(factory: factory)
    }
    
    func testProcessorShouldReturnAlignExecutableCommand() throws {
        let commands = try self.processor.executableCommands(from: "align")
        
        XCTAssertEqual(commands.count, 1)
        XCTAssertEqual(commands.first?.command.name, "align")
    }
    
    func testProcessorShouldThrowOnUnknownExecutableCommand() throws {
        XCTAssertThrowsError(try self.processor.executableCommands(from: "foo")) { (error) in
            // error should be of type `CommandProcessor.ProcessingError`
            XCTAssertNotNil(error as? CommandProcessor.ProcessingError)
        }
    }
    
    func testProcessorShouldProperlyChainCommands() throws {
        let commands = try self.processor.executableCommands(from: "align | build")
       
        XCTAssertEqual(commands.count, 2)
        XCTAssertEqual(commands[0].command.name, self.alignCommand.name)
        XCTAssertEqual(commands[1].command.name, self.buildCommand.name)
    }
    
    func testProcessorShouldAppendCorrectParametersToCommand() throws {
        let command = try self.processor.executableCommands(from: "build staging 3.1").first!
        
        XCTAssertEqual(command.parameters, ["staging", "3.1"])
    }
    
}
