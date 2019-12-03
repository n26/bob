//
//  EnvironmentInfoProvider.swift
//  Bob
//
//  Created by Jan Chaloupecky on 02.12.19.
//

import Foundation
import Service

public struct EnvironmentInfoProvider: InfoProvider {
    private let key: String

    public init(key: String) {
        self.key = key
    }
    public var name: String {
        return "env \(key)"
    }

    public var value: String {
        return Environment.get(key) ?? ""
    }
}
