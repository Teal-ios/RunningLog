//
//  RunningFeature.swift
//  RunningLog
//
//  Created by Den on 5/26/25.
//

import Foundation
import ComposableArchitecture
import CoreLocation
import WidgetKit

@Reducer
struct RunningFeature {
    @ObservableState
    struct State: Equatable {
        var session: RunningSession = RunningSession()
        var runID: UUID?
        var isLoading = false
        var errorMessage: String?
        var isTimerActive = false
        var isLocationTrackingActive = false
        var isHeartRateTracking = false
        var pathLocations: [CLLocation] = []
    }
    
    enum Action {
        case onAppear
        case startRunning
        case pauseRunning
        case resumeRunning
        case stopRunning
        case timerTick
        case heartRateTick
        case sessionResponse(Result<RunningSession?, Error>)
        case updateLocation(CLLocation)
        case updateHeartRate(Int)
        case runningActionResponse(Result<Void, Error>)
        case locationResponse(Result<String, Error>)
        case startLocationTracking
        case stopLocationTracking
        case startHeartRateTracking
        case stopHeartRateTracking
    }
    
    @Dependency(\.runningClient) var runningClient
    @Dependency(\.locationClient) var locationClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.kalmanFilterManager) var kalmanFilterManager
    
    private enum CancelID { 
        case timer
        case locationTracking
        case heartRateTracking
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                print("[RunningFeature] locationClient 인스턴스 주소: \(Unmanaged.passUnretained(locationClient as AnyObject).toOpaque())")
                return .run { send in
                    // 현재 세션 상태만 동기화 (타이머는 시작하지 않음)
                    if let currentSession = await runningClient.getSession() {
                        await send(.sessionResponse(.success(currentSession)))
                        // 세션이 활성 상태(러닝 중)라면 위치 추적 및 타이머 재시작
                        if currentSession.isActive && !currentSession.isPaused {
                            await send(.startLocationTracking)
                            await send(.timerTick)
                        }
                    } else {
                        await send(.sessionResponse(.success(nil)))
                    }
                }
                
            case .startRunning:
                // 이미 활성 상태인 세션은 재시작하지 않음
                guard !state.session.isActive else { return .none }
                
                // 러닝 시작 시 경로 배열도 초기화
                state.pathLocations = []
                state.runID = UUID()
                
                state.isLoading = true
                state.session.isActive = true
                state.session.isPaused = false
                state.session.startTime = Date()
                state.isTimerActive = true
                state.isHeartRateTracking = true
                
                return .run { send in
                    // Start running session
                    await send(.runningActionResponse(
                        Result { try await runningClient.startRunning() }
                    ))
                    
                    // Start location tracking
                    await send(.startLocationTracking)
                    
                    // Start heart rate tracking
                    await send(.startHeartRateTracking)
                    
                    // Start timer
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .pauseRunning:
                state.session.isPaused = true
                state.isTimerActive = false
                
                return .concatenate(
                    .run { send in
                        await send(.runningActionResponse(
                            Result { try await runningClient.pauseRunning() }
                        ))
                    },
                    .cancel(id: CancelID.timer)
                )
                
            case .resumeRunning:
                state.session.isPaused = false
                state.isTimerActive = true
                
                return .run { send in
                    await send(.runningActionResponse(
                        Result { try await runningClient.resumeRunning() }
                    ))
                    
                    // Resume timer
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .stopRunning:
                state.session.isActive = false
                state.session.isPaused = false
                state.session.endTime = Date()
                state.isTimerActive = false
                state.isHeartRateTracking = false
                let session = state.session
                let path = state.pathLocations
                state.runID = nil
                
                // 값 유효성 체크: 거리, 시간, 경로 모두 있어야 저장
                guard session.distance > 0, session.elapsedTime > 0, !path.isEmpty else {
                    print("[러닝기록] 거리/시간/경로 값이 없어 저장하지 않음")
                    state.pathLocations = []
                    // 러닝 종료 후 상태 완전 초기화
                    state.session = RunningSession()
                    return .concatenate(
                        .cancel(id: CancelID.timer),
                        .cancel(id: CancelID.locationTracking),
                        .cancel(id: CancelID.heartRateTracking),
                        .run { send in
                            do {
                                try await runningClient.stopRunning()
                            } catch {
                                print("[러닝 종료] stopRunning 에러: \(error)")
                            }
                            await send(.runningActionResponse(.success(())))
                        }
                    )
                }
                let record = RunningRecord(
                    id: UUID(),
                    startTime: session.startTime ?? Date(),
                    endTime: Date(),
                    distance: session.distance,
                    calories: session.calories,
                    elapsedTime: session.elapsedTime,
                    averagePace: session.averagePace,
                    path: path
                )
                state.pathLocations = []
                if PersistenceController.shared.isStoreLoaded {
                    let repository = CoreDataRunningRecordRepository(context: PersistenceController.shared.container.viewContext)
                    do {
                        try repository.save(record: record)
                        print("러닝 기록 저장 성공: \(record)")
                    } catch {
                        print("러닝 기록 저장 실패: \(error)")
                    }
                } else {
                    print("[러닝기록] CoreData store가 아직 준비되지 않음")
                }
                // 러닝 종료 후 상태 완전 초기화
                state.session = RunningSession()
                return .concatenate(
                    .cancel(id: CancelID.timer),
                    .cancel(id: CancelID.locationTracking),
                    .cancel(id: CancelID.heartRateTracking),
                    .run { send in
                        do {
                            try await runningClient.stopRunning()
                        } catch {
                            print("[러닝 종료] stopRunning 에러: \(error)")
                        }
                        await send(.runningActionResponse(.success(())))
                    }
                )
                
            case .startLocationTracking:
                state.isLocationTrackingActive = true
                return .run { send in
                    do {
                        for try await location in try await locationClient.requestLocationUpdates() {
                            await send(.updateLocation(location))
                        }
                    } catch {
                        await send(.locationResponse(.failure(error)))
                    }
                }
                .cancellable(id: CancelID.locationTracking)
                
            case .stopLocationTracking:
                state.isLocationTrackingActive = false
                return .cancel(id: CancelID.locationTracking)
                
            case .startHeartRateTracking:
                state.isHeartRateTracking = true
                return .run { send in
                    // 심박수를 3초마다 업데이트
                    for await _ in clock.timer(interval: .seconds(3)) {
                        await send(.heartRateTick)
                    }
                }
                .cancellable(id: CancelID.heartRateTracking)
                
            case .stopHeartRateTracking:
                state.isHeartRateTracking = false
                return .cancel(id: CancelID.heartRateTracking)
                
            case .timerTick:
                if state.session.isActive && !state.session.isPaused {
                    state.session.elapsedTime += 1

                    // 1초마다 실시간 페이스 재계산
                    if state.session.distance > 0 {
                        let distanceInKm = state.session.distance / 1000.0
                        let timeInMinutes = state.session.elapsedTime / 60.0
                        state.session.currentPace = timeInMinutes / distanceInKm
                    }
                    // 10초마다 위젯 데이터 업데이트
                    if Int(state.session.elapsedTime) % 10 == 0 {
                        let formattedTime = state.session.formattedTime
                        return .run { send in
                            // 위젯 데이터 업데이트 요청
                            let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
                            sharedDefaults?.set(formattedTime, forKey: "time")
                            
                            WidgetCenter.shared.reloadTimelines(ofKind: "RunningWidget")
                        }
                    }
                }
                return .none
                
            case .heartRateTick:
                // 세션이 활성 상태일 때만 심박수 업데이트
                guard state.session.isActive && !state.session.isPaused else { return .none }
                return .run { send in
                    // 현재 세션에서 심박수 가져오기 (HealthKit 실제 데이터)
                    if let currentSession = await runningClient.getSession(), currentSession.heartRate != 0 {
                        await send(.updateHeartRate(currentSession.heartRate))
                    }
                }
                
            case .updateLocation(let location):
                // 칼만 필터 및 속도 이상치 제거 적용
                if let filteredLocation = kalmanFilterManager.filter(location: location) {
                    // 러닝이 활성 상태(일시정지 제외)일 때만 경로에 추가
                    if state.session.isActive && !state.session.isPaused {
                        // 거리 누적 개선: 이전 위치와의 거리를 직접 계산하여 누적
                        if let last = state.pathLocations.last {
                            let distance = filteredLocation.distance(from: last)
                            if distance > 1 { // 1m 이상 이동한 경우만 누적
                                state.session.distance += distance
                            }
                        }
                        state.pathLocations.append(filteredLocation)
                    }
                    return .run { send in
                        try? await runningClient.updateLocation(filteredLocation)
                        if let session = await runningClient.getSession() {
                            await send(.sessionResponse(.success(session)))
                        }
                    }
                } else {
                    print("[RunningFeature] 이상치 위치 무시")
                    return .none
                }
                
            case let .updateHeartRate(heartRate):
                // 심박수가 실제로 변경될 때만 업데이트
                guard state.session.heartRate != heartRate else { return .none }
                
                state.session.heartRate = heartRate
                print("💓 심박수 업데이트: \(heartRate) bpm")
                
                return .run { send in
                    await send(.runningActionResponse(
                        Result { try await runningClient.updateHeartRate(heartRate) }
                    ))
                }
                
            case let .sessionResponse(.success(session)):
                state.isLoading = false
                if let session = session {
                    // 심박수만 별도로 처리하여 UI 업데이트 보장
                    let oldHeartRate = state.session.heartRate
                    state.session = session
                    
                    // 타이머 상태 동기화
                    state.isTimerActive = session.isActive && !session.isPaused
                    state.isLocationTrackingActive = session.isActive
                    state.isHeartRateTracking = session.isActive
                    
                    // 심박수가 변경되었을 때 로그 출력
                    if oldHeartRate != session.heartRate && session.heartRate > 0 {
                        print("💓 세션에서 심박수 업데이트: \(session.heartRate) bpm")
                    }
                }
                return .none
                
            case let .sessionResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .runningActionResponse(.success):
                state.isLoading = false
                state.errorMessage = nil
                return .none
                
            case let .runningActionResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .locationResponse(.success):
                return .none
                
            case let .locationResponse(.failure(error)):
                state.errorMessage = "위치 추적 오류: \(error.localizedDescription)"
                return .none
            }
        }
    }
}

extension DependencyValues {
    var runningClient: RunningClient {
        get { self[RunningClientKey.self] }
        set { self[RunningClientKey.self] = newValue }
    }
    
    var locationClient: LocationClient {
        get { self[LocationClientKey.self] }
        set { self[LocationClientKey.self] = newValue }
    }
}

private enum RunningClientKey: DependencyKey {
    static let liveValue: RunningClient = RunningClientImpl()
    static let testValue: RunningClient = MockRunningClient()
}

private enum LocationClientKey: DependencyKey {
    static let liveValue: LocationClient = LocationClientImpl()
    static let testValue: LocationClient = MockLocationClient()
}
