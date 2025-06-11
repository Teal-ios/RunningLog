//
//  WeatherNowRouter.swift
//  RunningLog
//
//  Created by Den on 6/1/25.
//

import Foundation

struct WeatherNowRouter: TargetType {
    typealias Response = WeatherNowResponse

    let lat: Double
    let lon: Double
    let apiKey: String

    var scheme: String { "https" }
    var host: String { "api.openweathermap.org" }
    var path: String { "/data/2.5/weather" }
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

// OpenWeatherMap 실시간 날씨 응답 모델
struct WeatherNowResponse: Codable {
    struct Weather: Codable {
        let main: String
        let description: String
    }
    struct Main: Codable {
        let temp: Double
        let humidity: Int
    }
    struct Wind: Codable {
        let speed: Double
    }
    let weather: [Weather]
    let main: Main
    let wind: Wind
    let name: String
} 