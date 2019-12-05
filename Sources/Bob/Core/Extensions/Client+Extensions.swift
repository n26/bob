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

    func get<T: Decodable>(_ uri: String, using decoder: JSONDecoder = JSONDecoder(), authorization: BasicAuthorization? = nil, headers: HTTPHeaders? = nil) throws -> Future<T> {
        var request = HTTPRequest(method: .GET, url: uri)
        if let headers = headers {
            request.headers = headers
        }
        return try perform(request, using: decoder, authorization: authorization)
    }

    func post<Body: Content, T: Decodable>(body: Body, to uri: String, encoder: JSONEncoder = JSONEncoder(), using decoder: JSONDecoder = JSONDecoder(), method: HTTPMethod = .POST, authorization: BasicAuthorization? = nil) throws -> Future<T> {
        var request = HTTPRequest(method: method, url: uri)
        let data = try encoder.encode(body)
        request.body = HTTPBody(data: data)
        request.contentType = .json
        return try perform(request, using: decoder, authorization: authorization)
    }

    func perform<T: Decodable>(_ request: HTTPRequest, using decoder: JSONDecoder = JSONDecoder(), authorization: BasicAuthorization? = nil) throws -> Future<T> {
        let req = Request(http: request, using: container)

        if let authorization = authorization {
            req.http.headers.basicAuthorization = authorization
        }

        let futureResult = send(req)
        let featureContent = futureResult.flatMap { response -> EventLoopFuture<T> in
            return try self.decode(response: response, using: decoder)
        }

        return featureContent
    }

    func decode<T: Decodable>(response: Response, using decoder: JSONDecoder) throws -> Future<T> {
        guard response.http.status.isSuccessfulRequest else {
            var responseBody: String?
            if let data = response.http.body.data {
                responseBody = String(data: data, encoding: .utf8)
            }
            throw GitHubError.invalidStatus(httpStatus: response.http.status.code, body: responseBody)
        }

        if T.self is Response.Empty.Type {
            return self.container.future(Response.Empty() as! T)
        }
        return try response.content.decode(json: T.self, using: decoder)

    }
}
