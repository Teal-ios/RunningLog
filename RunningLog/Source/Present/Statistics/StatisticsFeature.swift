//
//  StatisticsFeature.swift
//  RunningLog
//
//  Created by Den on 11/13/25.
//

import Foundation
import ComposableArchitecture
import SwiftUI // Chart, Date 관련

// MARK: - 통계 데이터 모델

// 주간 통계 요약 데이터 (기존 모델 유지)
struct WeeklyStats: Equatable {
    let totalDistance: Double
    let totalTime: Double // 초 단위
    let runCount: Int
    let averagePace: Double // 초/km 단위
    let targetDistance: Double = 10.0 // 목표 거리 (예시)
    let targetCount: Int = 3 // 목표 횟수 (예시)
    
    // 일별 거리 기록 (0=일, 1=월, ... 6=토)
    var dailyDistance: [Double] = Array(repeating: 0.0, count: 7)
    // 일별 시간 기록 (분 단위)
    var dailyTimeMinutes: [Double] = Array(repeating: 0.0, count: 7)
}

// 월간/연간 통계를 위한 범용 통계 구조체
struct PeriodStats: Equatable {
    let totalDistance: Double
    let totalTime: Double
    let runCount: Int
    let averagePace: Double
    // (선택 사항: 월별 일별 기록, 연도별 월별 기록 등 추가 가능)
}


// MARK: - StatisticsFeature

@Reducer
struct StatisticsFeature {
    
    // 통계 기간 enum
    enum StatsPeriod: String, CaseIterable, Identifiable {
        case weekly = "주간"
        case monthly = "월간"
        case yearly = "연간"
        var id: String { self.rawValue }
    }
    
    @ObservableState
    struct State: Equatable {
        var records: [RunningRecord] = [] // 외부에서 주입받는 원본 데이터
        // ✨ 변경: 기간별 통계를 저장할 필드 추가
        var weeklyStats: WeeklyStats? = nil
        var monthlyStats: PeriodStats? = nil
        var yearlyStats: PeriodStats? = nil
        
        var selectedStatsPeriod: StatsPeriod = .weekly // 초기값: 주간
        var isLoading = false
        var errorMessage: String?
        var repository: RunningRecordRepository? = nil

        static func == (lhs: State, rhs: State) -> Bool {
            // records.count는 로드 여부 판단을 위해 유지
            lhs.records.count == rhs.records.count &&
            lhs.weeklyStats == rhs.weeklyStats &&
            lhs.monthlyStats == rhs.monthlyStats &&
            lhs.yearlyStats == rhs.yearlyStats &&
            lhs.selectedStatsPeriod == rhs.selectedStatsPeriod
        }
    }
    
    enum Action {
        case recordsUpdated([RunningRecord])
        case selectStatsPeriod(StatsPeriod)
        case onAppear
        case repositoryReady
        case loadRecords
        case recordsResponse(Result<[RunningRecord], Error>)
        // ✨ 추가: 통계 계산을 분리할 액션
        case calculateStats
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .recordsUpdated(newRecords):
                state.records = newRecords
                // 데이터가 변경되면 모든 통계를 다시 계산
                return .send(.calculateStats)
                
            case let .selectStatsPeriod(period):
                state.selectedStatsPeriod = period
                // 기간이 변경되면 해당 통계가 이미 State에 있는지 확인하고, 없으면 계산
                if (period == .monthly && state.monthlyStats == nil) ||
                   (period == .yearly && state.yearlyStats == nil) {
                    return .send(.calculateStats)
                }
                return .none
                
            case .onAppear:
                // ... 기존 로직 유지 ... (PersistenceController.shared.isStoreLoaded, repository 생성 등)
                state.isLoading = true
                if PersistenceController.shared.isStoreLoaded {
                    state.repository = CoreDataRunningRecordRepository(context: PersistenceController.shared.container.viewContext)
                    return .send(.repositoryReady)
                } else {
                    state.errorMessage = NSLocalizedString("database_not_ready_wait", comment: "")
                    state.isLoading = false
                    return .none
                }
                
            case .repositoryReady:
                return .send(.loadRecords)
                
