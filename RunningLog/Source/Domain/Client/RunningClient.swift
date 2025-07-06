//
//  RunningClient.swift
//  RunningLog
//
//  Created by Den on 5/26/25.
//

import Foundation
import CoreLocation
import ComposableArchitecture
import WidgetKit
import UIKit
import HealthKit


// MARK: - Running Client Protocol
protocol RunningClient {
    func startRunning() async throws -> Void
    func pauseRunning() async throws -> Void
    func resumeRunning() async throws -> Void
    func stopRunning() async throws -> Void
    func updateLocation(_ location: CLLocation) async throws -> Void
    func updateHeartRate(_ heartRate: Int) async throws -> Void
    func updateElapsedTime(_ elapsedTime: TimeInterval) async throws -> Void
    func getSession() async -> RunningSession?
    func getLocations() async -> [CLLocation]
    func getUserProfile() async -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws -> Void
    func enableBackgroundTracking() async throws -> Void
    func disableBackgroundTracking() async throws -> Void
}

// MARK: - Running Client Implementation
extension RunningClient {
    static var live: RunningClient {
        RunningClientImpl()
    }
    
    static var mock: RunningClient {
        MockRunningClient()
    }
}

class RunningClientImpl: RunningClient {
    private var session = RunningSession()
    private var userProfile = UserProfile()
    private var locations: [CLLocation] = []
    private var lastLocation: CLLocation?
    private let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?
    private var isUsingRealHeartRate = false
    
    init() {
        setupHealthKit()
    }
    
