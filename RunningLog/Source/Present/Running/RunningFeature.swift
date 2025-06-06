//
//  RunningFeature.swift
//  RunningLog
//
//  Created by Den on 5/26/25.
//

import Foundation
import ComposableArchitecture
import CoreLocation

@Reducer
struct RunningFeature {
    @ObservableState
    struct State: Equatable {
        var session: RunningSession = RunningSession()
        var isLoading = false
        var errorMessage: String?
        var isTimerActive = false
    }
    
    enum Action {
        case onAppear
        case startRunning
        case pauseRunning
        case resumeRunning
        case stopRunning
        case timerTick
        case sessionResponse(Result<RunningSession?, Error>)
        case updateLocation(CLLocation)
        case updateHeartRate(Int)
        case runningActionResponse(Result<Void, Error>)
    }
    
    @Dependency(\.runningClient) var runningClient
    @Dependency(\.continuousClock) var clock
    
    private enum CancelID { case timer }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.sessionResponse(
                        Result { await runningClient.getSession() }
                    ))
                }
                
            case .startRunning:
                state.isLoading = true
                state.session.isActive = true
                state.session.isPaused = false
                state.session.startTime = Date()
                state.isTimerActive = true
                
                return .run { send in
                    // Start running session
                    await send(.runningActionResponse(
                        Result { try await runningClient.startRunning() }
                    ))
                    
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
                
                return .concatenate(
                    .run { send in
                        await send(.runningActionResponse(
                            Result { try await runningClient.stopRunning() }
                        ))
                    },
                    .cancel(id: CancelID.timer)
                )
                
            case .timerTick:
                if state.session.isActive && !state.session.isPaused {
                    state.session.elapsedTime += 1
                }
                return .none
                
            case let .updateLocation(location):
                return .run { send in
                    await send(.runningActionResponse(
                        Result { try await runningClient.updateLocation(location) }
                    ))
                }
                
            case let .updateHeartRate(heartRate):
                state.session.heartRate = heartRate
                return .run { send in
                    await send(.runningActionResponse(
                        Result { try await runningClient.updateHeartRate(heartRate) }
                    ))
                }
                
            case let .sessionResponse(.success(session)):
                state.isLoading = false
                if let session = session {
                    state.session = session
                }
                return .none
                
            case let .sessionResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case let .runningActionResponse(.success):
                state.isLoading = false
                state.errorMessage = nil
                return .none
                
            case let .runningActionResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
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
}

private enum RunningClientKey: DependencyKey {
    static let liveValue: RunningClient = RunningClientImpl()
    static let testValue: RunningClient = MockRunningClient()
}
