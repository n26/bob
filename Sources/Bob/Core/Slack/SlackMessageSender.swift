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

extension WebSocket {
    func send<T: Encodable>(message: T) throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(message)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            send(jsonString)
        }
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
        try! self.socket.send(message: slackMessage)
    }
}
