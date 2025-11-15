//
//  StatusBox.swift
//  RunningLog
//
//  Created by Den on 11/15/25.
//

import SwiftUI

struct StatsBox: View {
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

struct GoalAchievementView: View {
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
