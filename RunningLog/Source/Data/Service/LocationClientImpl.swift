import Foundation
import CoreLocation

final class LocationClientImpl: NSObject, LocationClient, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<(latitude: Double, longitude: Double, address: String), Error>?
    private var shouldRequestLocation = false
    private var isRequestingLocation = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        print("[LocationClientImpl] init/delegate set")
    }
    
    func requestLocation() async throws -> (latitude: Double, longitude: Double, address: String) {
        if isRequestingLocation {
            print("[LocationClientImpl] 이미 위치 요청 중, 중복 요청 방지")
            throw NSError(domain: "LocationError", code: 2, userInfo: [NSLocalizedDescriptionKey: "이미 위치 요청 중입니다."])
        }
        isRequestingLocation = true
        defer { isRequestingLocation = false }
        let status = manager.authorizationStatus
        print("[LocationClientImpl] requestLocation() called, status: \(status.rawValue)")
        if status == .notDetermined {
            shouldRequestLocation = true
            print("[LocationClientImpl] 권한 notDetermined → 권한 요청")
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("[LocationClientImpl] 권한 승인됨 → 위치 요청")
            manager.requestLocation()
        } else {
            print("[LocationClientImpl] 권한 거부됨")
            throw NSError(domain: "LocationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "위치 권한이 필요합니다."])
        }
        return try await withCheckedThrowingContinuation { continuation in
            print("[LocationClientImpl] withCheckedThrowingContinuation 대기 시작")
            self.continuation = continuation
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("[LocationClientImpl] didChangeAuthorization: \(status.rawValue)")
        if shouldRequestLocation && (status == .authorizedWhenInUse || status == .authorizedAlways) {
            shouldRequestLocation = false
            print("[LocationClientImpl] 권한 승인됨 → 위치 요청(재시도)")
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("[LocationClientImpl] didUpdateLocations 호출됨: \(locations)")
        guard let location = locations.last else {
            print("[LocationClientImpl] 위치 없음 에러")
            continuation?.resume(throwing: NSError(domain: "LocationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "위치 정보를 가져올 수 없습니다."]))
            continuation = nil
            return
        }
        let geocoder = CLGeocoder()
        print("[LocationClientImpl] reverseGeocodeLocation 시작")
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("[LocationClientImpl] reverseGeocodeLocation 에러: \(error)")
                self.continuation?.resume(throwing: error)
                self.continuation = nil
                return
            }
            let placemark = placemarks?.first
            let gu = placemark?.subLocality ?? ""
            let si = placemark?.locality ?? ""
            let address = [gu, si].filter { !$0.isEmpty }.joined(separator: " ")
            print("[LocationClientImpl] 주소 변환 결과: \(address)")
            self.continuation?.resume(returning: (location.coordinate.latitude, location.coordinate.longitude, address))
            self.continuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationClientImpl] didFailWithError: \(error)")
        continuation?.resume(throwing: error)
        continuation = nil
    }
} 
