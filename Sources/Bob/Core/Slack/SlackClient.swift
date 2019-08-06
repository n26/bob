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

extension Client {
    func loadRealtimeApi(token: String, simpleLatest: Bool = true, noUnreads: Bool = true) throws ->  EventLoopFuture<Response> {
        var headers = HTTPHeaders()
        headers.add(name: HTTPHeaderName.accept, value: "application/json; charset=utf-8")

        var components = URLComponents(url: URL(string: "https://slack.com/api/rtm.start")!, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "simple_latest", value: simpleLatest ? "1" : "0"),
            URLQueryItem(name: "no_unreads", value: noUnreads ? "1" : "0")
        ]

        return get(components.url!, headers: headers, beforeSend: { _ in })

    }
}

class SlackClient {

    private let token: String
    private let app: Application
    init(token: String, app: Application) {
        self.token = token
        self.app = app
    }
    
    func connect(onMessage: @escaping (_ message: String, _ sender: MessageSender) -> Void) throws {
        print("Starting Slack connection")


        let response = try app.client().loadRealtimeApi(token: token).wait()
        let slackResponse = try response.content.decode(SlackStartResponse.self).wait()

        let _ = try app.client().webSocket(slackResponse.url).flatMap { ws -> Future<Void> in

            ws.onText  { ws, text in
                print("[event] - \(text)")

                guard
                    let data = text.data(using: .utf8),
                    let event = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let channel = event?["channel"] as? String,
                    let text = event?["text"] as? String else {
                    return
                }

                let sender = SlackMessageSender(socket: ws, channel: channel)
                onMessage(text, sender)
            }

            return ws.onClose
        }
    }
    
}
