//
//  WeatherView.swift
//  RunningLog
//
//  Created by Den on 5/29/25.
//

import SwiftUI
import ComposableArchitecture
// MARK: - Views
struct WeatherView: View {
    let store: StoreOf<WeatherFeature>
    
    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    
                    if store.isLoading {
                        ProgressView("날씨 정보를 불러오는 중...")
                            .frame(height: 200)
                    } else if let weatherData = store.weatherData {
                        aqiView(weatherData: weatherData)
                        currentWeatherView(weatherData: weatherData)
                        hourlyForecastView(weatherData: weatherData)
                    } else if let errorMessage = store.errorMessage {
                        Text("오류: \(errorMessage)")
                            .foregroundColor(.red)
                            .frame(height: 200)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                store.send(.onAppear)
            }
            .refreshable {
                store.send(.refreshWeather)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("RUN")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                + Text("BUNG")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.gray)
                Text(store.location)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func aqiView(weatherData: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AQI")
                .font(.headline)
                .fontWeight(.medium)
            
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    VStack {
                        Text(getDateString(for: index))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 4) {
                            // PM10
                            Text("PM10")
                                .font(.caption2)
                                .foregroundColor(.white)
                            Text("\(weatherData.pm10 + index * 5)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(getPM10Color(value: weatherData.pm10 + index * 5))
                        .cornerRadius(8)
                        
                        VStack(spacing: 4) {
                            // PM2.5
                            Text("PM2.5")
                                .font(.caption2)
                                .foregroundColor(.white)
                            Text("\(weatherData.pm25 + index * 10)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(getPM25Color(value: weatherData.pm25 + index * 10))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func currentWeatherView(weatherData: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("실시간 기상 정보")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("29일 16:09 기준")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 20) {
                weatherInfoItem(
                    icon: "sun.max.fill",
                    title: weatherData.weatherCondition,
                    value: "\(Int(weatherData.temperature))°C",
                    iconColor: .orange
                )
                
                weatherInfoItem(
                    icon: "drop.fill",
                    title: "",
                    value: "\(weatherData.humidity)%",
                    iconColor: .blue
                )
                
                weatherInfoItem(
                    icon: "wind",
                    title: "",
                    value: "\(weatherData.windSpeed)m/s",
                    iconColor: .gray
                )
            }
            
            HStack(spacing: 10) {
                // PM10
                VStack(alignment: .leading, spacing: 5) {
                    Text("PM10")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("\(weatherData.pm10)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("어제 05:14")
                        Spacer()
                        Text("오늘 19:45")
                    }
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(getPM10Color(value: weatherData.pm10))
                .cornerRadius(12)
                
                // PM2.5
                VStack(alignment: .leading, spacing: 5) {
                    Text("PM2.5")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("\(weatherData.pm25)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("미세먼지 포시 기준 AQI")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(getPM25Color(value: weatherData.pm25))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func hourlyForecastView(weatherData: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("시간별 기상 예보")
                .font(.headline)
                .fontWeight(.medium)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(weatherData.hourlyForecast) { hourly in
                        VStack(spacing: 8) {
                            Text(hourly.time)
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Image(systemName: getWeatherIcon(for: hourly.condition))
                                .font(.title2)
                                .foregroundColor(getWeatherIconColor(for: hourly.condition))
                            
                            Text("\(Int(hourly.temperature))°C")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(hourly.humidity)%")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Text("\(Int(hourly.windSpeed))m/s")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(hourly.time == "18:00" ? Color.green : Color.clear, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func weatherInfoItem(icon: String, title: String, value: String, iconColor: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            if !title.isEmpty {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Helper functions
    private func getDateString(for index: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d(E)"
        formatter.locale = Locale(identifier: "ko_KR")
        
        let date = Calendar.current.date(byAdding: .day, value: index, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func getPM10Color(value: Int) -> Color {
        switch value {
        case 0...30: return .green
        case 31...80: return .yellow
        case 81...150: return .orange
        default: return .red
        }
    }
    
    private func getPM25Color(value: Int) -> Color {
        switch value {
        case 0...15: return .green
        case 16...35: return .yellow
        case 36...75: return .orange
        default: return .red
        }
    }
    
    private func getWeatherIcon(for condition: String) -> String {
        switch condition {
        case "sunny": return "sun.max.fill"
        case "clear": return "sun.max"
        case "rainy": return "umbrella.fill"
        case "cloudy": return "cloud.fill"
        default: return "sun.max.fill"
        }
    }
    
    private func getWeatherIconColor(for condition: String) -> Color {
        switch condition {
        case "sunny", "clear": return .orange
        case "rainy": return .blue
        case "cloudy": return .gray
        default: return .orange
        }
    }
}
