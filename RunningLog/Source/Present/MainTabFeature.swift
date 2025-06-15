//
//  MainTabFeature.swift
//  RunningLog
//
//  Created by Den on 5/26/25.
//

import Foundation
import ComposableArchitecture
import RunningLog

@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .running
        var weatherState = WeatherFeature.State()
        var runningState = RunningFeature.State()
        var mapState = MapFeature.State()
        var runningRecordList = RunningRecordListFeature.State()
    }
    
    enum Tab: CaseIterable {
        case weather
        case running
        case map
        case record
        
        var title: String {
            switch self {
            case .weather:
                return "날씨"
            case .running:
                return "러닝"
            case .map:
                return "지도"
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
            case .map:
                return "map"
            case .record:
                return "list.bullet"
            }
        }
    }
    
    enum Action {
        case tabSelected(Tab)
        case weather(WeatherFeature.Action)
        case running(RunningFeature.Action)
        case map(MapFeature.Action)
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
        
        Scope(state: \.mapState, action: \.map) {
            MapFeature()
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
            case .map:
                return .none
            case .runningRecordList:
                return .none
            case .selectTab:
                return .none
            }
        }
    }
} 
