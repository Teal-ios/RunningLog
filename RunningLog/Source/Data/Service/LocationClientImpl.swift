//
//  LocationClientImpl.swift
//  RunningLog
//
//  Created by Den on 5/26/25.
//

import Foundation
import CoreLocation

final class LocationClientImpl: NSObject, LocationClient {
    private let locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<(latitude: Double, longitude: Double, address: String), Error>?
    private var locationUpdatesContinuation: AsyncStream<CLLocation>.Continuation?
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        let delegateStatus = self.locationManager.delegate != nil ? "OK" : "nil"
        print("🧩 LocationClientImpl init, delegate: \(delegateStatus)")
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 1.0 // 5미터마다 업데이트
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestLocation() async throws -> (latitude: Double, longitude: Double, address: String) {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            
            DispatchQueue.main.async {
                print("📍 위치 권한 상태: \(self.locationManager.authorizationStatus.rawValue)")
                
                switch self.locationManager.authorizationStatus {
                case .notDetermined:
                    print("📍 위치 권한 요청 중...")
                    self.locationManager.requestWhenInUseAuthorization()
                case .denied, .restricted:
                    print("📍 위치 권한 거부됨")
                    continuation.resume(throwing: RLError.locationPermissionDenied)
                    return
                case .authorizedWhenInUse, .authorizedAlways:
                    print("📍 위치 요청 시작...")
                    self.locationManager.requestLocation()
                @unknown default:
                    continuation.resume(throwing: RLError.unknown)
                    return
                }
            }
        }
    }
    
    func requestLocationUpdates() async throws -> AsyncStream<CLLocation> {
        print("🟢 requestLocationUpdates() 호출됨")
        return AsyncStream { continuation in
            self.locationUpdatesContinuation = continuation
            
            DispatchQueue.main.async {
                print("📍 위치 업데이트 스트림 시작")
                
                switch self.locationManager.authorizationStatus {
                case .notDetermined:
                    print("📍 위치 권한 요청 중...")
                    self.locationManager.requestWhenInUseAuthorization()
                case .denied, .restricted:
                    print("📍 위치 권한 거부됨")
                    continuation.finish()
                    return
                case .authorizedWhenInUse, .authorizedAlways:
                    print("📍 연속 위치 업데이트 시작...")
                    self.locationManager.startUpdatingLocation()
                @unknown default:
                    continuation.finish()
                    return
                }
            }
            
            continuation.onTermination = { _ in
                print("📍 위치 업데이트 스트림 종료")
                DispatchQueue.main.async {
                    self.locationManager.stopUpdatingLocation()
                }
            }
        }
    }
    
    private func convertToAddress(from location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                var addressComponents: [String] = []
                
                if let subLocality = placemark.subLocality {
                    addressComponents.append(subLocality)
                }
                
                if let locality = placemark.locality {
                    addressComponents.append(locality)
                }
                
                let address = addressComponents.joined(separator: " ")
                print("📍 주소 변환 완료: \(address)")
                return address.isEmpty ? "알 수 없는 위치" : address
            }
        } catch {
            print("📍 주소 변환 실패: \(error.localizedDescription)")
        }
        
        return "알 수 없는 위치"
    }
    
    deinit {
        print("❌ LocationClientImpl deinit(메모리 해제됨)")
    }
}

extension LocationClientImpl: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("🔥 didUpdateLocations 진입: count = \(locations.count)")
        if let loc = locations.first {
            print("🔥 위치 콜백: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
        }
        print("📍 위치 업데이트 수신: \(locations.count)개")
        
        guard let location = locations.first else {
            print("📍 유효한 위치 정보 없음")
            return
        }
        
        print("📍 위치: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // 실시간 위치 업데이트 스트림용
        if let continuation = locationUpdatesContinuation {
            continuation.yield(location)
        }
        
        // 단일 위치 요청용
        if let continuation = locationContinuation {
            self.locationContinuation = nil
            
            Task {
                let address = await self.convertToAddress(from: location)
                continuation.resume(returning: (
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    address: address
                ))
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❗️ 위치 업데이트 실패: \(error.localizedDescription)")
        
        if let continuation = locationContinuation {
            self.locationContinuation = nil
            continuation.resume(throwing: RLError.locationUnavailable)
        }
        
        if let continuation = locationUpdatesContinuation {
            continuation.finish()
            self.locationUpdatesContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 위치 권한 상태 변경: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 위치 권한 승인됨")
            
            // 단일 위치 요청이 있는 경우
            if locationContinuation != nil {
                manager.requestLocation()
            }
            
            // 연속 위치 업데이트가 있는 경우
            if locationUpdatesContinuation != nil {
                manager.startUpdatingLocation()
            }
            
        case .denied, .restricted:
            print("❌ 위치 권한 거부됨")
            
            if let continuation = locationContinuation {
                self.locationContinuation = nil
                continuation.resume(throwing: RLError.locationPermissionDenied)
            }
            
            if let continuation = locationUpdatesContinuation {
                continuation.finish()
                self.locationUpdatesContinuation = nil
            }
            
        case .notDetermined:
            print("❓ 위치 권한 미결정")
            
        @unknown default:
            print("❓ 알 수 없는 권한 상태")
        }
    }
} 
