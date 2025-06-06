import Foundation

public protocol LocationClient {
    func requestLocation() async throws -> (latitude: Double, longitude: Double, address: String)
} 