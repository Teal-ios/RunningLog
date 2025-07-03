//
//  RunningView.swift
//  RunningLog
//
//  Created by Den on 5/26/25.
//

import SwiftUI
import ComposableArchitecture
import MapKit

struct RunningView: View {
    let store: StoreOf<RunningFeature>
    @State private var isMapPresented = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var isStopAlertPresented = false
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                // 1. 러닝 화면 (메인)
                mainRunningContent(viewStore: viewStore)
                    .opacity(isMapPresented ? 0 : 1)
                    .modifier(FlipEffect(angle: isMapPresented ? -90 : 0))
                // 2. 전체화면 MapView (오버레이)
                if isMapPresented {
                    MapFullScreenView(
                        routeID: viewStore.runID ?? UUID(),
                        locations: viewStore.pathLocations,
                        currentLocation: viewStore.pathLocations.last,
                        onClose: { withAnimation { isMapPresented = false } },
                        runningTime: viewStore.session.formattedTime,
                        pace: viewStore.session.currentPace,
                        distance: viewStore.session.distance
                    )
                    .modifier(FlipEffect(angle: isMapPresented ? 0 : 90))
                }
                // 3. 커스텀 정지 Alert
                if isStopAlertPresented {
                    CustomAlertView(
                        title: NSLocalizedString("stop_running_title", comment: ""),
                        message: NSLocalizedString("stop_running_message", comment: ""),
                        confirmTitle: NSLocalizedString("save_and_stop", comment: ""),
                        cancelTitle: NSLocalizedString("cancel", comment: ""),
                        onConfirm: {
                            isStopAlertPresented = false
                            viewStore.send(.stopRunning)
                        },
                        onCancel: {
                            isStopAlertPresented = false
                        }
                    )
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isMapPresented)
            .background(Color(.systemBackground))
            .onAppear {
                viewStore.send(.onAppear)
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .background || newPhase == .inactive {
                    // 백그라운드/잠금 진입 시 위치 추적 유지
                    if viewStore.session.isActive && !viewStore.session.isPaused {
                        viewStore.send(.startLocationTracking)
                    }
                }
            }
        }
    }
    
    // 러닝 화면 내용 (상단 MapView 제거)
    @ViewBuilder
    private func mainRunningContent(viewStore: ViewStore<RunningFeature.State, RunningFeature.Action>) -> some View {
        VStack(spacing: 0) {
            // 상태바 + 지도 버튼
            HStack {
                statusBar(for: viewStore.state)
                Spacer()
                Button(action: { withAnimation { isMapPresented = true } }) {
                    Image(systemName: "map")
                        .font(.title2)
                        .padding(8)
                }
            }
            // 러닝 상태 인디케이터 (활성 상태일 때만 표시)
            if viewStore.session.isActive {
                runningStatusIndicator(for: viewStore.state)
            }
            // MapView 제거 (상단에 항상 보이지 않음)
            // 에러 메시지 (있을 경우)
            if let errorMessage = viewStore.errorMessage {
                Text(NSLocalizedString("error_prefix", comment: "") + errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.top, 5)
            }
            // 메인 컨텐츠
            VStack(spacing: 30) {
                Spacer()
                heartRateDisplay(heartRate: viewStore.session.heartRate, isActive: viewStore.session.isActive)
                VStack(spacing: 8) {
                    Text("running_time")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(viewStore.session.formattedTime)
                        .font(.system(size: 50, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                HStack(spacing: 40) {
                    StatItem(
                        title: NSLocalizedString("distance", comment: ""),
                        value: String(format: "%.2f", viewStore.session.distance / 1000),
                        unit: NSLocalizedString("unit_km", comment: "")
                    )
                    StatItem(
                        title: NSLocalizedString("calories", comment: ""),
                        value: "\(Int(viewStore.session.calories))",
                        unit: NSLocalizedString("unit_kcal", comment: "")
                    )
                    StatItem(
                        title: NSLocalizedString("pace", comment: ""),
                        value: viewStore.session.currentPace > 0
                            ? String(format: "%.2f", viewStore.session.currentPace)
                            : "--.--",
                        unit: NSLocalizedString("unit_min_per_km", comment: "")
                    )
                }
                Spacer()
                controlButtons(for: viewStore)
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - 심박수 표시
    @ViewBuilder
    private func heartRateDisplay(heartRate: Int, isActive: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // 심장 아이콘 (뛰는 애니메이션)
                Image(systemName: "heart.fill")
                    .foregroundColor(heartRateColor(for: heartRate))
                    .font(.title2)
                    .scaleEffect(isActive && heartRate > 0 ? 1.2 : 1.0)
                    .animation(
                        isActive && heartRate > 0 ? 
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : 
                        .default,
                        value: isActive
                    )
                
                Text("heart_rate")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // 심박수 값
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(heartRate > 0 ? "\(heartRate)" : "--")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(heartRateColor(for: heartRate))
                    .contentTransition(.numericText(value: Double(heartRate)))
                
                Text("unit_bpm")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .offset(y: -8)
            }
            
            // 심박수 구간 표시
            if heartRate > 0 {
                heartRateZoneIndicator(for: heartRate)
            } else if isActive {
                Text("heart_rate_measuring")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .opacity(0.7)
            } else {
                Text("heart_rate_start_info")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(heartRateColor(for: heartRate).opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    // MARK: - 심박수 색상
    private func heartRateColor(for heartRate: Int) -> Color {
        switch heartRate {
        case 0:
            return .gray
        case 1..<90:
            return .blue      // 휴식
        case 90..<120:
            return .green     // 가벼운 운동
        case 120..<150:
            return .yellow    // 보통 운동
        case 150..<180:
            return .orange    // 격렬한 운동
        default:
            return .red       // 최고 강도
        }
    }
    
    // MARK: - 심박수 구간 표시
    @ViewBuilder
    private func heartRateZoneIndicator(for heartRate: Int) -> some View {
        let zone = getHeartRateZone(for: heartRate)
        
        HStack(spacing: 4) {
            Circle()
                .fill(heartRateColor(for: heartRate))
                .frame(width: 8, height: 8)
            
            Text(zone.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(heartRateColor(for: heartRate))
        }
    }
    
    private func getHeartRateZone(for heartRate: Int) -> (name: String, color: Color) {
        switch heartRate {
        case 1..<90:
            return (NSLocalizedString("heart_zone_rest", comment: ""), .blue)
        case 90..<120:
            return (NSLocalizedString("heart_zone_fat_burn", comment: ""), .green)
        case 120..<150:
            return (NSLocalizedString("heart_zone_aerobic", comment: ""), .yellow)
        case 150..<180:
            return (NSLocalizedString("heart_zone_anaerobic", comment: ""), .orange)
        default:
            return (NSLocalizedString("heart_zone_max", comment: ""), .red)
        }
    }
    
    // MARK: - 상태바
    @ViewBuilder
    private func statusBar(for state: RunningFeature.State) -> some View {
        HStack {
            Circle()
                .fill(state.session.isActive ? 
                     (state.session.isPaused ? .orange : .green) : .gray)
                .frame(width: 8, height: 8)
            
            Text(state.session.isActive ? 
                 (state.session.isPaused ? "status_paused" : "status_running") : "status_waiting")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if state.isLocationTrackingActive {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                    Text("location_tracking")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 심박수 상태 표시
            if state.session.isActive {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .foregroundColor(state.session.heartRate > 0 ? .red : .gray)
                    Text(state.session.heartRate > 0 ? "heart_rate_connected" : "heart_rate_waiting")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - 러닝 상태 인디케이터
    @ViewBuilder
    private func runningStatusIndicator(for state: RunningFeature.State) -> some View {
        HStack {
            Image(systemName: "figure.run")
                .foregroundColor(.green)
            
            Text("running_continues_message")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if !state.session.isPaused {
                HStack(spacing: 2) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(.green)
                            .frame(width: 4, height: 4)
                            .opacity(0.3)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: state.session.elapsedTime
                            )
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.green.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    // MARK: - 컨트롤 버튼
    @ViewBuilder
    private func controlButtons(for viewStore: ViewStore<RunningFeature.State, RunningFeature.Action>) -> some View {
        HStack(spacing: 16) {
            if !viewStore.session.isActive {
                // 시작 버튼
                Button(action: { viewStore.send(.startRunning) }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("start")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .font(.headline)
                }
                .disabled(viewStore.isLoading)
            } else {
                if viewStore.session.isPaused {
                    // 재시작 버튼
                    Button(action: { viewStore.send(.resumeRunning) }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("restart")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .font(.headline)
                    }
                } else {
                    // 일시정지 버튼
                    Button(action: { viewStore.send(.pauseRunning) }) {
                        HStack {
                            Image(systemName: "pause.fill")
                            Text("pause")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .font(.headline)
                    }
                }
                // 정지 버튼 (Alert 표시)
                Button(action: { isStopAlertPresented = true }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("stop")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .font(.headline)
                }
            }
        }
    }
}

#Preview {
    RunningView(
        store: Store(initialState: RunningFeature.State()) {
            RunningFeature()
        }
    )
} 
