//
//  TimeTrendLineChart.swift
//  RunningLog
//
//  Created by Den on 11/15/25.
//

import SwiftUI
import Charts

struct TimeTrendLineChart: View {
    let title: String
    let data: [Double] 
    let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    LineMark(
                        x: .value("요일", weekdays[index]),
                        y: .value("시간(분)", data[index])
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.monotone)
                    
                    PointMark(
                        x: .value("요일", weekdays[index]),
                        y: .value("시간(분)", data[index])
                    )
                    .foregroundStyle(.blue)
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .chartXAxis { AxisMarks(values: weekdays) { _ in AxisValueLabel() } }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