    private func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let readTypes: Set<HKObjectType> = [heartRateType]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            if success {
                print("HealthKit 권한 승인됨")
                self?.startHeartRateMonitoring()
            } else {
                print("HealthKit 권한 거부됨: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func startHeartRateMonitoring() {
        func executeHeartRateQuery(startDate: Date) {
            guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
                print("HealthKit 심박수 타입을 가져올 수 없음")
                DispatchQueue.main.async {
                    self.isUsingRealHeartRate = false
                    self.session.heartRate = 0
                }
                return
            }
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: nil,
                options: .strictEndDate
            )
            let query = HKAnchoredObjectQuery(
                type: heartRateType,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit
            ) { [weak self] query, samples, deletedObjects, anchor, error in
                guard let self = self else { return }
                if let error = error {
                    print("HealthKit 심박수 쿼리 에러: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isUsingRealHeartRate = false
                        self.session.heartRate = 0
                    }
                    return
                }
                // 초기 샘플 처리
                if let samples = samples as? [HKQuantitySample], !samples.isEmpty {
                    if let latestSample = samples.last {
                        let heartRate = Int(latestSample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                        DispatchQueue.main.async {
                            self.isUsingRealHeartRate = true
                            self.session.heartRate = heartRate
                            print("💓 HealthKit 초기 심박수: \(heartRate) bpm")
                        }
                    }
                } else {
                    // 만약 최초 쿼리라면, 10분 전으로 한 번 더 재시도
                    if startDate >= Date().addingTimeInterval(-5) {
                        print("HealthKit 초기 심박수 데이터 없음, 10분 전까지 재시도")
                        executeHeartRateQuery(startDate: Date().addingTimeInterval(-60*10))
                        return
                    }
                    print("HealthKit 초기 심박수 데이터 없음 (10분 전까지도 없음)")
                    DispatchQueue.main.async {
                        self.isUsingRealHeartRate = false
                        self.session.heartRate = 0
                    }
                }
            }
            // updateHandler를 직접 정의해서 할당
            query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
                guard let self = self else { return }
                if let error = error {
                    print("HealthKit 심박수 업데이트 에러: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isUsingRealHeartRate = false
                        self.session.heartRate = 0
                    }
                    return
                }
                guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                    DispatchQueue.main.async {
                        self.isUsingRealHeartRate = false
                        self.session.heartRate = 0
                    }
                    return
                }
                if let latestSample = samples.last {
                    let heartRate = Int(latestSample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                    let sampleDate = latestSample.endDate
                    if Date().timeIntervalSince(sampleDate) <= 300 {
                        DispatchQueue.main.async {
                            self.isUsingRealHeartRate = true
                            self.session.heartRate = heartRate
                            print("💓 HealthKit 실시간 심박수: \(heartRate) bpm (측정시간: \(sampleDate))")
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.isUsingRealHeartRate = false
                            self.session.heartRate = 0
                        }
                    }
                }
            }
            self.heartRateQuery = query
            self.healthStore.execute(query)
            print("💓 HealthKit 실시간 심박수 모니터링 시작 (", startDate, ")")
        }
        executeHeartRateQuery(startDate: Date())
    }
    
    private func updateWidgetData() {
        let currentIsRunning = session.isActive && !session.isPaused
        sharedDefaults?.set(currentIsRunning, forKey: "isRunning")
        sharedDefaults?.set(session.formattedDistance, forKey: "distance")
        sharedDefaults?.set(session.formattedTime, forKey: "time")
        sharedDefaults?.set(session.formattedCalories, forKey: "calories")
        
        // 위젯 상태 변경 로그
        print("[RunningClient] 위젯 상태 업데이트: 러닝=\(currentIsRunning), 시간=\(session.formattedTime), 거리=\(session.formattedDistance)km, 칼로리=\(session.formattedCalories)kcal")
        
        // 위젯 타임라인 즉시 업데이트 요청
        WidgetCenter.shared.reloadTimelines(ofKind: "RunningWidget")
        
        // 추가적으로 0.5초 후에도 한 번 더 업데이트 (지연 반영 방지)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WidgetCenter.shared.reloadTimelines(ofKind: "RunningWidget")
        }
    }
    
    func startRunning() async throws -> Void {
        session.isActive = true
        session.isPaused = false
        session.startTime = Date()
        session.elapsedTime = 0
        session.distance = 0
        session.calories = 0
        session.heartRate = 0
        locations.removeAll()
        lastLocation = nil
        isUsingRealHeartRate = false
        print("러닝 시작: \(Date())")
        
        // 즉시 위젯 업데이트
        updateWidgetData()
        
        startHeartRateMonitoring()
    }
    
    func pauseRunning() async throws -> Void {
        session.isPaused = true
        print("러닝 일시정지")
        
        // 즉시 위젯 업데이트
        updateWidgetData()
    }
    
    func resumeRunning() async throws -> Void {
        session.isPaused = false
        print("러닝 재개")
        
        // 즉시 위젯 업데이트
        updateWidgetData()
    }
    
    func stopRunning() async throws -> Void {
        session.isActive = false
        session.isPaused = false
        session.endTime = Date()
        print("러닝 종료: 거리 \(session.formattedDistance)km, 시간 \(session.formattedTime)")
        if session.distance > 0 && session.elapsedTime > 0 {
            let distanceInKm = session.distance / 1000.0
            let timeInMinutes = session.elapsedTime / 60.0
            session.averagePace = timeInMinutes / distanceInKm
        }
        session.calculateCalories(userProfile: userProfile)
        
        // 즉시 위젯 업데이트
        updateWidgetData()
        
        stopHeartRateMonitoring()
    }
    
    func updateLocation(_ location: CLLocation) async throws -> Void {
        guard session.isActive && !session.isPaused else { return }
        
        print("🏃‍♂️ [러닝 중] 위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        locations.append(location)
        
        // Calculate distance
        if let lastLoc = lastLocation {
            let distance = location.distance(from: lastLoc)
            
            // 너무 작은 거리는 무시 (GPS 오차 고려)
            if distance > 2.0 {
                session.distance += distance
                print("거리 증가: +\(String(format: "%.2f", distance))m, 총 거리: \(session.formattedDistance)km")
                
                // Calculate current pace (simplified)
                if session.elapsedTime > 0 {
                    let distanceInKm = session.distance / 1000.0
                    let timeInMinutes = session.elapsedTime / 60.0
                    session.currentPace = timeInMinutes / distanceInKm
                }
                
                // 실시간 칼로리 계산
                session.calculateCalories(userProfile: userProfile)
                print("칼로리 업데이트: \(session.formattedCalories)kcal")
                
                // 위젯 데이터 업데이트 (거리가 변경될 때마다)
                updateWidgetData()
            }
        }
        
        lastLocation = location
    }
    
    func updateHeartRate(_ heartRate: Int) async throws -> Void {
        session.heartRate = heartRate
        print("심박수 수동 업데이트: \(heartRate) bpm")
    }
    
    func updateElapsedTime(_ elapsedTime: TimeInterval) async throws -> Void {
        session.elapsedTime = elapsedTime
        print("러닝 경과시간 업데이트: \(elapsedTime) seconds")
        updateWidgetData()
    }
    
    func getSession() async -> RunningSession? {
        // TCA에서 시간을 관리하므로 실시간 계산하지 않음
        return session
    }
    
    func getLocations() async -> [CLLocation] {
        return locations
    }
    
    func getUserProfile() async -> UserProfile {
        return userProfile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> Void {
        userProfile = profile
        // 사용자 프로필이 변경되면 칼로리를 다시 계산
        if session.isActive {
            session.calculateCalories(userProfile: userProfile)
        }
    }
    
    func enableBackgroundTracking() async throws -> Void {
        print("백그라운드 위치 추적 활성화 (LocationClient에 위임)")
    }
    
    func disableBackgroundTracking() async throws -> Void {
        print("백그라운드 위치 추적 비활성화 (LocationClient에 위임)")
    }
    
    private func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        isUsingRealHeartRate = false
    }
}

