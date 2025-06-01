import Foundation
import CoreLocation

// MARK: - Models
public struct WeatherData: Codable, Equatable {
    public let temperature: Double
    public let humidity: Int
    public let windSpeed: Double
    public let weatherCondition: String
    public let pm10: Int
    public let pm25: Int
    public let hourlyForecast: [HourlyWeather]
    public let location: String
    
    public init(temperature: Double, humidity: Int, windSpeed: Double, weatherCondition: String, pm10: Int, pm25: Int, hourlyForecast: [HourlyWeather], location: String) {
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

public struct HourlyWeather: Codable, Equatable, Identifiable {
    public let id = UUID()
    public let time: String
    public let temperature: Double
    public let humidity: Int
    public let windSpeed: Double
    public let condition: String
    
    public init(time: String, temperature: Double, humidity: Int, windSpeed: Double, condition: String) {
        self.time = time
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.condition = condition
    }
    
    private enum CodingKeys: String, CodingKey {
        case time, temperature, humidity, windSpeed, condition
    }
}

// MARK: - API Client
public struct WeatherClient {
    public var fetchWeather: @Sendable (_ lat: Double, _ lon: Double) async throws -> WeatherData
    
    public static let live = WeatherClient(
        fetchWeather: { lat, lon in
            let networkService = NetworkService()
            let dataTransferService = DataTransferService(networkService: networkService)
            let router = WeatherRouter(lat: lat, lon: lon, apiKey: APIKey.openweatherKey)
            let response: AirPollutionResponse = try await dataTransferService.request(with: router)
            let pm10 = Int(response.list.first?.components.pm10 ?? 0)
            let pm25 = Int(response.list.first?.components.pm2_5 ?? 0)
            // 임시로 나머지 값은 0 또는 기본값
            return WeatherData(
                temperature: 0,
                humidity: 0,
                windSpeed: 0,
                weatherCondition: "",
                pm10: pm10,
                pm25: pm25,
                hourlyForecast: [],
                location: ""
            )
        }
    )
    
    public static let mock = WeatherClient(
        fetchWeather: { _, _ in
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
