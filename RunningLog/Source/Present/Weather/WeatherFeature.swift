//
//  WeatherFeature.swift
//  RunningLog
//
//  Created by Den on 5/23/25.
//

import Foundation
import ComposableArchitecture
import CoreLocation

@Reducer
struct WeatherFeature {
    @ObservableState
    struct State: Equatable {
        var weatherData: WeatherData?
        var isLoading = false
        var errorMessage: String?
        var location: String = "대한민국"
        var latitude: Double? = nil
        var longitude: Double? = nil
        var hasLoadedInitialData = false  // 초기 데이터 로드 완료 여부
        var recordList: RunningRecordListFeature.State = .init()
    }
    
    enum Action {
        case onAppear
        case loadInitialData
        case refreshWeather
        case weatherResponse(Result<WeatherData, Error>)
        case updateLocation(latitude: Double, longitude: Double, address: String)
        case locationError(String)
        case recordList(RunningRecordListFeature.Action)
    }
    
    @Dependency(\.weatherClient) var weatherClient
    @Dependency(\.locationClient) var locationClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 이미 초기 데이터를 로드했으면 새로 가져오지 않음
                if state.hasLoadedInitialData {
                    return .none
                } else {
                    // 첫 실행이면 초기 로딩 시작
                    return .send(.loadInitialData)
                }
                
            case .loadInitialData, .refreshWeather:
                print("[WeatherFeature] locationClient 인스턴스 주소: \(Unmanaged.passUnretained(locationClient as AnyObject).toOpaque())")
                state.isLoading = true
                state.errorMessage = nil
                // 위치 정보가 있으면 fetchWeather, 없으면 위치 요청
                if let lat = state.latitude, let lon = state.longitude {
                    return .run { send in
                        await send(.weatherResponse(
                            Result { try await weatherClient.fetchWeather(lat, lon) }
                        ))
                    }
                } else {
                    // 위치 정보가 없으면 LocationClient로 위치 요청 Effect 실행
                    return .run { send in
                        do {
                            let (lat, lon, address) = try await locationClient.requestLocation()
                            await send(.updateLocation(latitude: lat, longitude: lon, address: address))
                        } catch {
                            await send(.locationError("위치 정보를 가져올 수 없습니다."))
                        }
                    }
                }
            case let .updateLocation(latitude, longitude, address):
                state.latitude = latitude
                state.longitude = longitude
                state.location = address
                // 위치가 갱신되면 바로 날씨 요청
                return .run { send in
                    await send(.weatherResponse(
                        Result { try await weatherClient.fetchWeather(latitude, longitude) }
                    ))
                }
            case let .weatherResponse(.success(weatherData)):
                state.isLoading = false
                state.weatherData = weatherData
                state.errorMessage = nil
                state.hasLoadedInitialData = true  // 초기 데이터 로드 완료 표시
                return .none
            case let .weatherResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            case let .locationError(errorMsg):
                state.isLoading = false
                state.errorMessage = errorMsg
                return .none
            case let .recordList(action):
                return .none
            }
        }
        Scope(state: \.recordList, action: \.recordList) {
            RunningRecordListFeature()
        }
    }
}

extension DependencyValues {
    var weatherClient: WeatherClient {
        get { self[WeatherClientKey.self] }
        set { self[WeatherClientKey.self] = newValue }
    }
}

private enum WeatherClientKey: DependencyKey {
    static let liveValue = WeatherClient.live
    static let testValue = WeatherClient.mock
}
