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
            // ... (기존 데이터 유지)
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
        // View에서 발생 (페이지 전환 요청)
        case nextButtonTapped
        case pageChanged(Int) // TabView의 Binding을 위한 액션 추가
        
        // 상위 Feature(Root)로 전달할 액션
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case completeOnboarding
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .pageChanged(let page):
                state.currentPage = page
                return .none
                
            case .nextButtonTapped:
                if state.currentPage < state.onboardingData.count - 1 {
                    // 다음 페이지로 이동
                    state.currentPage += 1
                    return .none
                } else {
                    // 온보딩 완료 시 Delegate 액션 전송
                    return .send(.delegate(.completeOnboarding))
                }
            
            case .delegate:
                return .none
            }
        }
    }
}
