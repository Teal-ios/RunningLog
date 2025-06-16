//
//  UserProfile.swift
//  RunningLog
//
//  Created by Den on 6/16/25.
//

import Foundation

// MARK: - Running Models
struct UserProfile: Equatable {
    var weight: Double = 70.0 // kg
    var age: Int = 30
    var height: Double = 170.0 // cm
    var gender: Gender = .male
    
    enum Gender {
        case male, female
        
        var calorieMultiplier: Double {
            switch self {
            case .male: return 1.0
            case .female: return 0.9
            }
        }
    }
}
