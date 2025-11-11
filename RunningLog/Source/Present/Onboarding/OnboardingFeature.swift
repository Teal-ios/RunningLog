//
//  OnboardingFeature.swift
//  RunningLog
//
//  Created by Den on 11/11/25.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct OnboardingFeature: Reducer {
    
    struct State: Equatable {
        var onboardingData: [OnboardingData] = [
            OnboardingData(
                iconName: "waveform.path.ecg",
                title: "러닝을 기록하세요",
                description: "GPS를 통해 실시간으로 러닝 경로와 데이터를 추적합니다",
                iconColor: Color.mainColor
            ),
            OnboardingData(
                iconName: "location.fill",
                title: "목표를 달성하세요",
                description: "주간, 월간 목표를 설정하고 달성률을 확인하세요",
                iconColor: Color.mainColor
            ),
            OnboardingData(
                iconName: "location.fill",
                title: "로컬에 안전하게 저장",
                description: "모든 데이터는 기기에만 저장되어 안전하게 보호됩니다",
                iconColor: Color.mainColor
            )
        ]
        
        var currentPage = 0
    }
    
    enum Action: Equatable {
        case nextButtonTapped(page: Int)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .nextButtonTapped(page):
                if state.currentPage < state.onboardingData.count - 1 {
                    state.currentPage += 1
                }
                return .none
            }
        }
    }
}
