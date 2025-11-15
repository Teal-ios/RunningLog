//
//  StatisticsView.swift
//  RunningLog
//
//  Created by Den on 11/13/25.
//

import SwiftUI
import ComposableArchitecture
import Charts

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
                                    GoalAchievementView(stats: weeklyStats)
                                        .padding(.horizontal)
                                    
                                    DailyTrendChart(
                                        title: "일별 거리 추이 (km)",
                                        data: weeklyStats.dailyDistance, // 미터 단위
                                        barColor: .orange
                                    )
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                    
                                    TimeTrendLineChart(
                                        title: "일별 시간 추이 (분)",
                                        data: weeklyStats.dailyTimeMinutes
                                    )
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                }
                                
                            case .monthly:
                                if let monthlyStats = viewStore.monthlyStats {
                                    WeekTrendChart(
                                        title: "주별 거리 추이 (km)",
                                        data: monthlyStats.weeklyDistance, // 미터 단위
                                        labels: monthlyStats.weekLabels,
                                        barColor: .orange
                                    )
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                    
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
                                    MonthTrendChart(
                                        title: "월별 거리 추이 (km)",
                                        data: yearlyStats.monthlyDistance, // 미터 단위
                                        barColor: .orange
                                    )
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                    
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
                .onAppear { viewStore.send(.onAppear) }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
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
}
