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

// 월간 통계 (주간 추이 데이터 포함)
struct MonthlyStats: Equatable {
    let totalDistance: Double
    let totalTime: Double
    let runCount: Int
    let averagePace: Double
    
    // 월간: 주별 기록 (1주차, 2주차, ...)
    var weeklyDistance: [Double] = []
    var weeklyTimeMinutes: [Double] = []
    var weekLabels: [String] = [] // "1주", "2주" 레이블
}

// 연간 통계 (월별 추이 데이터 포함)
struct YearlyStats: Equatable {
    let totalDistance: Double
    let totalTime: Double
    let runCount: Int
    let averagePace: Double
    
    // 연간: 월별 기록 (1월, 2월, ...)
    var monthlyDistance: [Double] = Array(repeating: 0.0, count: 12)
    var monthlyTimeMinutes: [Double] = Array(repeating: 0.0, count: 12)
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
    
    // StatisticsFeature 내부 또는 파일 상단에 정의
    static let minimumElapsedTime: Double = 60.0 // 1분 = 60초
    static let minimumDistance: Double = 0.1 // 100미터 = 0.1km
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
        // ✨ 변경: MonthlyStats, YearlyStats 사용
        var monthlyStats: MonthlyStats? = nil
        var yearlyStats: YearlyStats? = nil
        
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
                return .send(.calculateStats) // 기간이 바뀌면 통계 다시 계산/갱신
                
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
                // 주간 통계 (항상 계산)
                state.weeklyStats = StatisticsFeature.calculateWeeklyStats(from: state.records)
                
                // 월간/연간은 필요할 때만 계산 (새 레코드가 로드되거나, 해당 탭이 선택되었을 때)
                if state.selectedStatsPeriod == .monthly || state.monthlyStats == nil {
                    state.monthlyStats = StatisticsFeature.calculateMonthlyStats(from: state.records)
                }
                
                if state.selectedStatsPeriod == .yearly || state.yearlyStats == nil {
                    state.yearlyStats = StatisticsFeature.calculateYearlyStats(from: state.records)
                }
                
