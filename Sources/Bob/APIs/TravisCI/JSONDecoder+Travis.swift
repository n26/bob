//
//  JSONDecoder+Travis.swift
//  Bob
//
//  Created by Jan Chaloupecky on 05.12.19.
//

import Foundation

extension JSONDecoder {
    static let travis: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}
