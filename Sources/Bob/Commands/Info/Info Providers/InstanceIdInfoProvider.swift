//
//  InstanceIdInfoProvider.swift
//  Bob
//
//  Created by Jan Chaloupecky on 02.12.19.
//

import Foundation

public struct InstanceIdInfoProvider: InfoProvider {
    public let name = "Instance Id"
    public let value = UUID().uuidString
}
