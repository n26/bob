/*
 * Copyright (c) 2019 N26 GmbH.
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



extension Response {
    public struct Empty: Content { }
}

public extension Client {

    func get<T: Content>(_ uri: String, using decoder: JSONDecoder = JSONDecoder(), authorization: BasicAuthorization? = nil) throws -> Future<T> {
        let request = HTTPRequest(method: .GET, url: uri)
        return try perform(request, using: decoder)
    }

    func post<Body: Content, T: Content>(body: Body, to uri: String, encoder: JSONEncoder = JSONEncoder(), using decoder: JSONDecoder = JSONDecoder(), method: HTTPMethod = .POST, authorization: BasicAuthorization? = nil) throws -> Future<T> {
        var request = HTTPRequest(method: method, url: uri)
        let data = try encoder.encode(body)
        request.body = HTTPBody(data: data)
        request.contentType = .json
        return try perform(request, using: decoder)
    }

    func perform<T: Content>(_ request: HTTPRequest, using decoder: JSONDecoder = JSONDecoder(), authorization: BasicAuthorization? = nil) throws -> Future<T> {
        let req = Request(http: request, using: container)

        req.http.headers.basicAuthorization = authorization

        let futureResult = send(req)
        let featureContent = futureResult.flatMap { response -> EventLoopFuture<T> in
            guard response.http.status.isSuccessfulRequest else {
                var responseBody: String?
                if let data = response.http.body.data {
                    responseBody = String(data: data, encoding: .utf8)
                }
                throw GitHubError.invalidStatus(httpStatus: response.http.status.code, body: responseBody)
            }
            let futureDecode = try response.content.decode(json: T.self, using: decoder)
            futureDecode.whenFailure { error in
                print("\(request.method.string) \(request.url): \(error)")
            }
            return futureDecode
        }

        return featureContent
    }
}
