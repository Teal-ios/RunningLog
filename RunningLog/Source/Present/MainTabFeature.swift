//
//  MainTabFeature.swift
//  RunningLog
//
//  Created by Den on 5/26/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .weather
        var weatherState = WeatherFeature.State()
        var runningState = RunningFeature.State()
    }
    
    enum Tab: CaseIterable {
        case weather
        case running
        
        var title: String {
            switch self {
            case .weather:
                return "날씨"
            case .running:
                return "러닝"
            }
        }
        
        var systemImage: String {
            switch self {
            case .weather:
                return "cloud.sun"
            case .running:
                return "figure.run"
            }
        }
    }
    
    enum Action {
        case tabSelected(Tab)
        case weather(WeatherFeature.Action)
        case running(RunningFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.weatherState, action: \.weather) {
            WeatherFeature()
        }
        
        Scope(state: \.runningState, action: \.running) {
            RunningFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .weather:
                return .none
                
            case .running:
                return .none
            }
        }
    }
} 