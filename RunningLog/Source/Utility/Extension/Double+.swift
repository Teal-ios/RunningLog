//
//  Double+.swift
//  RunningLog
//
//  Created by Den on 11/15/25.
//

import Foundation

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
    

    func formatDistanceKm() -> String {
        let distanceInKm = self / 1000.0
        return String(format: "%.2f km", distanceInKm)
    }
}
