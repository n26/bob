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
import HTTP
import TLS
import Transport

extension HTTP.Client {
    static func loadRealtimeApi(token: String, simpleLatest: Bool = true, noUnreads: Bool = true) throws -> HTTP.Response {
        let headers: [HeaderKey: String] = ["Accept": "application/json; charset=utf-8"]
        let query: [String: CustomStringConvertible] = [
            "token": token,
            "simple_latest": simpleLatest ? 1 : 0,
            "no_unreads": noUnreads ? 1 : 0
        ]
        return try get(
            "https://slack.com/api/rtm.start",
            headers: headers,
            query: query
        )
    }
}

class SlackClient {

    private let token: String
    init(token: String) {
        self.token = token
        defaultClientConfig = {
            return try TLS.Config(context: try Context(mode: .client), certificates: .none, verifyHost: false, verifyCertificates: false, cipher: .compat)
        }
    }
    
    func connect(onMessage: @escaping (_ message: String, _ sender: MessageSender) -> Void) throws {
        
        let rtmResponse = try BasicClient.loadRealtimeApi(token: self.token)
        guard let webSocketURL = rtmResponse.data["url"]?.string else { throw "Unable to retrieve `url` from slack. Raw response \(rtmResponse.data)" }
        
        try WebSocket.connect(to: webSocketURL) { socket in
            
            print("Connected to \(webSocketURL)")
            
            socket.onText = { ws, text in
                print("[event] - \(text)")
                
                let event = try JSON(bytes: text.utf8.array)
                
                guard
                    let channel = event["channel"]?.string,
                    let text = event["text"]?.string
                    else { return }
                
                let sender = SlackMessageSender(socket: socket, channel: channel)
                
                onMessage(text, sender)
            }
            
            socket.onClose = { _ in
                print("\n[CLOSED]\n")
            }
        }


    }
    
}
