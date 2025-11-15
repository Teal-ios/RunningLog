//
//  DailyTrendChart.swift
//  RunningLog
//
//  Created by Den on 11/15/25.
//

import SwiftUI
import Charts

struct DailyTrendChart: View {
    let title: String
    let data: [Double]
    let barColor: Color
    let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    BarMark(
                        x: .value("요일", weekdays[index]),
                        y: .value("거리(km)", data[index] / 1000.0)
                    )
                    .foregroundStyle(barColor)
                }
            }
            .chartYAxis {
                // ✨ 수정됨: Y축 레이블을 km 단위로, 소수점 둘째 자리까지 표시
                AxisMarks(position: .leading) { value in
                    AxisValueLabel(String(format: "%.2f", value.as(Double.self) ?? 0))
                    AxisGridLine()
                }
            }
            .chartXAxis { AxisMarks(values: weekdays) { _ in AxisValueLabel() } }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
