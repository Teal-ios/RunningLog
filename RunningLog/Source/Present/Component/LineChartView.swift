//
//  LineChartView.swift
//  RunningLog
//
//  Created by Den on 6/30/25.
//

import SwiftUI
// 꺾은선 그래프 뷰
struct LineChartView: View {
    let records: [RunningRecord]
    private let topPadding: CGFloat = 20
    private let bottomPadding: CGFloat = 24

    private var maxDistance: Double {
        records.map { $0.distance }.max() ?? 1
    }
    private var minDistance: Double {
        records.map { $0.distance }.min() ?? 0
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 배경 그리드
                VStack {
                    Spacer()
                    Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 1)
                }
                // 꺾은선
                if records.count > 1 {
                    Path { path in
                        for idx in records.indices {
                            let record = records[idx]
                            let x = geo.size.width * CGFloat(idx) / CGFloat(records.count - 1)
                            let y = yPosition(for: record.distance, in: geo.size)
                            if idx == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
                    .shadow(color: Color.accentColor.opacity(0.15), radius: 4, y: 2)
                }
                // 점/라벨
                ForEach(records.indices, id: \ .self) { idx in
                    let record = records[idx]
                    let x = geo.size.width * CGFloat(idx) / CGFloat(records.count - 1)
                    let y = yPosition(for: record.distance, in: geo.size)
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 10, height: 10)
                        .position(x: x, y: y)
                    // 거리 라벨 (위로 살짝 띄움)
                    Text(String(format: "%.1f", record.distance / 1000))
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                        .position(x: x, y: y - 14)
                }
                // x축 날짜 라벨
                ZStack {
                    ForEach(records.indices, id: \ .self) { idx in
                        let record = records[idx]
                        let x = geo.size.width * CGFloat(idx) / CGFloat(records.count - 1)
                        Text(shortDate(record.startTime))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .position(x: x, y: geo.size.height - 8)
                    }
                }
            }
        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }
    
    private func yPosition(for distance: Double, in size: CGSize) -> CGFloat {
        let availableHeight = size.height - topPadding - bottomPadding
        let ratio = (distance - minDistance) / max(0.01, maxDistance - minDistance)
        return topPadding + availableHeight * CGFloat(1 - ratio)
    }
    
    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}
