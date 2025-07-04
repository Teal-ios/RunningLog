//
//  RunningWidget.swift
//  RunningWidget
//
//  Created by Den on 5/26/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Provider
struct RunningTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RunningEntry {
        RunningEntry(
            date: Date(),
            isRunning: false,
            distance: "0.00",
            time: "00:00:00",
            calories: "0"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RunningEntry) -> ()) {
        let entry = RunningEntry(
            date: Date(),
            isRunning: true,
            distance: "3.12",
            time: "00:27:03",
            calories: "245"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = getCurrentRunningEntry(date: currentDate)
        
        // 러닝 중이면 10초마다, 대기 중이면 1분마다 업데이트
        let updateInterval: TimeInterval = entry.isRunning ? 10 : 60
        let nextUpdate = Calendar.current.date(byAdding: .second, value: Int(updateInterval), to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func getCurrentRunningEntry(date: Date) -> RunningEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
        
        let isRunning = sharedDefaults?.bool(forKey: "isRunning") ?? false
        let distance = sharedDefaults?.string(forKey: "distance") ?? "0.00"
        let time = sharedDefaults?.string(forKey: "time") ?? "00:00:00"
        let calories = sharedDefaults?.string(forKey: "calories") ?? "0"
        
        return RunningEntry(
            date: date,
            isRunning: isRunning,
            distance: distance,
            time: time,
            calories: calories
        )
    }
}

// MARK: - Timeline Entry
struct RunningEntry: TimelineEntry {
    let date: Date
    let isRunning: Bool
    let distance: String
    let time: String
    let calories: String
}

// MARK: - Widget View
struct RunningWidgetEntryView: View {
    var entry: RunningTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        default:
            smallWidgetView
        }
    }
    
    // Small Widget View
    private var smallWidgetView: some View {
        VStack(spacing: 8) {
            // 상태와 시간
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.isRunning ? NSLocalizedString("status_running", comment: "") : NSLocalizedString("status_standby", comment: ""))
                    .font(.caption2)
                    .foregroundColor(entry.isRunning ? .green : .gray)
                
                Text(entry.time)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .minimumScaleFactor(0.8)
            }
            
            Spacer()
            
            // 거리
            VStack(spacing: 2) {
                Text("distance")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(entry.distance)
                        .font(.system(size: 14, weight: .semibold))
                    Text("unit_km")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .widgetURL(URL(string: "runninglog://widget-tap"))
    }
    
    // Medium Widget View
    private var mediumWidgetView: some View {
        VStack(spacing: 12) {
            // 상단: 상태와 시간
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.isRunning ? NSLocalizedString("status_running", comment: "") : NSLocalizedString("status_standby", comment: ""))
                        .font(.caption)
                        .foregroundColor(entry.isRunning ? .green : .gray)
                    
                    Text(entry.time)
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                }
                
                Spacer()
                
                // 재생/정지 버튼 (iOS 17+ AppIntent 지원)
                if #available(iOS 17.0, *) {
                    Button(intent: ToggleRunningIntent()) {
                        Image(systemName: entry.isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(entry.isRunning ? .orange : .green)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: entry.isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(entry.isRunning ? .orange : .green)
                }
            }
            
            // 하단: 거리와 칼로리
            HStack {
                VStack {
                    Text("distance")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(entry.distance)
                            .font(.system(size: 16, weight: .semibold))
                        Text("unit_km")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("calories")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(entry.calories)
                            .font(.system(size: 16, weight: .semibold))
                        Text("unit_kcal")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "runninglog://widget-tap"))
    }
}

// MARK: - Widget Configuration
struct RunningWidget: Widget {
    let kind: String = "RunningWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RunningTimelineProvider()) { entry in
            RunningWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("widget_name")
        .description("widget_description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - App Intent (iOS 17+)
@available(iOS 17.0, *)
struct ToggleRunningIntent: AppIntent {
    static var title: LocalizedStringResource = "러닝 토글"
    static var description = IntentDescription("러닝을 시작하거나 일시정지합니다.")
    
    func perform() async throws -> some IntentResult {
        // UserDefaults를 통해 앱과 통신
        let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
        let isRunning = sharedDefaults?.bool(forKey: "isRunning") ?? false
        
        // 상태 토글
        sharedDefaults?.set(!isRunning, forKey: "isRunning")
        
        // 위젯 업데이트 요청
        WidgetCenter.shared.reloadTimelines(ofKind: "RunningWidget")
        
        return .result()
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    RunningWidget()
} timeline: {
    RunningEntry(
        date: Date(),
        isRunning: true,
        distance: "3.12",
        time: "00:27:03",
        calories: "245"
    )
    RunningEntry(
        date: Date().addingTimeInterval(300),
        isRunning: false,
        distance: "5.47",
        time: "00:45:12",
        calories: "380"
    )
} 