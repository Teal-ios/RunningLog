//
//  StatisticsFeature.swift
//  RunningLog
//
//  Created by Den on 11/13/25.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct StatisticsFeature {
    
    static let minimumElapsedTime: Double = 60.0
    static let minimumDistance: Double = 0.1
    
    enum StatsPeriod: String, CaseIterable, Identifiable {
        case weekly = "주간"
        case monthly = "월간"
        case yearly = "연간"
        var id: String { self.rawValue }
    }
    
    @ObservableState
    struct State: Equatable {
        var records: [RunningRecord] = []
        var weeklyStats: WeeklyStats? = nil
        var monthlyStats: MonthlyStats? = nil
        var yearlyStats: YearlyStats? = nil
        
        var selectedStatsPeriod: StatsPeriod = .weekly
        var isLoading = false
        var errorMessage: String?
        var repository: RunningRecordRepository? = nil
        
        static func == (lhs: State, rhs: State) -> Bool {
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
        case calculateStats
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .recordsUpdated(newRecords):
                state.records = newRecords
                return .send(.calculateStats)
                
            case let .selectStatsPeriod(period):
                state.selectedStatsPeriod = period
                return .send(.calculateStats)
                
            case .onAppear:
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
                return .send(.calculateStats)
                
            case let .recordsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .calculateStats:
                state.weeklyStats = StatisticsFeature.calculateWeeklyStats(from: state.records)
                
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
        
        let weeklyRecords = records.filter { record in
            record.startTime >= startOfWeek
        }
        
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
            return .init(totalDistance: 0, totalTime: 0, runCount: 0, averagePace: 0)
        }
        
        guard let startDate = calendar.date(from: calendar.dateComponents([component, .year], from: today)) else {
            return .init(totalDistance: 0, totalTime: 0, runCount: 0, averagePace: 0)
        }
        
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
        
        let monthlyRecords = records.filter { record in record.startTime >= startOfMonth }
        
        let filteredRecords = monthlyRecords.filter { record in
            record.elapsedTime > minimumElapsedTime && record.distance > minimumDistance
        }
        
        let totalDistance = filteredRecords.reduce(0.0) { $0 + $1.distance }
        let totalTime = filteredRecords.reduce(0.0) { $0 + $1.elapsedTime }
        let totalDistanceInKm = totalDistance / 1000.0
        let runCount = filteredRecords.count
        let averagePace = totalDistanceInKm > 0 ? totalTime / totalDistanceInKm : 0
        
        var weeklyDistance: [Double] = []
        var weeklyTimeMinutes: [Double] = []
        var weekLabels: [String] = []
        
        let currentWeek = calendar.component(.weekOfMonth, from: today)
        
        for i in 1...currentWeek {
            guard let startDate = calendar.date(byAdding: .weekOfMonth, value: i - 1, to: startOfMonth) else { continue }
            guard let endDate = calendar.date(byAdding: .weekOfMonth, value: 1, to: startDate) else { continue }
            
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
        
        let yearlyRecords = records.filter { record in record.startTime >= startOfYear }
        
        let filteredRecords = yearlyRecords.filter { record in
            record.elapsedTime > minimumElapsedTime && record.distance > minimumDistance
        }
        
        let totalDistance = filteredRecords.reduce(0.0) { $0 + $1.distance }
        let totalTime = filteredRecords.reduce(0.0) { $0 + $1.elapsedTime }
        let totalDistanceInKm = totalDistance / 1000.0 
        let runCount = filteredRecords.count
        let averagePace = totalDistanceInKm > 0 ? totalTime / totalDistanceInKm : 0
        print("주간 통계 - 총 거리: \(totalDistance), 총 시간: \(totalTime)")
        var monthlyDistance: [Double] = Array(repeating: 0.0, count: 12)
        var monthlyTimeMinutes: [Double] = Array(repeating: 0.0, count: 12)
        
        for record in filteredRecords {
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