                return .none
            }
        }
    }
    
    // MARK: - 통계 계산 헬퍼 함수
    
    static func calculateWeeklyStats(from records: [RunningRecord]) -> WeeklyStats {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return .init(totalDistance: 0, totalTime: 0, runCount: 0, averagePace: 0)
        }
        
        // 1차 필터링: 해당 주간의 레코드만
        let weeklyRecords = records.filter { record in
            record.startTime >= startOfWeek
        }
        
        // ✨ 2차 필터링 추가: 시간이 1분(60초) 초과 AND 거리가 100m(0.1km) 초과인 레코드만 포함
        let filteredRecords = weeklyRecords.filter { record in
            record.elapsedTime > minimumElapsedTime && record.distance > minimumDistance
        }
        
        let totalDistance = filteredRecords.reduce(0.0) { $0 + $1.distance }
        let totalTime = filteredRecords.reduce(0.0) { $0 + $1.elapsedTime }
        let totalDistanceInKm = totalDistance / 1000.0 // 👈 미터 -> 킬로미터 변환
        let runCount = filteredRecords.count
        let averagePace = totalDistanceInKm > 0 ? totalTime / totalDistanceInKm : 0
        
        var dailyDistance: [Double] = Array(repeating: 0.0, count: 7)
        var dailyTimeMinutes: [Double] = Array(repeating: 0.0, count: 7)
        
        for record in filteredRecords { // filteredRecords 사용
            let weekday = calendar.component(.weekday, from: record.startTime)
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
    
    
    static func calculateMonthlyStats(from records: [RunningRecord]) -> MonthlyStats {
        let calendar = Calendar.current
        let today = Date()
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return .init(totalDistance: 0, totalTime: 0, runCount: 0, averagePace: 0)
        }
        
        // 1차 필터링: 해당 월의 레코드만
        let monthlyRecords = records.filter { record in record.startTime >= startOfMonth }
        
        // ✨ 2차 필터링 추가: 시간이 1분(60초) 초과 AND 거리가 100m(0.1km) 초과인 레코드만 포함
        let filteredRecords = monthlyRecords.filter { record in
            record.elapsedTime > minimumElapsedTime && record.distance > minimumDistance
        }
        
        // 이후 로직은 filteredRecords를 사용하도록 변경
        let totalDistance = filteredRecords.reduce(0.0) { $0 + $1.distance }
        let totalTime = filteredRecords.reduce(0.0) { $0 + $1.elapsedTime }
        let totalDistanceInKm = totalDistance / 1000.0
        let runCount = filteredRecords.count
        let averagePace = totalDistanceInKm > 0 ? totalTime / totalDistanceInKm : 0
        
        // 주차별 데이터 집계 (filteredRecords 기반으로 수정)
        var weeklyDistance: [Double] = []
        var weeklyTimeMinutes: [Double] = []
        var weekLabels: [String] = []
        
        let currentWeek = calendar.component(.weekOfMonth, from: today)
        
        for i in 1...currentWeek {
            // ... (주차 시작/끝 날짜 계산 로직 유지)
            guard let startDate = calendar.date(byAdding: .weekOfMonth, value: i - 1, to: startOfMonth) else { continue }
            // 해당 주차의 끝 날짜를 다음 주의 시작 날짜로 설정 (보다 정확한 주차 구분)
            guard let endDate = calendar.date(byAdding: .weekOfMonth, value: 1, to: startDate) else { continue }
            
            // 해당 주차에 포함되는 레코드 필터링 (filteredRecords에서 가져옴)
            let weekRecords = filteredRecords.filter { record in
                record.startTime >= startDate && record.startTime < endDate
            }
            
            let weekDistance = weekRecords.reduce(0.0) { $0 + $1.distance }
            let weekTimeMinutes = weekRecords.reduce(0.0) { $0 + $1.elapsedTime / 60.0 }
            
            weeklyDistance.append(weekDistance)
            weeklyTimeMinutes.append(weekTimeMinutes)
            weekLabels.append("\(i)주")
        }
        
        return MonthlyStats(
            totalDistance: totalDistance,
            totalTime: totalTime,
            runCount: runCount,
            averagePace: averagePace,
            weeklyDistance: weeklyDistance,
            weeklyTimeMinutes: weeklyTimeMinutes,
            weekLabels: weekLabels
        )
    }

    static func calculateYearlyStats(from records: [RunningRecord]) -> YearlyStats {
        let calendar = Calendar.current
        let today = Date()
        
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today)) else {
            return .init(totalDistance: 0, totalTime: 0, runCount: 0, averagePace: 0)
        }
        
        // 1차 필터링: 해당 년도의 레코드만
        let yearlyRecords = records.filter { record in record.startTime >= startOfYear }
        
        // ✨ 2차 필터링 추가: 시간이 1분(60초) 초과 AND 거리가 100m(0.1km) 초과인 레코드만 포함
        let filteredRecords = yearlyRecords.filter { record in
            record.elapsedTime > minimumElapsedTime && record.distance > minimumDistance
        }
        
        // 이후 로직은 filteredRecords를 사용하도록 변경
        let totalDistance = filteredRecords.reduce(0.0) { $0 + $1.distance }
        let totalTime = filteredRecords.reduce(0.0) { $0 + $1.elapsedTime }
        let totalDistanceInKm = totalDistance / 1000.0 // 👈 미터 -> 킬로미터 변환
        let runCount = filteredRecords.count
        let averagePace = totalDistanceInKm > 0 ? totalTime / totalDistanceInKm : 0
        print("주간 통계 - 총 거리: \(totalDistance), 총 시간: \(totalTime)")
        // 월별 데이터 집계 (filteredRecords 기반으로 수정)
        var monthlyDistance: [Double] = Array(repeating: 0.0, count: 12)
        var monthlyTimeMinutes: [Double] = Array(repeating: 0.0, count: 12)
        
        for record in filteredRecords { // filteredRecords 사용
            let month = calendar.component(.month, from: record.startTime)
            let index = month - 1
            if index >= 0 && index < 12 {
                monthlyDistance[index] += record.distance
                monthlyTimeMinutes[index] += record.elapsedTime / 60.0
            }
        }
        
        print("average", averagePace)

        return YearlyStats(
            totalDistance: totalDistance,
            totalTime: totalTime,
            runCount: runCount,
            averagePace: averagePace,
            monthlyDistance: monthlyDistance,
            monthlyTimeMinutes: monthlyTimeMinutes
        )
    }
}
