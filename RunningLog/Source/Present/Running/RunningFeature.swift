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
        var errorMessage: String? = nil
        var isTimerActive = false
        var isLocationTrackingActive = false
        var isHeartRateTracking = false
        var pathLocations: [CLLocation] = []
        var lastWidgetAction: String? = nil // 위젯 액션 추적
        var lastWidgetActionTime: TimeInterval = 0 // 위젯 액션 타임스탬프
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
        case syncLocations([CLLocation])
        case updateHeartRate(Int)
        case runningActionResponse(Result<Void, Error>)
        case locationResponse(Result<String, Error>)
        case startLocationTracking
        case stopLocationTracking
        case startHeartRateTracking
        case stopHeartRateTracking
        case saveRunningRecord(RunningRecord)
        case runningRecordSaved(Result<Void, Error>)
        case checkWidgetAction // 위젯 액션 체크
        case delegate(Delegate)
        
        enum Delegate {
            case runningDidEnd
        }
    }
    
    @Dependency(\.runningClient) var runningClient
    @Dependency(\.locationClient) var locationClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.kalmanFilterManager) var kalmanFilterManager
    
    private enum CancelID { 
        case timer
        case locationTracking
        case heartRateTracking
        case widgetActionChecker // 위젯 액션 체크 타이머
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                print("[RunningFeature] locationClient 인스턴스 주소: \(Unmanaged.passUnretained(locationClient as AnyObject).toOpaque())")
                return .concatenate(
                        .run { send in

                            
                            // 현재 세션 상태와 위치 정보 동기화
                            if let currentSession = await runningClient.getSession() {
                                await send(.sessionResponse(.success(currentSession)))
                                
                                let savedLocations = await runningClient.getLocations()
                                await send(.syncLocations(savedLocations))
                                
                                // 세션이 활성 상태(러닝 중)라면 타이머 재시작
                                if currentSession.isActive && !currentSession.isPaused {
                                    await send(.timerTick)
                                }
                                
                            } else {
                                await send(.sessionResponse(.success(nil)))
                                await send(.stopHeartRateTracking)
                            }
                            
                            await send(.startLocationTracking) // ✅ 추가됨

                        },
                    // 위젯 액션 체크 타이머 시작
                    .run { send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.checkWidgetAction)
                        }
                    }
                    .cancellable(id: CancelID.widgetActionChecker)
                )
                
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
                state.session.elapsedTime = 0 // 시간 초기화
                state.isTimerActive = true
                state.isHeartRateTracking = true
                
                return .concatenate(
                    // 먼저 기존 타이머들을 모두 취소 (중첩 방지)
                    .cancel(id: CancelID.timer),
                    .cancel(id: CancelID.locationTracking),
                    .cancel(id: CancelID.heartRateTracking),
                    // 위젯 상태 즉시 업데이트
                    .run { send in
                        let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
                        sharedDefaults?.set(true, forKey: "isRunning")
                        sharedDefaults?.set("00:00:00", forKey: "time")
                        sharedDefaults?.set("0.00", forKey: "distance")
                        sharedDefaults?.set("0", forKey: "calories")
                        sharedDefaults?.set("--'--\"", forKey: "pace")
                        
                        print("[RunningFeature] 러닝 시작 - 위젯 상태 즉시 업데이트")
                        WidgetCenter.shared.reloadTimelines(ofKind: "RunningWidget")
                    },
                    .run { send in
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
                )
                
            case .pauseRunning:
                state.session.isPaused = true
                state.isTimerActive = false
                
                return .concatenate(
                    // 위젯 상태 즉시 업데이트
                    .run { send in
                        let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
                        sharedDefaults?.set(false, forKey: "isRunning")
                        
                        print("[RunningFeature] 러닝 일시정지 - 위젯 상태 즉시 업데이트")
                        WidgetCenter.shared.reloadTimelines(ofKind: "RunningWidget")
                    },
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
                
                return .concatenate(
                    // 위젯 상태 즉시 업데이트
                    .run { send in
                        let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
                        sharedDefaults?.set(true, forKey: "isRunning")
                        
                        print("[RunningFeature] 러닝 재개 - 위젯 상태 즉시 업데이트")
                        WidgetCenter.shared.reloadTimelines(ofKind: "RunningWidget")
                    },
                    .run { send in
                        await send(.runningActionResponse(
                            Result { try await runningClient.resumeRunning() }
                        ))
                        
                        // Resume timer
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.timerTick)
                        }
                    }
                    .cancellable(id: CancelID.timer)
                )
                
            case .stopRunning:
                state.isLoading = true
                state.session.isPaused = true
                state.session.isActive = false
                let record = RunningRecord(
                    id: state.runID ?? UUID(),
                    startTime: state.session.startTime ?? Date(),
                    endTime: Date(),
                    distance: state.session.distance,
                    calories: state.session.calories,
                    elapsedTime: state.session.elapsedTime,
                    averagePace: state.session.averagePace,
                    path: state.pathLocations
                )
                return .concatenate(
                    // 먼저 모든 타이머를 취소
                    .cancel(id: CancelID.timer),
                    .cancel(id: CancelID.locationTracking),
                    .cancel(id: CancelID.heartRateTracking),
                    // 위젯 상태 즉시 업데이트
                    .run { send in
                        let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
                        sharedDefaults?.set(false, forKey: "isRunning")
                        
                        print("[RunningFeature] 러닝 정지 - 위젯 상태 즉시 업데이트")
                        WidgetCenter.shared.reloadTimelines(ofKind: "RunningWidget")
                    },
                    .run { [record] send in
                        // 모든 추적을 중지
                        await send(.stopHeartRateTracking)
                        await send(.stopLocationTracking)
                        
                        // RunningClient의 세션을 완전히 종료
                        await send(.runningActionResponse(
                            Result { try await runningClient.stopRunning() }
                        ))
                        
                        // 그 후 기록 저장
                        do {
                            let repository = CoreDataRunningRecordRepository(context: PersistenceController.shared.container.viewContext)
                            try repository.save(record: record)
                            await send(.runningRecordSaved(.success(())))
                        } catch {
                            await send(.runningRecordSaved(.failure(error)))
                        }
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
                    
                    // RunningClient와 시간 동기화
                    let currentTime = state.session.elapsedTime
                    
                    // 3초마다 위젯 데이터 업데이트 (더 자주 업데이트)
                    if Int(state.session.elapsedTime) % 3 == 0 {
                        let formattedTime = state.session.formattedTime
                        let formattedPace = state.session.formattedPace
                        return .run { send in
                            // RunningClient와 시간 동기화
                            try? await runningClient.updateElapsedTime(currentTime)
                            
                            // 위젯 데이터 즉시 업데이트
                            let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
                            sharedDefaults?.set(formattedTime, forKey: "time")
                            sharedDefaults?.set(formattedPace, forKey: "pace")
                            sharedDefaults?.set(true, forKey: "isRunning") // 러닝 중 상태 확실히 설정
                            
                            print("[RunningFeature] 위젯 데이터 업데이트: 시간=\(formattedTime), 페이스=\(formattedPace)")
                            
                            WidgetCenter.shared.reloadTimelines(ofKind: "RunningWidget")
                        }
                    } else {
                        // 3초가 아닐 때도 RunningClient와 시간 동기화
                        return .run { send in
                            try? await runningClient.updateElapsedTime(currentTime)
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
                if state.pathLocations.isEmpty {
                    state.pathLocations.append(location)
                    return .none
                } else {
                    
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
                }
            case .syncLocations(let locations):
                // 저장된 위치 정보를 거리 계산 없이 동기화
                state.pathLocations = locations
                print("[RunningFeature] 위치 정보 동기화 완료: \(locations.count)개 위치")
                return .none
                
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
                    // 시간을 제외한 세션 정보만 선별적으로 동기화
                    let currentElapsedTime = state.session.elapsedTime // TCA에서 관리하는 시간 보존
                    let oldHeartRate = state.session.heartRate
                    
                    // 선별적 업데이트 (elapsedTime과 id는 제외)
                    // id는 let 상수이므로 변경 불가
                    state.session.startTime = session.startTime
                    state.session.endTime = session.endTime
                    state.session.distance = session.distance
                    state.session.currentPace = session.currentPace
                    state.session.averagePace = session.averagePace
                    state.session.heartRate = session.heartRate
                    state.session.calories = session.calories
                    state.session.isActive = session.isActive
                    state.session.isPaused = session.isPaused
                    // elapsedTime은 TCA에서 관리하므로 덮어쓰지 않음
                    state.session.elapsedTime = currentElapsedTime
                    
                    // 타이머 상태 동기화
                    state.isTimerActive = session.isActive && !session.isPaused
                    state.isLocationTrackingActive = session.isActive
                    state.isHeartRateTracking = session.isActive
                    
                    // 심박수가 변경되었을 때 로그 출력
                    if oldHeartRate != session.heartRate && session.heartRate > 0 {
                        print("💓 세션에서 심박수 업데이트: \(session.heartRate) bpm")
                    }
                    
                    // 세션이 비활성 상태라면 모든 타이머 취소
                    if !session.isActive {
                        return .concatenate(
                            .cancel(id: CancelID.timer),
                            .cancel(id: CancelID.locationTracking),
                            .cancel(id: CancelID.heartRateTracking)
                        )
                    }
                } else {
                    // 세션이 없다면 초기 상태로 설정하고 모든 타이머 취소
                    state.session = RunningSession()
                    state.isTimerActive = false
                    state.isLocationTrackingActive = false
                    state.isHeartRateTracking = false
                    
                    return .concatenate(
                        .cancel(id: CancelID.timer),
                        .cancel(id: CancelID.locationTracking),
                        .cancel(id: CancelID.heartRateTracking)
                    )
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
                
            case let .saveRunningRecord(record):
                return .run { send in
                    do {
                        let repository = CoreDataRunningRecordRepository(context: PersistenceController.shared.container.viewContext)
                        try repository.save(record: record)
                        await send(.runningRecordSaved(.success(())))
                    } catch {
                        await send(.runningRecordSaved(.failure(error)))
                    }
                }
                
            case .runningRecordSaved(.success):
                state.isLoading = false
                let newState = State() // 상태 초기화
                state = newState
                return .concatenate(
                    // 모든 타이머를 확실히 취소
                    .cancel(id: CancelID.timer),
                    .cancel(id: CancelID.locationTracking),
                    .cancel(id: CancelID.heartRateTracking),
                    .send(.delegate(.runningDidEnd))
                )

            case .runningRecordSaved(.failure(let error)):
                state.isLoading = false
                state.errorMessage = "기록 저장 실패: \(error.localizedDescription)"
                return .none
                
            case .checkWidgetAction:
                // 위젯에서 설정한 액션 확인
                let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
                guard let widgetAction = sharedDefaults?.string(forKey: "widgetAction") else {
                    return .none
                }
                
                // 타임스탬프 기반 중복 처리 방지
                let widgetActionTime = sharedDefaults?.double(forKey: "widgetActionTime") ?? 0
                guard widgetActionTime > state.lastWidgetActionTime else {
                    return .none
                }
                
                print("[RunningFeature] 위젯 액션 감지: \(widgetAction) (타임스탬프: \(widgetActionTime))")
                state.lastWidgetAction = widgetAction
                state.lastWidgetActionTime = widgetActionTime
                
                // 위젯 액션 처리 시작 - 즉시 제거하여 중복 실행 방지
                sharedDefaults?.removeObject(forKey: "widgetAction")
                sharedDefaults?.removeObject(forKey: "widgetActionTime")
                
                switch widgetAction {
                case "start":
                    if !state.session.isActive {
                        print("[RunningFeature] 위젯에서 러닝 시작 요청")
                        return .send(.startRunning)
                    } else if state.session.isPaused {
                        print("[RunningFeature] 위젯에서 러닝 재개 요청")
                        return .send(.resumeRunning)
                    }
                case "pause":
                    if state.session.isActive && !state.session.isPaused {
                        print("[RunningFeature] 위젯에서 러닝 일시정지 요청")
                        return .send(.pauseRunning)
                    }
                default:
                    print("[RunningFeature] 알 수 없는 위젯 액션: \(widgetAction)")
                    break
                }
                
                return .none
                
            case .delegate:
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