            case .loadRecords:
                // ... 기존 로직 유지 ... (repository에서 fetchAll 실행)
                state.isLoading = true
                guard let repository = state.repository else {
                    state.isLoading = false
                    return .none
                }
                return .run { send in
                    do {
                        let records = try repository.fetchAll().sorted { $0.startTime > $1.startTime }
                        await send(.recordsResponse(.success(records)))
                    } catch {
                        await send(.recordsResponse(.failure(error)))
                    }
                }
                
            case let .recordsResponse(.success(records)):
                state.records = records
                state.isLoading = false
                state.errorMessage = nil
                // 로드 후 통계 계산 액션 호출
                return .send(.calculateStats)
                
            case let .recordsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .calculateStats:
                // 주간 통계 계산 (항상 계산하여 최신 상태 유지)
                state.weeklyStats = StatisticsFeature.calculateWeeklyStats(from: state.records)

                // 선택된 기간이 월간이고, 아직 계산되지 않았거나, 전체 기록이 업데이트된 경우 계산
                if state.selectedStatsPeriod == .monthly || state.monthlyStats == nil {
                    state.monthlyStats = StatisticsFeature.calculatePeriodStats(from: state.records, period: .monthly)
                }

                // 선택된 기간이 연간이고, 아직 계산되지 않았거나, 전체 기록이 업데이트된 경우 계산
                if state.selectedStatsPeriod == .yearly || state.yearlyStats == nil {
                    state.yearlyStats = StatisticsFeature.calculatePeriodStats(from: state.records, period: .yearly)
                }
                
                return .none
            }
        }
    }
    
    // MARK: - 통계 계산 헬퍼 함수
    
    // 주간 통계 (일별 데이터 포함, 기존 로직 유지)
    static func calculateWeeklyStats(from records: [RunningRecord]) -> WeeklyStats {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return .init(totalDistance: 0, totalTime: 0, runCount: 0, averagePace: 0)
        }
        
        let weeklyRecords = records.filter { record in
            record.startTime >= startOfWeek
        }
        
        // ... (주간 통계 계산 로직 유지) ...
        let totalDistance = weeklyRecords.reduce(0.0) { $0 + $1.distance }
        let totalTime = weeklyRecords.reduce(0.0) { $0 + $1.elapsedTime }
        let runCount = weeklyRecords.count
        let averagePace = totalDistance > 0 ? totalTime / totalDistance : 0
        
        var dailyDistance: [Double] = Array(repeating: 0.0, count: 7)
        var dailyTimeMinutes: [Double] = Array(repeating: 0.0, count: 7)
        
        for record in weeklyRecords {
            let weekday = calendar.component(.weekday, from: record.startTime) // 1=일요일, 2=월요일, ...
            let index = (weekday + 5) % 7 // 0=일, 1=월, ...
            
            dailyDistance[index] += record.distance
            dailyTimeMinutes[index] += record.elapsedTime / 60.0
        }
        
        return WeeklyStats(
            totalDistance: totalDistance,
            totalTime: totalTime,
            runCount: runCount,
            averagePace: averagePace,
            dailyDistance: dailyDistance,
            dailyTimeMinutes: dailyTimeMinutes
        )
    }
    
    // 월간/연간 통계 (범용 통계 계산)
    static func calculatePeriodStats(from records: [RunningRecord], period: StatsPeriod) -> PeriodStats {
        let calendar = Calendar.current
        let today = Date()
        var component: Calendar.Component
        
        switch period {
        case .monthly:
            component = .month
        case .yearly:
            component = .year
        case .weekly:
            // weekly는 별도의 함수를 사용함
            return .init(totalDistance: 0, totalTime: 0, runCount: 0, averagePace: 0)
        }
        
        // 해당 기간의 시작 날짜 계산
        guard let startDate = calendar.date(from: calendar.dateComponents([component, .year], from: today)) else {
            return .init(totalDistance: 0, totalTime: 0, runCount: 0, averagePace: 0)
        }
        
        // 해당 기간에 해당하는 기록 필터링
        let periodRecords = records.filter { record in
            record.startTime >= startDate
        }
        
        let totalDistance = periodRecords.reduce(0.0) { $0 + $1.distance }
        let totalTime = periodRecords.reduce(0.0) { $0 + $1.elapsedTime }
        let runCount = periodRecords.count
        let averagePace = totalDistance > 0 ? totalTime / totalDistance : 0
        
        return PeriodStats(
            totalDistance: totalDistance,
            totalTime: totalTime,
            runCount: runCount,
            averagePace: averagePace
        )
    }
}
