//
//  WeatherFeature.swift
//  RunningLog
//
//  Created by Den on 5/23/25.
//

import Foundation
import ComposableArchitecture

// MARK: - Models
struct WeatherData: Codable, Equatable {
    let temperature: Double
    let humidity: Int
    let windSpeed: Double
    let weatherCondition: String
    let pm10: Int
    let pm25: Int
    let hourlyForecast: [HourlyWeather]
    let location: String
}

struct HourlyWeather: Codable, Equatable, Identifiable {
    let id = UUID()
    let time: String
    let temperature: Double
    let humidity: Int
    let windSpeed: Double
    let condition: String
    
    private enum CodingKeys: String, CodingKey {
        case time, temperature, humidity, windSpeed, condition
    }
}

// MARK: - API Client
struct WeatherClient {
    var fetchWeather: @Sendable (String) async throws -> WeatherData
    
    static let live = WeatherClient(
        fetchWeather: { location in
            // 실제 API 호출 대신 Mock 데이터 반환
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 지연
            
            return WeatherData(
                temperature: 26,
                humidity: 50,
                windSpeed: 5.7,
                weatherCondition: "맑음",
                pm10: 33,
                pm25: 82,
                hourlyForecast: [
                    HourlyWeather(time: "18:00", temperature: 25, humidity: 48, windSpeed: 4, condition: "rainy"),
                    HourlyWeather(time: "21:00", temperature: 23, humidity: 46, windSpeed: 1, condition: "rainy"),
                    HourlyWeather(time: "0:00", temperature: 19, humidity: 51, windSpeed: 1, condition: "clear"),
                    HourlyWeather(time: "3:00", temperature: 17, humidity: 64, windSpeed: 1, condition: "clear"),
                    HourlyWeather(time: "6:00", temperature: 16, humidity: 70, windSpeed: 1, condition: "sunny")
                ],
                location: "구로구 서울"
            )
        }
    )
    
    static let mock = WeatherClient(
        fetchWeather: { _ in
            WeatherData(
                temperature: 26,
                humidity: 50,
                windSpeed: 5.7,
                weatherCondition: "맑음",
                pm10: 33,
                pm25: 82,
                hourlyForecast: [],
                location: "구로구 서울"
            )
        }
    )
}


@Reducer
struct WeatherFeature {
    @ObservableState
    struct State: Equatable {
        var weatherData: WeatherData?
        var isLoading = false
        var errorMessage: String?
        var location = "구로구 서울"
    }
    
    enum Action {
        case onAppear
        case refreshWeather
        case weatherResponse(Result<WeatherData, Error>)
    }
    
    @Dependency(\.weatherClient) var weatherClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear, .refreshWeather:
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { [location = state.location] send in
                    await send(.weatherResponse(
                        Result { try await weatherClient.fetchWeather(location) }
                    ))
                }
                
            case let .weatherResponse(.success(weatherData)):
                state.isLoading = false
                state.weatherData = weatherData
                state.errorMessage = nil
                return .none
                
            case let .weatherResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            }
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
