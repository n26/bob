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
    
    func execute(with parameters: [String], replyingTo sender: MessageSender) throws { }
}

class CommandFactoryTests: XCTestCase {
    
    static var allTests : [(String, (CommandFactoryTests) -> () throws -> Void)] {
        return [
            ("testShouldRegisterCommand", testShouldRegisterCommand),
            ("testShouldntRegisterCommandWithTheSameName", testShouldntRegisterCommandWithTheSameName),
            ("testShouldRetrieveCommandWithName", testShouldRetrieveCommandWithName),
        ]
    }
    
    var factory: CommandFactory!
    
    override func setUp() {
        self.factory = CommandFactory(commands: [])
    }
    
    func testShouldRegisterCommand() throws {
        let command = MockCommand(name: "command", usage: "usage")
        
        try self.factory.register(command)
    }
    
    func testShouldntRegisterCommandWithTheSameName() throws {
        let aCommand = MockCommand(name: "command", usage: "usage")
        let bCommand = MockCommand(name: "command", usage: "usage")

        try self.factory.register(aCommand)
        
        XCTAssertThrowsError(try self.factory.register(bCommand))
    }
    
    func testShouldRetrieveCommandWithName() throws {
        let command = MockCommand(name: "command", usage: "usage")

        try self.factory.register(command)
        
        XCTAssertEqual(self.factory.command(withName: command.name)?.name, command.name)
    }
    
}
