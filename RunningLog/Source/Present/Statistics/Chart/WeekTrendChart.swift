//
//  WeekTrendChart.swift
//  RunningLog
//
//  Created by Den on 11/15/25.
//

import SwiftUI
import Charts

struct WeekTrendChart: View {
    let title: String
    let data: [Double]
    let labels: [String]
    let barColor: Color
    var isTime: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    let value = isTime ? data[index] : data[index] / 1000.0
                    
                    if isTime {
                        LineMark(
                            x: .value("주차", labels[index]),
                            y: .value("값", value)
                        )
                        .foregroundStyle(barColor)
                        .interpolationMethod(.monotone)
                        PointMark(
                            x: .value("주차", labels[index]),
                            y: .value("값", value)
                        )
                        .foregroundStyle(barColor)
                    } else {
                        BarMark(
                            x: .value("주차", labels[index]),
                            y: .value("값", value)
                        )
                        .foregroundStyle(barColor)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if isTime == false {
                        AxisValueLabel(String(format: "%.2f", value.as(Double.self) ?? 0))
                    } else {
                        AxisValueLabel()
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis { AxisMarks(values: labels) { _ in AxisValueLabel() } }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
