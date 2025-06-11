import Foundation
import CoreLocation

public protocol LocationClient {
    func requestLocation() async throws -> (latitude: Double, longitude: Double, address: String)
    func requestLocationUpdates() async throws -> AsyncStream<CLLocation>
}

// MARK: - Extensions
extension LocationClient {
    static var live: LocationClient {
        SharedLocationClient.shared
    }
    
    static var mock: LocationClient {
        MockLocationClient()
    }
}

private class SharedLocationClient {
    static let shared: LocationClient = LocationClientImpl()
}

// MARK: - Mock Implementation
struct MockLocationClient: LocationClient {
    func requestLocation() async throws -> (latitude: Double, longitude: Double, address: String) {
        return (37.5665, 126.9780, "중구 서울")
    }
    
    func requestLocationUpdates() async throws -> AsyncStream<CLLocation> {
        return AsyncStream { continuation in
            Task {
                // 시뮬레이션용 위치 데이터를 3초마다 전송
                var latitude = 37.5665
                var longitude = 126.9780
                
                while true {
                    // 약간씩 위치를 변경하여 이동을 시뮬레이션
                    latitude += Double.random(in: -0.0001...0.0001)
                    longitude += Double.random(in: -0.0001...0.0001)
                    
                    let location = CLLocation(latitude: latitude, longitude: longitude)
                    continuation.yield(location)
                    
                    try await Task.sleep(nanoseconds: 3_000_000_000) // 3초
                }
            }
        }
    }
}

