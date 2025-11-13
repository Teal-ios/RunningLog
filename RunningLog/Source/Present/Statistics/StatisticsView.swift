//
//  StatisticsView.swift
//  RunningLog
//
//  Created by Den on 11/13/25.
//

import SwiftUI
import ComposableArchitecture
import Charts // 차트 구현에 사용

// MARK: - 데이터 포맷 헬퍼

extension Double {
    /// 초/km 페이스를 "분'초"/km" 형식으로 포맷합니다. (예: 308.0 -> "5'08\"/km")
    func formatPace() -> String {
        guard self > 0 else { return "0'00\"/km" }
        let minutes = Int(self / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        return String(format: "%d'%02d\"/km", minutes, seconds)
    }
    
    /// 초 단위 시간을 "시간 분" 형식으로 포맷합니다. (예: 4860.0 -> "1시간 21분")
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
                                    value: String(format: "%.1f km", stats.totalDistance),
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
                        
                        // 주간 통계일 때만 목표 및 일별 차트 표시
                        if viewStore.selectedStatsPeriod == .weekly, let weeklyStats = viewStore.weeklyStats {
                            // MARK: - 목표 달성률
                            GoalAchievementView(stats: weeklyStats)
                                .padding(.horizontal)
                            
                            // MARK: - 거리 추이 차트
                            DataTrendChart(
                                title: "거리 추이",
                                data: weeklyStats.dailyDistance,
                                barColor: .orange
                            )
                            .frame(height: 200)
                            .padding(.horizontal)
                            
                            // MARK: - 시간 추이 차트
                            TimeTrendChart(
                                title: "시간 추이",
                                data: weeklyStats.dailyTimeMinutes
                            )
                            .frame(height: 200)
                            .padding(.horizontal)
                        } else {
                            Spacer()
                            Text("\(viewStore.selectedStatsPeriod.rawValue) 상세 데이터는 준비 중입니다.")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                    } else {
                        Text("통계 데이터를 로드할 수 없습니다.").foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
                .onAppear { viewStore.send(.onAppear) } // onAppear에서 데이터 로드 시작
            }
        }
    } // body
    
    // MARK: - View 헬퍼 함수 (StatisticsView 구조체 내부)
    
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

    // MARK: - 보조 View
    
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
                    current: stats.totalDistance,
                    target: stats.targetDistance,
                    color: .orange,
                    valueFormatter: { String(format: "%.1f / %.0f km", $0, $1) }
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

    private struct DataTrendChart: View {
        let title: String
        let data: [Double]
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
                            y: .value("거리", data[index])
                        )
                        .foregroundStyle(barColor)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: weekdays) { value in
                        AxisValueLabel()
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private struct TimeTrendChart: View {
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
                        .symbol(.circle)
                        
                        PointMark(
                            x: .value("요일", weekdays[index]),
                            y: .value("시간(분)", data[index])
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: weekdays) { value in
                        AxisValueLabel()
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
} // StatisticsView
