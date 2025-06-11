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
    public let timestamp: Date
    public let weatherIcon: String
    
    public init(time: String, temperature: Double, humidity: Int, windSpeed: Double, condition: String, timestamp: Date, weatherIcon: String) {
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

// MARK: - API Client
public struct WeatherClient {
    public var fetchWeather: @Sendable (_ lat: Double, _ lon: Double) async throws -> WeatherData
    
    public static let live = WeatherClient(
        fetchWeather: { lat, lon in
            let networkService = NetworkService()
            let dataTransferService = DataTransferService(networkService: networkService)
            // 1. 미세먼지
            let airRouter = WeatherRouter(lat: lat, lon: lon, apiKey: APIKey.openweatherKey)
            let airResponse: AirPollutionResponse = try await dataTransferService.request(with: airRouter)
            let pm10 = Int(airResponse.list.first?.components.pm10 ?? 0)
            let pm25 = Int(airResponse.list.first?.components.pm2_5 ?? 0)
            // 2. 실시간 날씨
            let nowRouter = WeatherNowRouter(lat: lat, lon: lon, apiKey: APIKey.openweatherKey)
            let nowResponse: WeatherNowResponse = try await dataTransferService.request(with: nowRouter)
            // 3. 시간별 예보
            let forecastRouter = WeatherForecastRouter(lat: lat, lon: lon, apiKey: APIKey.openweatherKey)
            let forecastResponse: WeatherForecastResponse = try await dataTransferService.request(with: forecastRouter)
            let now = Date()
            let hourlyForecast: [HourlyWeather] = forecastResponse.list.compactMap { item -> HourlyWeather? in
                let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
                guard date > now else { return nil }
                let timeFormatter = DateFormatter()
                timeFormatter.locale = Locale(identifier: "ko_KR")
                timeFormatter.dateFormat = "HH:mm"
                let icon = item.weather.first?.icon ?? "01d"
                return HourlyWeather(
                    time: timeFormatter.string(from: date),
                    temperature: item.main.temp,
                    humidity: item.main.humidity,
                    windSpeed: item.wind.speed,
                    condition: item.weather.first?.description ?? "",
                    timestamp: date,
                    weatherIcon: icon
                )
            }
            // 4. WeatherData로 통합
            return WeatherData(
                temperature: nowResponse.main.temp,
                humidity: nowResponse.main.humidity,
                windSpeed: nowResponse.wind.speed,
                weatherCondition: nowResponse.weather.first?.description ?? "",
                pm10: pm10,
                pm25: pm25,
                hourlyForecast: hourlyForecast,
                location: nowResponse.name
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
