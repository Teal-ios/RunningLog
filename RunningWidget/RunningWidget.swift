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
            calories: "0",
            pace: "--'--\""
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RunningEntry) -> ()) {
        let entry = RunningEntry(
            date: Date(),
            isRunning: true,
            distance: "3.12",
            time: "00:27:03",
            calories: "245",
            pace: "5'23\""
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = getCurrentRunningEntry(date: currentDate)
        
        // 러닝 중이면 5초마다, 대기 중이면 30초마다 업데이트
        let updateInterval: TimeInterval = entry.isRunning ? 5 : 30
        let nextUpdate = Calendar.current.date(byAdding: .second, value: Int(updateInterval), to: currentDate)!
        
        // 여러 엔트리를 생성하여 더 자주 업데이트되도록 함
        var entries: [RunningEntry] = [entry]
        
        if entry.isRunning {
            // 러닝 중일 때는 5초, 10초, 15초 후에도 업데이트
            for offset in [5, 10, 15] {
                if let futureDate = Calendar.current.date(byAdding: .second, value: offset, to: currentDate) {
                    let futureEntry = getCurrentRunningEntry(date: futureDate)
                    entries.append(futureEntry)
                }
            }
        }
        
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getCurrentRunningEntry(date: Date) -> RunningEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
        
        let isRunning = sharedDefaults?.bool(forKey: "isRunning") ?? false
        let distance = sharedDefaults?.string(forKey: "distance") ?? "0.00"
        let time = sharedDefaults?.string(forKey: "time") ?? "00:00:00"
        let calories = sharedDefaults?.string(forKey: "calories") ?? "0"
        let pace = sharedDefaults?.string(forKey: "pace") ?? "--'--\""
        
        // 디버깅을 위한 로그
        print("[Widget] 상태 업데이트: 러닝=\(isRunning), 시간=\(time), 거리=\(distance)km, 페이스=\(pace)")
        
        return RunningEntry(
            date: date,
            isRunning: isRunning,
            distance: distance,
            time: time,
            calories: calories,
            pace: pace
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
    let pace: String
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
        VStack(spacing: 6) {
            // 상태와 시간
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.isRunning ? NSLocalizedString("status_running", comment: "") : NSLocalizedString("status_standby", comment: ""))
                    .font(.caption2)
                    .foregroundColor(entry.isRunning ? .green : .gray)
                
                Text(entry.time)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .minimumScaleFactor(0.8)
            }
            
            Spacer()
            
            // 거리와 페이스
            HStack {
                VStack(spacing: 2) {
                    Text("distance")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(entry.distance)
                            .font(.system(size: 12, weight: .semibold))
                        Text("unit_km")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("pace")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(entry.pace)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(entry.isRunning ? .primary : .secondary)
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
                
                // 재생/일시정지 토글 버튼만 표시 (iOS 17+ AppIntent 지원)
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
            
            // 하단: 거리, 칼로리, 페이스
            HStack {
                VStack {
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
                
                Spacer()
                
                VStack {
                    Text("pace")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(entry.pace)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(entry.isRunning ? .primary : .secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("calories")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(entry.calories)
                            .font(.system(size: 14, weight: .semibold))
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
        
        // 현재 상태에 따라 적절한 액션 설정
        let action = isRunning ? "pause" : "start"
        
        // 메인 앱에 액션 전달
        sharedDefaults?.set(action, forKey: "widgetAction")
        
        // 위젯 액션 타임스탬프 설정 (중복 처리 방지)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "widgetActionTime")
        
        print("[Widget] 위젯 액션 전달: \(action)")
        
        // 위젯 업데이트 요청 (상태 변경 없이 UI만 업데이트)
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
        calories: "245",
        pace: "5'23\""
    )
    RunningEntry(
        date: Date().addingTimeInterval(300),
        isRunning: false,
        distance: "5.47",
        time: "00:45:12",
        calories: "380",
        pace: "6'12\""
    )
} 