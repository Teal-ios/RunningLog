//
//  HourlyWeather.swift
//  RunningLog
//
//  Created by Den on 6/16/25.
//

import Foundation

struct HourlyWeather: Codable, Equatable, Identifiable {
    let id = UUID()
    let time: String
    let temperature: Double
    let humidity: Int
    let windSpeed: Double
    let condition: String
    let timestamp: Date
    let weatherIcon: String
    
    init(time: String, temperature: Double, humidity: Int, windSpeed: Double, condition: String, timestamp: Date, weatherIcon: String) {
        self.time = time
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.condition = condition
        self.timestamp = timestamp
        self.weatherIcon = weatherIcon
    }
    
    private enum CodingKeys: String, CodingKey {
        case time, temperature, humidity, windSpeed, condition, timestamp, weatherIcon
    }
}
