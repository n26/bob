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
import HTTP
import Vapor

extension Client {
    func loadRealtimeApi(token: String, simpleLatest: Bool = true, noUnreads: Bool = true) throws -> EventLoopFuture<Response> {
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

    func loadSlackRealTimeURL(token: String, simpleLatest: Bool = true, noUnreads: Bool = true) throws -> Future<SlackStartResponse.Success> {
        let result = try loadRealtimeApi(token: token).flatMap(to: SlackStartResponse.Success.self) { response in

            let slackResponse = try response.content.syncDecode(SlackStartResponse.self)

            if !slackResponse.ok {
                throw "Slack RTM response does not containt a URL. Is your slack token correct?"
            }
            return try response.content.decode(SlackStartResponse.Success.self)
        }
        return result

    }
}

class SlackClient {

    // https://api.slack.com/rtm
    enum Event {
        fileprivate enum RawType: String {
            /// https://api.slack.com/events/message
            case message

            /// https://api.slack.com/events/goodbye
            case goodbye
        }

        struct Message: Decodable {
            let text: String
            let channel: String
            let user: String
        }

        case message(Message)
        case goodbye
    }

    private let token: String
    private let app: Application
    private let reconnectAfter: TimeInterval
    private let logger: Logger

    private var onMessage: ((_ message: String, _ sender: MessageSender) -> Void)?

    init(token: String, app: Application, reconnectAfter: TimeInterval = 60) {
        self.token = token
        self.app = app
        self.reconnectAfter = reconnectAfter
        self.logger = try! app.make(Logger.self)
    }
    
    func connect(onMessage: @escaping (_ message: String, _ sender: MessageSender) -> Void) throws {
        self.onMessage = onMessage
        try createConnection()
    }

    private func createConnection() throws {
        let logger = try app.make(Logger.self)

        logger.info("Requesting RTM url")
        try app.client().loadSlackRealTimeURL(token: token).map { slackResponse in
            logger.info("Connecting to RTM url")

            let _ = try self.app.client().webSocket(slackResponse.url).flatMap { ws -> Future<Void> in

                ws.onText { ws, text in
                    self.onText(ws: ws, text: text, me: slackResponse.me, logger: logger)
                }

                ws.onCloseCode { code in
                    logger.error("Closed \(code)")
                }

                ws.onError { ws, error in
                    logger.error("ws onError: \(error)")
                    self.reconnectWithTimeout()
                }
                return ws.onClose
            }.map {
                logger.info("ws close")
                self.reconnectWithTimeout()
            }
            .catch { error in
                logger.error("ws error: \(error)")
                self.reconnectWithTimeout()
            }
        }.catch { error in
            logger.error("Failed to request RTM url: \(error)")
        }
        logger.info("Connected to Slack")
    }

    private func reconnectWithTimeout() {
        logger.info("Reconnecting after \(reconnectAfter)s")
        app.eventLoop.scheduleTask(in: TimeAmount.seconds(TimeAmount.Value(reconnectAfter))) {
            try self.createConnection()
        }
    }

    // MARK: - Event handling
    private  func onText(ws: WebSocket, text: String, me: SlackStartResponse.Success.User, logger: Logger) {
        logger.debug("[event] - \(text)")

        do {
            guard let event = try self.event(fromText: text) else { return }

            switch event {
            case .message(let message):
                guard message.user != me.id else {
                    logger.warning("Ignoring message from another instance of myself: '\(message.text)'")
                    return
                }
                let sender = SlackMessageSender(socket: ws, channel: message.channel)
                onMessage?(message.text, sender)
            case .goodbye:
                logger.info("Received goodbye event. Closing connection")
                ws.close()
            }
        } catch {
            logger.info("Could not parse Slack event: \(error)")
        }
    }

    // MARK: - Private Parsing

    /// Parses a Event from a slack websocket message
    /// - Parameter text: the slack json event
    /// - returns: The Event or nil when the type is not one of Event.RawType
    /// - throws: When a known even could not be parsed
    private func event(fromText text: String) throws -> Event? {
        guard let (rawType, data) = messageType(fromText: text) else {
            return nil
        }
        return try event(rawType: rawType, from: data)

    }
    private func messageType(fromText text: String) -> (Event.RawType, Data)? {
        guard
            let data = text.data(using: .utf8),
            let event = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let typeRaw = event?["type"] as? String,
            let rawType = Event.RawType.init(rawValue: typeRaw) else {
                return nil
        }
        return (rawType, data)
    }

    private func event(rawType: Event.RawType, from data: Data) throws -> Event {
        let decoder = JSONDecoder()
        switch rawType {
        case .message:
            return .message(try decoder.decode(Event.Message.self, from: data))
        case .goodbye:
            return .goodbye
        }
    }
}
