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

fileprivate struct SlackMessage {
    
    static var messageCounter: Int = 0
    static var lastTimestamp: UInt64 = 0
    
    let id: UInt64
    let channel: String
    let text: String
    
    init(to channel: String, text: String) {
        
        let timestamp = UInt64(floor(Date().timeIntervalSince1970))
        if timestamp != SlackMessage.lastTimestamp {
            SlackMessage.lastTimestamp = timestamp
            SlackMessage.messageCounter = 0
        }
        
        self.id = timestamp * 1000 + UInt64(SlackMessage.messageCounter)
        SlackMessage.messageCounter += 1
        self.channel = channel
        self.text = text
    }
}

extension SlackMessage: NodeRepresentable {
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id, "channel": channel,
                               "type": "message",
                               "text": text])
    }
}

extension WebSocket {
    func send(_ node: NodeRepresentable) throws {
        let json = try node.converted(to: JSON.self)
        let message = try json.makeBytes()
        try send(message.string)
    }
}


class SlackMessageSender: MessageSender {
    
    private let socket: WebSocket
    private let channel: String
    init(socket: WebSocket, channel: String) {
        self.socket = socket
        self.channel = channel
    }
    
    func send(_ message: String) {
        let slackMessage = SlackMessage(to: self.channel, text: message)
        try? self.socket.send(slackMessage)
    }
}
