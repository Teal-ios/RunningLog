//
//  RunningView.swift
//  RunningLog
//
//  Created by Den on 5/26/25.
//

import SwiftUI
import ComposableArchitecture

struct RunningView: View {
    let store: StoreOf<RunningFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                // 상태바 영역
                statusBar(for: viewStore.state)
                
                // 러닝 상태 인디케이터 (활성 상태일 때만 표시)
                if viewStore.session.isActive {
                    runningStatusIndicator(for: viewStore.state)
                }
                
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
                    
                    // 심박수 표시 (강조)
                    heartRateDisplay(heartRate: viewStore.session.heartRate, isActive: viewStore.session.isActive)
                    
                    // 시간 표시
                    VStack(spacing: 8) {
                        Text("러닝 시간")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(viewStore.session.formattedTime)
                            .font(.system(size: 50, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    // 거리와 칼로리 통계
                    HStack(spacing: 60) {
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
                    }
                    
                    Spacer()
                    
                    // 컨트롤 버튼
                    controlButtons(for: viewStore)
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .onAppear {
                viewStore.send(.onAppear)
            }
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
                
                // 정지 버튼
                Button(action: { viewStore.send(.stopRunning) }) {
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

#Preview {
    RunningView(
        store: Store(initialState: RunningFeature.State()) {
            RunningFeature()
        }
    )
} 
