//
//  GoalProgressRow.swift
//  RunningLog
//
//  Created by Den on 11/15/25.
//

import SwiftUI

struct GoalProgressRow: View {
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
