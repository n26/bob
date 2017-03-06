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

fileprivate class MockCommand: Command {
    
    let name: String
    let usage: String
    var hasBeenExecuted = false
    
    init(name: String, usage: String) {
        self.name = name
        self.usage = usage
    }
    
    func execute(with parameters: [String], replyingTo sender: MessageSender, completion: @escaping (_ error: Error?) -> Void) throws {
        self.hasBeenExecuted = true
        completion(nil)
    }

}

fileprivate class MockErroredCommand: Command {
    let name = "name"
    let usage = "usage"
    static let error = "an error message"
    
    func execute(with parameters: [String], replyingTo sender: MessageSender, completion: @escaping (_ error: Error?) -> Void) throws {
        completion(MockErroredCommand.error)
    }
    
}

fileprivate class MockMessageSender: MessageSender {
    
    var receivedMessage: String = ""
    
    func send(_ message: String) {
        self.receivedMessage = message
    }
    
}

class CommandExecutorTests: XCTestCase {
    
    static var allTests : [(String, (CommandExecutorTests) -> () throws -> Void)] {
        return [
            ("testExecutorShouldSendBuildUsageToMessageSender", testExecutorShouldSendBuildUsageToMessageSender),
            ("testExecutorShouldExecuteBuildCommand", testExecutorShouldExecuteBuildCommand),
            ("testExecutorShouldReturnErrorMessage", testExecutorShouldReturnErrorMessage),
        ]
    }
    
    fileprivate var executor: CommandExecutor!
    fileprivate var buildCommand: MockCommand!
    fileprivate var messageSender: MockMessageSender!
    
    override func setUp() {
        self.buildCommand = MockCommand(name: "build", usage: "build command usage")
        self.executor = CommandExecutor()
        self.messageSender = MockMessageSender()
    }

    func testExecutorShouldSendBuildUsageToMessageSender() {
        let executableBuildUsage = ExecutableCommand(command: buildCommand, parameters: ["usage"])
        
        self.executor.execute([executableBuildUsage], replyingTo: self.messageSender)
        
        XCTAssertEqual(self.messageSender.receivedMessage, self.buildCommand.usage)
    }
    
    func testExecutorShouldExecuteBuildCommand() {
        let executableBuildCommand = ExecutableCommand(command: self.buildCommand, parameters: ["staging 3.1"])
        
        self.executor.execute([executableBuildCommand], replyingTo: self.messageSender)
        
        XCTAssertTrue(self.buildCommand.hasBeenExecuted)
    }
    
    func testExecutorShouldReturnErrorMessage() {
        let executableErrorCommand = ExecutableCommand(command: MockErroredCommand(), parameters: [])
        self.executor.execute([executableErrorCommand], replyingTo: self.messageSender)

        XCTAssertEqual(self.messageSender.receivedMessage, MockErroredCommand.error)
    }
}
