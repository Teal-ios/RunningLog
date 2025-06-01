//
//  DataTransferService.swift
//  RunningLog
//
//  Created by Den on 6/1/25.
//

import Foundation

final class DataTransferService {
    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func request<T: Decodable, E: TargetType>(with target: E) async throws -> T where E.Response == T {
        do {
            let responseData = try await networkService.request(target: target)
            print(responseData)
            let decodedData = try JSONDecoder().decode(T.self, from: responseData)
            print(decodedData)
            return decodedData
        } catch {
            print("❌ Error From: \(target.request)")
            print(error)
            throw RLError.decodingError(error: error)
        }
    }
}

