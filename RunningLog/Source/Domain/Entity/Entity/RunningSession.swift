//
//  RunningSession.swift
//  RunningLog
//
//  Created by Den on 6/16/25.
//

import Foundation

struct RunningSession: Equatable {
    let id = UUID()
    var startTime: Date?
    var endTime: Date?
    var distance: Double = 0.0 // meters
    var currentPace: Double = 0.0 // minutes per km
    var averagePace: Double = 0.0
    var heartRate: Int = 0 // bpm
    var calories: Double = 0.0 // kcal
    var isActive: Bool = false
    var isPaused: Bool = false
    var elapsedTime: TimeInterval = 0
    
    var formattedDistance: String {
        String(format: "%.2f", distance / 1000)
    }
    
    var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var formattedPace: String {
        if currentPace == 0 { return "--'--\"" }
        let minutes = Int(currentPace)
        let seconds = Int((currentPace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"", minutes, seconds)
    }
    
    var formattedCalories: String {
        return String(format: "%.0f", calories)
    }
    
    // 칼로리 계산 (MET 기반)
    mutating func calculateCalories(userProfile: UserProfile) {
        guard elapsedTime > 0 else { return }
        
        // 평균 속도 계산 (km/h)
        let distanceInKm = distance / 1000.0
        let timeInHours = elapsedTime / 3600.0
        let speedKmh = distanceInKm / timeInHours
        
        // MET 값 계산 (러닝 속도에 따른)
        let met: Double
        switch speedKmh {
        case 0..<6: met = 6.0    // 걷기
        case 6..<8: met = 8.3    // 조깅
        case 8..<10: met = 11.0  // 러닝
        case 10..<12: met = 11.5 // 빠른 러닝
        case 12..<14: met = 12.8 // 매우 빠른 러닝
        default: met = 15.0      // 스프린트
        }
        
        // 칼로리 = MET × 체중(kg) × 시간(h) × 성별 보정
        calories = met * userProfile.weight * timeInHours * userProfile.gender.calorieMultiplier
    }
}
