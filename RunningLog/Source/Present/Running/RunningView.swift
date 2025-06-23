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
                        title: "러닝 종료",
                        message: "러닝을 종료하고 기록을 저장하시겠습니까?",
                        confirmTitle: "저장하고 종료",
                        cancelTitle: "취소",
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
                Text("오류: \(errorMessage)")
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
                    Text("러닝 시간")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(viewStore.session.formattedTime)
                        .font(.system(size: 50, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                HStack(spacing: 40) {
                    StatItem(
                        title: "거리",
                        value: String(format: "%.2f", viewStore.session.distance / 1000),
                        unit: "km"
                    )
                    StatItem(
                        title: "칼로리",
                        value: "\(Int(viewStore.session.calories))",
                        unit: "kcal"
                    )
                    StatItem(
                        title: "페이스",
                        value: viewStore.session.currentPace > 0
                            ? String(format: "%.2f", viewStore.session.currentPace)
                            : "--.--",
                        unit: "분/km"
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
                
                Text("심박수")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // 심박수 값
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(heartRate > 0 ? "\(heartRate)" : "--")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(heartRateColor(for: heartRate))
                    .contentTransition(.numericText(value: Double(heartRate)))
                
                Text("bpm")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .offset(y: -8)
            }
            
            // 심박수 구간 표시
            if heartRate > 0 {
                heartRateZoneIndicator(for: heartRate)
            } else if isActive {
                Text("심박수 측정 중...")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .opacity(0.7)
            } else {
                Text("러닝 시작 시 심박수 측정")
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
            return ("휴식", .blue)
        case 90..<120:
            return ("지방연소", .green)
        case 120..<150:
            return ("유산소", .yellow)
        case 150..<180:
            return ("무산소", .orange)
        default:
            return ("최고강도", .red)
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
                 (state.session.isPaused ? "일시정지됨" : "러닝 중") : "대기 중")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if state.isLocationTrackingActive {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                    Text("위치 추적 중")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 심박수 상태 표시
            if state.session.isActive {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .foregroundColor(state.session.heartRate > 0 ? .red : .gray)
                    Text(state.session.heartRate > 0 ? "심박수 연결됨" : "심박수 대기 중")
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
            
            Text("탭을 전환해도 러닝이 계속됩니다")
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
        HStack(spacing: 20) {
            if !viewStore.session.isActive {
                // 시작 버튼
                Button(action: { viewStore.send(.startRunning) }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("러닝 시작")
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
                    // 재개 버튼
                    Button(action: { viewStore.send(.resumeRunning) }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("재개")
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
                            Text("일시정지")
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
                        Text("정지")
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

// MARK: - 통계 아이템
struct StatItem: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// 3D Flip 효과 Modifier (iOS 16+)
struct FlipEffect: ViewModifier {
    let angle: Double
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
            .animation(.easeInOut(duration: 0.5), value: angle)
    }
}

// 전체화면 MapView 오버레이
struct MapFullScreenView: View {
    @State private var region = MKCoordinateRegion()
    let routeID: UUID
    let locations: [CLLocation]
    let currentLocation: CLLocation?
    let onClose: () -> Void
    let runningTime: String
    let pace: Double
    let distance: Double
    
    var body: some View {
        ZStack {
            // 지도
            MapKitView(
                routeID: routeID,
                locations: locations,
                currentLocation: currentLocation,
                region: $region
            )
            .edgesIgnoringSafeArea(.all)
            
            // UI 요소들
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        if let current = currentLocation {
                            region = MKCoordinateRegion(
                                center: current.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                            )
                        }
                    }) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(.trailing, 8)
                    Button(action: onClose) {
                        Image(systemName: "map")
                            .font(.title2)
                            .padding(16)
                            .background(Color(.systemBackground).opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 8)
                }
                Spacer()
            }
            .padding(.top, 40)

            // 상단 정보 오버레이
            HStack(spacing: 24) {
                // 타이머
                VStack(spacing: 2) {
                    Text("시간")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(runningTime)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                // 페이스
                VStack(spacing: 2) {
                    Text("페이스")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(pace > 0 ? String(format: "%.2f", pace) : "--.--")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                // 거리
                VStack(spacing: 2) {
                    Text("거리")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f km", distance / 1000))
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.top, 40)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .onAppear {
            if let current = currentLocation {
                region = MKCoordinateRegion(
                    center: current.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                )
            }
        }
    }
}

// MARK: - 커스텀 Alert 뷰
struct CustomAlertView: View {
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Text(title)
                    .font(.title3).bold()
                    .foregroundColor(.primary)
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        Text(cancelTitle)
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 32)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut, value: 1)
    }
}

#Preview {
    RunningView(
        store: Store(initialState: RunningFeature.State()) {
            RunningFeature()
        }
    )
} 
