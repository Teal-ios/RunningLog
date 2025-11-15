//
//  StatsGroup.swift
//  RunningLog
//
//  Created by Den on 11/15/25.
//

import Foundation

struct WeeklyStats: Equatable {
    let totalDistance: Double
    let totalTime: Double
    let runCount: Int
    let averagePace: Double
    let targetDistance: Double = 10000.0
    let targetCount: Int = 3
    
    var dailyDistance: [Double] = Array(repeating: 0.0, count: 7)
    // 일별 시간 기록 (분 단위)
    var dailyTimeMinutes: [Double] = Array(repeating: 0.0, count: 7)
}

struct MonthlyStats: Equatable {
    let totalDistance: Double
    let totalTime: Double
    let runCount: Int
    let averagePace: Double
    
    var weeklyDistance: [Double] = []
    var weeklyTimeMinutes: [Double] = []
    var weekLabels: [String] = []
}

struct YearlyStats: Equatable {
    let totalDistance: Double
    let totalTime: Double
    let runCount: Int
    let averagePace: Double
    
    var monthlyDistance: [Double] = Array(repeating: 0.0, count: 12)
    var monthlyTimeMinutes: [Double] = Array(repeating: 0.0, count: 12)
}

struct PeriodStats: Equatable {
    let totalDistance: Double
    let totalTime: Double
    let runCount: Int
    let averagePace: Double
}

