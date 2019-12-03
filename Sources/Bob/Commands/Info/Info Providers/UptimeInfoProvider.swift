//
//  UptimeInfoProvider.swift
//  Bob
//
//  Created by Jan Chaloupecky on 02.12.19.
//

import Foundation

struct UptimeInfoProvider: InfoProvider {
    private let date = Date()
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm"
        return formatter
    }()

    var name = "Uptime since"
    var value: String {
        return "\(formatter.string(from: date))"
    }
}
