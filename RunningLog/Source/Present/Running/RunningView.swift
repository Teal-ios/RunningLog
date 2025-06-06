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
                statusBar
                
                // 메인 컨텐츠
                VStack(spacing: 40) {
                    Spacer()
                    
                    // 거리
                    distanceView(distance: viewStore.session.formattedDistance)
                    
                    // 타이머
                    timerView(time: viewStore.session.formattedTime)
                    
                    // 심박수
                    heartRateView(heartRate: viewStore.session.heartRate)
                    
                    Spacer()
                    
                    // 일시정지/재개 버튼
                    controlButton(
                        isPaused: viewStore.session.isPaused,
                        isActive: viewStore.session.isActive
                    ) {
                        if viewStore.session.isActive {
                            if viewStore.session.isPaused {
                                viewStore.send(.resumeRunning)
                            } else {
                                viewStore.send(.pauseRunning)
                            }
                        } else {
                            viewStore.send(.startRunning)
                        }
                    }
                    
                    Spacer()
                    
                    // 하단 버튼들
                    bottomButtons
                }
                .padding(.horizontal, 20)
                .background(Color.white)
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
    
    // MARK: - Status Bar
    private var statusBar: some View {
        HStack {
            // 신호 강도
            HStack(spacing: 2) {
                ForEach(0..<4) { index in
                    Rectangle()
                        .frame(width: 3, height: CGFloat(3 + index * 2))
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
            
            // 배터리
            HStack(spacing: 2) {
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
                    .frame(width: 22, height: 11)
                    .overlay(
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 18, height: 7)
                    )
                Rectangle()
                    .frame(width: 1, height: 4)
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .frame(height: 30)
    }
    
    // MARK: - Distance View
    private func distanceView(distance: String) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(distance)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.black)
                Text("km")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.black)
                    .offset(y: -10)
            }
        }
    }
    
    // MARK: - Timer View
    private func timerView(time: String) -> some View {
        Text(time)
            .font(.system(size: 48, weight: .light))
            .foregroundColor(.black)
            .tracking(2)
    }
    
    // MARK: - Heart Rate View
    private func heartRateView(heartRate: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(heartRate)")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.black)
            Text("bpm")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.black)
                .offset(y: -5)
        }
    }
    
    // MARK: - Control Button
    private func controlButton(
        isPaused: Bool,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Circle()
                .fill(getButtonColor(isPaused: isPaused, isActive: isActive))
                .frame(width: 120, height: 120)
                .overlay(
                    Text(getButtonText(isPaused: isPaused, isActive: isActive))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                )
        }
    }
    
    private func getButtonColor(isPaused: Bool, isActive: Bool) -> Color {
        if !isActive {
            return .green
        } else if isPaused {
            return .green
        } else {
            return .orange
        }
    }
    
    private func getButtonText(isPaused: Bool, isActive: Bool) -> String {
        if !isActive {
            return "Start"
        } else if isPaused {
            return "Resume"
        } else {
            return "Pause"
        }
    }
    
    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        HStack {
            // 홈 인디케이터 (노란색 원)
            Circle()
                .fill(.yellow)
                .frame(width: 40, height: 40)
            
            Spacer()
            
            // 러닝 아이콘 (파란색)
            Image(systemName: "figure.run")
                .font(.system(size: 24))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }
}

#Preview {
    RunningView(
        store: Store(initialState: RunningFeature.State()) {
            RunningFeature()
        }
    )
} 