//
//  InfoProvider.swift
//  Bob
//
//  Created by Jan Chaloupecky on 02.12.19.
//

import Foundation

/// Used by the `InfoCommand` to provide a name and value to the list
/// Use you can register a provider using `infoCommand.register(MyInfoProvider())`
public protocol InfoProvider {
    /// The name of the provided information printed to Slack
    var name: String { get }

    /// The value of the provided information printed to Slack
    var value: String { get }
}
