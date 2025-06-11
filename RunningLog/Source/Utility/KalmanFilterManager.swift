import CoreLocation

protocol KalmanFilterManagerProtocol {
    func filter(location: CLLocation) -> CLLocation?
    func reset()
}

final class DefaultKalmanFilterManager: KalmanFilterManagerProtocol {
    private var lastLocation: CLLocation?
    private let filter = KalmanFilter2D()
    private let maxHumanSpeed: CLLocationSpeed = 20.0 // m/s
    private let minSpeed: CLLocationSpeed = 2.0 // 2m/s 미만 무시

    func filter(location: CLLocation) -> CLLocation? {
        if let last = lastLocation {
            let distance = last.distance(from: location)
            let time = location.timestamp.timeIntervalSince(last.timestamp)
            let speed = distance / max(time, 0.1)
            if speed > maxHumanSpeed || speed < minSpeed {
                print("[KalmanFilterManager] 이상치 위치 무시: 거리 \(distance)m, 속도 \(speed)m/s")
                return nil
            }
        }
        lastLocation = location
        let (filteredLat, filteredLon) = filter.filter(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: filteredLat, longitude: filteredLon),
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            course: location.course,
            speed: location.speed,
            timestamp: location.timestamp
        )
    }
    
    func reset() {
        lastLocation = nil
        filter.reset()
    }
} 