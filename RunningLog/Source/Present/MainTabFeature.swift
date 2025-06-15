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
        var selectedTab: Tab = .running
        var weatherState = WeatherFeature.State()
        var runningState = RunningFeature.State()
        var runningRecordList = RunningRecordListFeature.State()
    }
    
    enum Tab: CaseIterable {
        case weather
        case running
        case record
        
        var title: String {
            switch self {
            case .weather:
                return "날씨"
            case .running:
                return "러닝"
            case .record:
                return "기록"
            }
        }
        
        var systemImage: String {
            switch self {
            case .weather:
                return "cloud.sun"
            case .running:
                return "figure.run"
            case .record:
                return "list.bullet"
            }
        }
    }
    
    enum Action {
        case tabSelected(Tab)
        case weather(WeatherFeature.Action)
        case running(RunningFeature.Action)
        case runningRecordList(RunningRecordListFeature.Action)
        case selectTab(Tab)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.weatherState, action: \.weather) {
            WeatherFeature()
        }
        
        Scope(state: \.runningState, action: \.running) {
            RunningFeature()
        }
        
        Scope(state: \.runningRecordList, action: /Action.runningRecordList) {
            RunningRecordListFeature()
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
            case .runningRecordList:
                return .none
            case .selectTab:
                return .none
            }
        }
    }
} 
