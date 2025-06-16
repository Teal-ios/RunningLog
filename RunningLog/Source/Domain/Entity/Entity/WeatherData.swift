//
//  WeatherData.swift
//  RunningLog
//
//  Created by Den on 6/16/25.
//

import Foundation

struct WeatherData: Codable, Equatable {
    let temperature: Double
    let humidity: Int
    let windSpeed: Double
    let weatherCondition: String
    let pm10: Int
    let pm25: Int
    let hourlyForecast: [HourlyWeather]
    let location: String
    
    init(temperature: Double, humidity: Int, windSpeed: Double, weatherCondition: String, pm10: Int, pm25: Int, hourlyForecast: [HourlyWeather], location: String) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.weatherCondition = weatherCondition
        self.pm10 = pm10
        self.pm25 = pm25
        self.hourlyForecast = hourlyForecast
        self.location = location
    }
}
