//
//  NetworkService.swift
//  RunningLog
//
//  Created by Den on 6/1/25.
//

import Foundation

final class NetworkService {
        
    func request(target: any TargetType) async throws -> Data {
        do {
            let urlRequest = target.request
            print("✅ 보내는 URLRequest",target.request)
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
             guard let response = response as? HTTPURLResponse else { throw RLError.httpURLResponse }

            switch response.statusCode {
            case 200:
                return data
            default:
                print("😅 INTERNAL ERROR", response.statusCode)
                throw RLError.statusCodeError(statusCode: response.statusCode)
            }
        } catch {
            print(error)
            throw RLError.unKnown
        }
    }
}
