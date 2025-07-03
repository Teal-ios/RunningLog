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
                return NSLocalizedString("tab_weather", comment: "")
            case .running:
                return NSLocalizedString("tab_running", comment: "")
            case .record:
                return NSLocalizedString("tab_record", comment: "")
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
                
            case .running(.delegate(let delegateAction)):
                switch delegateAction {
                case .runningDidEnd:
                    return .send(.runningRecordList(.loadRecords))
                }
                
            case .weather, .running, .runningRecordList:
                return .none
            case .selectTab:
                return .none
            }
        }
    }
} 
