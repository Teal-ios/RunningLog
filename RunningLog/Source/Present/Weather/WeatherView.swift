//
//  WeatherView.swift
//  RunningLog
//
//  Created by Den on 5/29/25.
//

import SwiftUI
import ComposableArchitecture
import CoreLocation
// MARK: - Views
struct WeatherView: View {
    let store: StoreOf<WeatherFeature>
    
    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    mainContent
                    Spacer()
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                store.send(.onAppear)
                store.send(.recordList(.onAppear))
            }
            .refreshable {
                store.send(.refreshWeather)
                store.send(.recordList(.onAppear))
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if store.isLoading {
            loadingView
        } else if let weatherData = store.weatherData {
            weatherDataSection(weatherData: weatherData)
        } else if let errorMessage = store.errorMessage {
            errorView(errorMessage: errorMessage)
        }
    }
    
    private var loadingView: some View {
        ProgressView("날씨 정보를 불러오는 중...")
            .frame(height: 200)
    }
    
    private func errorView(errorMessage: String) -> some View {
        Text("오류: \(errorMessage)")
            .foregroundColor(.red)
            .frame(height: 200)
    }
    
    private func weatherDataSection(weatherData: WeatherData) -> some View {
        VStack(spacing: 20) {
            currentWeatherView(weatherData: weatherData)
            hourlyForecastView(weatherData: weatherData)
            WithViewStore(store.scope(state: \.recordList, action: \.recordList), observe: { $0 }) { recordListViewStore in
                RecentRunningChartSection(records: Array(recordListViewStore.records.prefix(5)))
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("RUNNING")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(RLColor.primary)
                + Text("LOG")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(RLColor.accent)
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
    
    private func currentWeatherView(weatherData: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("실시간 기상 정보")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                Text(getCurrentTimeString() + " 기준")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 20) {
                weatherInfoItem(
                    icon: getWeatherIcon(for: weatherData.weatherCondition),
                    title: weatherData.weatherCondition,
                    value: "\(Int(weatherData.temperature))°C",
                    iconColor: getWeatherIconColor(for: weatherData.weatherCondition)
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
                    
                    Text("미세먼지 표시 기준 AQI")
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
                HStack(alignment: .top, spacing: 15) {
                    ForEach(weatherData.hourlyForecast) { hourly in
                        VStack(spacing: 8) {
                            // 날짜와 시간을 한 셀에 함께 표시
                            Text(getDateStringForHourly(date: hourly.timestamp) + "\n" + hourly.time)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                            // SFSymbol로 날씨 아이콘 표시
                            Image(systemName: sfSymbolName(for: hourly.weatherIcon))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 36, height: 36)
                                .foregroundColor(sfSymbolTintColor(for: hourly.weatherIcon))
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
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 HH:mm"
        return formatter.string(from: Date())
    }
    
    private func getDateStringForHourly(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
    
    private func getOpenWeatherIconURL(icon: String) -> URL? {
        // OpenWeather 공식 아이콘 URL
        URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")
    }
    
    // OpenWeather 아이콘 코드 → SFSymbol 이름 매핑 함수
    private func sfSymbolName(for iconCode: String) -> String {
        switch iconCode {
        case "01d": return "sun.max.fill"         // 맑음(주간)
        case "01n": return "moon.stars.fill"      // 맑음(야간)
        case "02d": return "cloud.sun.fill"       // 약간 흐림(주간)
        case "02n": return "cloud.moon.fill"      // 약간 흐림(야간)
        case "03d", "03n": return "cloud.fill"    // 구름
        case "04d", "04n": return "smoke.fill"    // 짙은 구름
        case "09d", "09n": return "cloud.drizzle.fill" // 이슬비
        case "10d": return "cloud.sun.rain.fill"  // 비(주간)
        case "10n": return "cloud.moon.rain.fill" // 비(야간)
        case "11d", "11n": return "cloud.bolt.rain.fill" // 천둥번개
        case "13d", "13n": return "snowflake"     // 눈
        case "50d", "50n": return "cloud.fog.fill"// 안개
        default: return "questionmark.circle.fill"
        }
    }
    
    // SFSymbol에 맞는 tintColor 반환 함수
    private func sfSymbolTintColor(for iconCode: String) -> Color {
        switch iconCode {
        case "01d": return .orange           // 맑음(주간)
        case "01n": return .yellow           // 맑음(야간)
        case "02d": return .yellow           // 약간 흐림(주간)
        case "02n": return .gray             // 약간 흐림(야간)
        case "03d", "03n": return .gray      // 구름
        case "04d", "04n": return .gray      // 짙은 구름
        case "09d", "09n": return .blue      // 이슬비
        case "10d": return .blue             // 비(주간)
        case "10n": return .indigo           // 비(야간)
        case "11d", "11n": return .purple    // 천둥번개
        case "13d", "13n": return .mint      // 눈
        case "50d", "50n": return .teal      // 안개
        default: return .gray
        }
    }
}

// 최근 러닝 거리 꺾은선 그래프 섹션
struct RecentRunningChartSection: View {
    let records: [RunningRecord]
    var body: some View {
        if !records.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("최근 러닝 거리")
                    .font(.headline)
                    .fontWeight(.medium)
                LineChartView(records: records)
                    .frame(height: 140)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

// 꺾은선 그래프 뷰
struct LineChartView: View {
    let records: [RunningRecord]
    private let topPadding: CGFloat = 20
    private let bottomPadding: CGFloat = 24

    private var maxDistance: Double {
        records.map { $0.distance }.max() ?? 1
    }
    private var minDistance: Double {
        records.map { $0.distance }.min() ?? 0
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 배경 그리드
                VStack {
                    Spacer()
                    Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 1)
                }
                // 꺾은선
                if records.count > 1 {
                    Path { path in
                        for idx in records.indices {
                            let record = records[idx]
                            let x = geo.size.width * CGFloat(idx) / CGFloat(records.count - 1)
                            let y = yPosition(for: record.distance, in: geo.size)
                            if idx == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
                    .shadow(color: Color.accentColor.opacity(0.15), radius: 4, y: 2)
                }
                // 점/라벨
                ForEach(records.indices, id: \ .self) { idx in
                    let record = records[idx]
                    let x = geo.size.width * CGFloat(idx) / CGFloat(records.count - 1)
                    let y = yPosition(for: record.distance, in: geo.size)
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 10, height: 10)
                        .position(x: x, y: y)
                    // 거리 라벨 (위로 살짝 띄움)
                    Text(String(format: "%.1f", record.distance / 1000))
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                        .position(x: x, y: y - 14)
                }
                // x축 날짜 라벨
                ZStack {
                    ForEach(records.indices, id: \ .self) { idx in
                        let record = records[idx]
                        let x = geo.size.width * CGFloat(idx) / CGFloat(records.count - 1)
                        Text(shortDate(record.startTime))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .position(x: x, y: geo.size.height - 8)
                    }
                }
            }
        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }
    
    private func yPosition(for distance: Double, in size: CGSize) -> CGFloat {
        let availableHeight = size.height - topPadding - bottomPadding
        let ratio = (distance - minDistance) / max(0.01, maxDistance - minDistance)
        return topPadding + availableHeight * CGFloat(1 - ratio)
    }
    
    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}
