//
//  StatisticsView.swift
//  RunningLog
//
//  Created by Den on 11/13/25.
//

import SwiftUI
import ComposableArchitecture
import Charts // 차트 구현에 사용

// MARK: - 데이터 포맷 헬퍼 (이전 답변과 동일)

extension Double {
    
    func formatPace() -> String {
        guard self > 0 else { return "0'00\"/km" }
        let minutes = Int(self / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        return String(format: "%d'%02d\"/km", minutes, seconds)
    }
    
    func formatTime() -> String {
        guard self > 0 else { return "0분" }
        let totalMinutes = Int(self / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
    
    /**
     거리(미터 단위)를 km로 변환하고 소수점 둘째 자리까지 반올림하여 포맷합니다.
     예: 2388.53226 -> "2.39 km"
     */
    func formatDistanceKm() -> String {
        // 미터 -> km 변환
        let distanceInKm = self / 1000.0
        // 소수점 둘째 자리까지 반올림 포맷
        return String(format: "%.2f km", distanceInKm)
    }
}
// MARK: - StatisticsView

struct StatisticsView: View {
    let store: StoreOf<StatisticsFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                
                let currentStats = self.getCurrentStats(state: viewStore.state)
                
                VStack(spacing: 20) {
                    // MARK: - 탭 선택 (주간, 월간, 연간)
                    Picker("기간", selection: viewStore.binding(
                        get: \.selectedStatsPeriod,
                        send: StatisticsFeature.Action.selectStatsPeriod
                    )) {
                        ForEach(StatisticsFeature.StatsPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // MARK: - 통계 내용 표시
                    if viewStore.isLoading {
                        ProgressView("기록 로드 중...")
                    } else if viewStore.errorMessage != nil {
                        Text("에러: \(viewStore.errorMessage!)").foregroundColor(.red)
                    } else if viewStore.records.isEmpty {
                        Text("기록이 없습니다.").foregroundColor(.gray)
                    } else if let stats = currentStats {
                        
                        // MARK: - 주요 통계 (4개 박스)
                        VStack(spacing: 16) {
                            HStack {
                                StatsBox(
                                    iconName: "chart.line.uptrend.xyaxis",
                                    title: "총 거리",
                                    // ✨ 수정됨: formatDistanceKm() 사용
                                    value: stats.totalDistance.formatDistanceKm(),
                                    color: .orange
                                )
                                StatsBox(
                                    iconName: "waveform.path.ecg",
                                    title: "총 시간",
                                    value: stats.totalTime.formatTime(),
                                    color: .blue
                                )
                            }
                            HStack {
                                StatsBox(
                                    iconName: "calendar",
                                    title: "러닝 횟수",
                                    value: "\(stats.runCount)회",
                                    color: .green
                                )
                                StatsBox(
                                    iconName: "trophy",
                                    title: "평균 페이스",
                                    value: stats.averagePace.formatPace(),
                                    color: .yellow
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: - 기간별 상세 통계 영역
                        VStack(spacing: 20) {
                            switch viewStore.selectedStatsPeriod {
                            case .weekly:
                                if let weeklyStats = viewStore.weeklyStats {
                                    // 목표 달성률
                                    GoalAchievementView(stats: weeklyStats)
                                        .padding(.horizontal)
                                    
                                    // 일별 거리 추이 차트 (Y축 포맷 수정)
                                    DailyTrendChart(
                                        title: "일별 거리 추이 (km)",
                                        data: weeklyStats.dailyDistance, // 미터 단위
                                        barColor: .orange
                                    )
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                    
                                    // 일별 시간 추이 차트
                                    TimeTrendLineChart(
                                        title: "일별 시간 추이 (분)",
                                        data: weeklyStats.dailyTimeMinutes
                                    )
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                }
                                
                            case .monthly:
                                if let monthlyStats = viewStore.monthlyStats {
                                    // 주별 거리 추이 차트
                                    WeekTrendChart(
                                        title: "주별 거리 추이 (km)",
                                        data: monthlyStats.weeklyDistance, // 미터 단위
                                        labels: monthlyStats.weekLabels,
                                        barColor: .orange
                                    )
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                    
                                    // 주별 시간 추이 차트
                                    WeekTrendChart(
                                        title: "주별 시간 추이 (분)",
                                        data: monthlyStats.weeklyTimeMinutes,
                                        labels: monthlyStats.weekLabels,
                                        barColor: .blue,
                                        isTime: true
                                    )
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                }
                                
                            case .yearly:
                                if let yearlyStats = viewStore.yearlyStats {
                                    // 월별 거리 추이 차트
                                    MonthTrendChart(
                                        title: "월별 거리 추이 (km)",
                                        data: yearlyStats.monthlyDistance, // 미터 단위
                                        barColor: .orange
                                    )
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                    
                                    // 월별 시간 추이 차트
                                    MonthTrendChart(
                                        title: "월별 시간 추이 (분)",
                                        data: yearlyStats.monthlyTimeMinutes,
                                        barColor: .blue,
                                        isTime: true
                                    )
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    } else {
                        Text("통계 데이터를 로드할 수 없습니다.").foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
                .onAppear { viewStore.send(.onAppear) }
            }
        }
    } // body
    
    // MARK: - View 헬퍼 함수
    
    private func getCurrentStats(state: StatisticsFeature.State) -> (totalDistance: Double, totalTime: Double, runCount: Int, averagePace: Double)? {
        switch state.selectedStatsPeriod {
        case .weekly:
            if let stats = state.weeklyStats {
                return (stats.totalDistance, stats.totalTime, stats.runCount, stats.averagePace)
            }
        case .monthly:
            if let stats = state.monthlyStats {
                return (stats.totalDistance, stats.totalTime, stats.runCount, stats.averagePace)
            }
        case .yearly:
            if let stats = state.yearlyStats {
                return (stats.totalDistance, stats.totalTime, stats.runCount, stats.averagePace)
            }
        }
        return nil
    }
    
    // MARK: - 보조 View (차트)
    
    // 주간 통계의 일별 추이 차트 (막대 그래프)
    private struct DailyTrendChart: View {
        let title: String
        let data: [Double] // 미터 단위
        let barColor: Color
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Chart {
                    ForEach(data.indices, id: \.self) { index in
                        BarMark(
                            x: .value("요일", weekdays[index]),
                            // 미터 단위를 km로 변환하여 차트에 사용
                            y: .value("거리(km)", data[index] / 1000.0)
                        )
                        .foregroundStyle(barColor)
                    }
                }
                .chartYAxis {
                    // ✨ 수정됨: Y축 레이블을 km 단위로, 소수점 둘째 자리까지 표시
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel(String(format: "%.2f", value.as(Double.self) ?? 0))
                        AxisGridLine()
                    }
                }
                .chartXAxis { AxisMarks(values: weekdays) { _ in AxisValueLabel() } }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    // 주간 통계의 일별 시간 추이 차트 (선 그래프)
    private struct TimeTrendLineChart: View {
        let title: String
        let data: [Double] // 분 단위
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Chart {
                    ForEach(data.indices, id: \.self) { index in
                        LineMark(
                            x: .value("요일", weekdays[index]),
                            y: .value("시간(분)", data[index])
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.monotone)
                        
                        PointMark(
                            x: .value("요일", weekdays[index]),
                            y: .value("시간(분)", data[index])
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis { AxisMarks(values: weekdays) { _ in AxisValueLabel() } }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    // 월간 통계의 주별 추이 차트
    private struct WeekTrendChart: View {
        let title: String
        let data: [Double] // 거리: 미터 단위, 시간: 분 단위
        let labels: [String] // "1주", "2주", ...
        let barColor: Color
        var isTime: Bool = false
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Chart {
                    ForEach(data.indices, id: \.self) { index in
                        // 거리일 경우 미터 -> km 변환 적용
                        let value = isTime ? data[index] : data[index] / 1000.0
                        
                        if isTime {
                            LineMark(
                                x: .value("주차", labels[index]),
                                y: .value("값", value)
                            )
                            .foregroundStyle(barColor)
                            .interpolationMethod(.monotone)
                            PointMark(
                                x: .value("주차", labels[index]),
                                y: .value("값", value)
                            )
                            .foregroundStyle(barColor)
                        } else {
                            BarMark(
                                x: .value("주차", labels[index]),
                                y: .value("값", value)
                            )
                            .foregroundStyle(barColor)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        // ✨ 수정됨: Y축 레이블을 km 단위로, 소수점 둘째 자리까지 표시 (시간은 기본값)
                        if isTime == false {
                            AxisValueLabel(String(format: "%.2f", value.as(Double.self) ?? 0))
                        } else {
                            AxisValueLabel()
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxis { AxisMarks(values: labels) { _ in AxisValueLabel() } }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    // 연간 통계의 월별 추이 차트
    private struct MonthTrendChart: View {
        let title: String
        let data: [Double] // 거리: 미터 단위, 시간: 분 단위
        let barColor: Color
        let months = (1...12).map { "\($0)월" }
        var isTime: Bool = false
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Chart {
                    ForEach(data.indices, id: \.self) { index in
                        // 현재 월까지만 표시
                        if data[index] >= 0 {
                            // 거리일 경우 미터 -> km 변환 적용
                            let value = isTime ? data[index] : data[index] / 1000.0
                            
                            if isTime {
                                LineMark(
                                    x: .value("월", months[index]),
                                    y: .value("값", value)
                                )
                                .foregroundStyle(barColor)
                                .interpolationMethod(.monotone)
                                PointMark(
                                    x: .value("월", months[index]),
                                    y: .value("값", value)
                                )
                                .foregroundStyle(barColor)
                            } else {
                                BarMark(
                                    x: .value("월", months[index]),
                                    y: .value("값", value)
                                )
                                .foregroundStyle(barColor)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        // ✨ 수정됨: Y축 레이블을 km 단위로, 소수점 둘째 자리까지 표시 (시간은 기본값)
                        if isTime == false {
                            AxisValueLabel(String(format: "%.2f", value.as(Double.self) ?? 0))
                        } else {
                            AxisValueLabel()
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    // 2개월 간격으로 레이블 표시
                    AxisMarks(values: months.filter { $0.hasSuffix("월") && (Int($0.dropLast()) ?? 0) % 2 == 0 } ) { _ in AxisValueLabel() }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private struct StatsBox: View {
        let iconName: String
        let title: String
        let value: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconName)
                        .foregroundColor(color)
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 100)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private struct GoalAchievementView: View {
        let stats: WeeklyStats
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("목표 달성률")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                GoalProgressRow(
                    label: "거리",
                    current: stats.totalDistance, // 미터 단위
                    target: stats.targetDistance, // 미터 단위
                    color: .orange,
                    // ✨ 수정됨: 미터를 km로 변환하여 표시
                    valueFormatter: { current, target in
                        "\(String(format: "%.2f", current / 1000.0)) / \(String(format: "%.0f", target / 1000.0)) km"
                    }
                )
                GoalProgressRow(
                    label: "횟수",
                    current: Double(stats.runCount),
                    target: Double(stats.targetCount),
                    color: .blue,
                    valueFormatter: { String(format: "%.0f / %.0f회", $0, $1) }
                )
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private struct GoalProgressRow: View {
        let label: String
        let current: Double
        let target: Double
        let color: Color
        let valueFormatter: (Double, Double) -> String
        
        var progress: Double { target > 0 ? min(current / target, 1.0) : 0.0 }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.subheadline)
                    Spacer()
                    Text(valueFormatter(current, target))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(color)
                            .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
    }
}