class MockRunningClient: RunningClient {
    private var session = RunningSession()
    private var heartRateTimer: Timer?
    
    func startRunning() async throws -> Void {
        session.isActive = true
        session.isPaused = false
        session.startTime = Date()
        session.elapsedTime = 0
        session.distance = 0
        session.calories = 0
        session.heartRate = 0
        
        print("Mock 러닝 시작")
        startMockHeartRateSimulation()
    }
    
    func pauseRunning() async throws -> Void {
        session.isPaused = true
        print("Mock 러닝 일시정지")
    }
    
    func resumeRunning() async throws -> Void {
        session.isPaused = false
        print("Mock 러닝 재개")
    }
    
    func stopRunning() async throws -> Void {
        session.isActive = false
        session.isPaused = false
        session.endTime = Date()
        heartRateTimer?.invalidate()
        heartRateTimer = nil
        print("Mock 러닝 종료")
    }
    
    func updateLocation(_ location: CLLocation) async throws -> Void {
        guard session.isActive && !session.isPaused else { return }
        
        // Mock 거리 증가 (50-100m 랜덤)
        let mockDistance = Double.random(in: 50...100)
        session.distance += mockDistance
        
        // Mock 칼로리 계산
        session.calories = session.distance / 1000.0 * 60.0 // 1km당 60kcal
        
        print("Mock 위치 업데이트: 거리 +\(String(format: "%.1f", mockDistance))m")
    }
    
    func updateHeartRate(_ heartRate: Int) async throws -> Void {
        session.heartRate = heartRate
        print("Mock 심박수 수동 업데이트: \(heartRate) bpm")
    }
    
    func updateElapsedTime(_ elapsedTime: TimeInterval) async throws -> Void {
        session.elapsedTime = elapsedTime
        print("Mock 러닝 경과시간 업데이트: \(elapsedTime) seconds")
    }
    
    func getSession() async -> RunningSession? {
        // TCA에서 시간을 관리하므로 실시간 계산하지 않음
        return session
    }
    
    func getLocations() async -> [CLLocation] {
        return []
    }
    
    func getUserProfile() async -> UserProfile {
        return UserProfile()
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> Void {
        print("Mock 사용자 프로필 업데이트")
    }
    
    func enableBackgroundTracking() async throws -> Void {
        print("Mock 백그라운드 추적 활성화")
    }
    
    func disableBackgroundTracking() async throws -> Void {
        print("Mock 백그라운드 추적 비활성화")
    }
    
    private func startMockHeartRateSimulation() {
        heartRateTimer?.invalidate()
        
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [self] timer in
            guard session.isActive else {
                timer.invalidate()
                return
            }
            
            // Mock 심박수 생성
            let baseHeartRate: Int
            let variation: Int
            
            if session.isPaused {
                baseHeartRate = 95
                variation = 5
            } else {
                // 시간에 따른 심박수 변화
                let minutes = session.elapsedTime / 60.0
                switch minutes {
                case 0..<3:
                    baseHeartRate = 125  // 초기
                    variation = 10
                case 3..<10:
                    baseHeartRate = 145  // 안정기
                    variation = 15
                case 10..<20:
                    baseHeartRate = 155  // 지속기
                    variation = 12
                default:
                    baseHeartRate = 160  // 고강도
                    variation = 8
                }
            }
            
            let mockHeartRate = baseHeartRate + Int.random(in: -variation...variation)
            let clampedHeartRate = max(80, min(180, mockHeartRate))
            
            DispatchQueue.main.async {
                self.session.heartRate = clampedHeartRate
                print("💓 Mock 심박수: \(clampedHeartRate) bpm")
            }
        }
    }
} 
