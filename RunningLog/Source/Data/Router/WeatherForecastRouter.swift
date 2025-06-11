//
//  WeatherForecastRouter.swift
//  RunningLog
//
//  Created by Den on 6/1/25.
//

import Foundation

struct WeatherForecastRouter: TargetType {
    typealias Response = WeatherForecastResponse

    let lat: Double
    let lon: Double
    let apiKey: String

    var scheme: String { "https" }
    var host: String { "api.openweathermap.org" }
    var path: String { "/data/2.5/forecast" }
    var httpMethod: HTTPMethod { .get }
    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "lat", value: "\(lat)"),
            URLQueryItem(name: "lon", value: "\(lon)"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "kr")
        ]
    }
    var header: [String : String] { [:] }
    var parameters: String? { nil }
    var port: Int? { nil }
    var body: Data? { nil }
}

// OpenWeatherMap 3시간 단위 예보 응답 모델
struct WeatherForecastResponse: Codable {
    struct ForecastItem: Codable {
        let dt: Int
        let main: Main
        let weather: [Weather]
        let wind: Wind

        struct Main: Codable {
            let temp: Double
            let humidity: Int
        }
        struct Weather: Codable {
            let main: String
            let description: String
            let icon: String
            
            private enum CodingKeys: String, CodingKey {
                case main, description, icon
            }
        }
        struct Wind: Codable {
            let speed: Double
        }
    }
    let list: [ForecastItem]
} 
