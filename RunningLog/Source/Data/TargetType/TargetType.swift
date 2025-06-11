//
//  TargetType.swift
//  RunningLog
//
//  Created by Den on 6/1/25.
//

import Foundation

protocol TargetType {
    associatedtype Response
    
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var httpMethod: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var header: [String: String] { get }
    var parameters: String? { get }
    var port: Int? { get }
    var body: Data? { get }
}

extension TargetType {
    var components: URLComponents {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        components.queryItems = queryItems
        components.port = port
        return components
    }
    
    var request: URLRequest {
        guard let url = components.url else {
            print(components)
            fatalError("URL ERRROR") }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.allHTTPHeaderFields = header
        request.httpBody = parameters?.data(using: .utf8)
        request.httpBody = body
        return request
    }
}
