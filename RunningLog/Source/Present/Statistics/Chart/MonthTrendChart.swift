//
//  MonthTrendChart.swift
//  RunningLog
//
//  Created by Den on 11/15/25.
//

import SwiftUI
import Charts

struct MonthTrendChart: View {
    let title: String
    let data: [Double]
    let barColor: Color
    let months = (1...12).map { "\($0)월" }
    var isTime: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    if data[index] >= 0 {
                        let value = isTime ? data[index] : data[index] / 1000.0
                        
                        if isTime {
                            LineMark(
                                x: .value("월", months[index]),
                                y: .value("값", value)
                            )
                            .foregroundStyle(barColor)
                            .interpolationMethod(.monotone)
                            PointMark(
                                x: .value("월", months[index]),
                                y: .value("값", value)
                            )
                            .foregroundStyle(barColor)
                        } else {
                            BarMark(
                                x: .value("월", months[index]),
                                y: .value("값", value)
                            )
                            .foregroundStyle(barColor)
                        }
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
            .chartXAxis {
                AxisMarks(values: months.filter { $0.hasSuffix("월") && (Int($0.dropLast()) ?? 0) % 2 == 0 } ) { _ in AxisValueLabel() }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
