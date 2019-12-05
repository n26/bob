//
//  InfoCommand.swift
//  Bob
//
//  Created by Jan Chaloupecky on 02.12.19.
//

import Foundation

/// The `InfoCommand` prints a list of key/values provided by `InfoProvider`
/// It's meant to provide info about a running instance of Bob
public class InfoCommand: Command {
    private var providers: [InfoProvider] = [
        InstanceIdInfoProvider(),
        UptimeInfoProvider()
    ]
    public let name = "info"

    public init() {
    }
    public var usage: String {
        return "`info` prints information about the Bob instance"
    }

    public func execute(with parameters: [String], replyingTo sender: MessageSender) throws {
        let result = providers
            .map { "\($0.name): \($0.value)" }
            .reduce("") { $0 + $1 + "\n" }
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let response = """
        ```
        \(result)
        ```
        """
        sender.send(response)
    }

    public func register(_ provider: InfoProvider) {
        providers.append(provider)
    }
}
