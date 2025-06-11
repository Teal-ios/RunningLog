//
//  WeatherRouter.swift
//  RunningLog
//
//  Created by Den on 6/1/25.
//

import Foundation
import CoreLocation

struct WeatherRouter: TargetType {
    typealias Response = AirPollutionResponse
    
    let lat: Double
    let lon: Double
    let apiKey: String
    
    var scheme: String { "https" }
    var host: String { "api.openweathermap.org" }
    var path: String { "/data/2.5/air_pollution" }
    var httpMethod: HTTPMethod { .get }
    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "lat", value: "\(lat)"),
            URLQueryItem(name: "lon", value: "\(lon)"),
            URLQueryItem(name: "appid", value: APIKey.openweatherKey)
        ]
    }
    var header: [String : String] { [:] }
    var parameters: String? { nil }
    var port: Int? { nil }
    var body: Data? { nil }
}

// OpenWeatherMap Air Pollution API 응답 모델
struct AirPollutionResponse: Codable {
    let list: [AirPollutionData]
}

struct AirPollutionData: Codable {
    let main: AirPollutionMain
    let components: AirPollutionComponents
    let dt: Int
}

struct AirPollutionMain: Codable {
    let aqi: Int
}

struct AirPollutionComponents: Codable {
    let pm10: Double
    let pm2_5: Double
    // 기타 필요한 값이 있으면 추가
}
