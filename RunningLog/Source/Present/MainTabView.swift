//
//  MainTabView.swift
//  RunningLog
//
//  Created by Den on 5/26/25.
//

import SwiftUI
import ComposableArchitecture
import RunningLog

struct MainTabView: View {
    let store: StoreOf<MainTabFeature>
    
    var body: some View {
        WithViewStore(store, observe: \.selectedTab) { viewStore in
            TabView(selection: viewStore.binding(
                send: MainTabFeature.Action.tabSelected
            )) {
                // 날씨 탭
                WeatherView(
                    store: store.scope(
                        state: \.weatherState,
                        action: \.weather
                    )
                )
                .tabItem {
                    Label(
                        MainTabFeature.Tab.weather.title,
                        systemImage: MainTabFeature.Tab.weather.systemImage
                    )
                }
                .tag(MainTabFeature.Tab.weather)
                
                // 러닝 탭
                RunningView(
                    store: store.scope(
                        state: \.runningState,
                        action: \.running
                    )
                )
                .tabItem {
                    Label(
                        MainTabFeature.Tab.running.title,
                        systemImage: MainTabFeature.Tab.running.systemImage
                    )
                }
                .tag(MainTabFeature.Tab.running)
                
                // 지도 탭
                MapView(
                    store: store.scope(
                        state: \.mapState,
                        action: \.map
                    )
                )
                .tabItem {
                    Label(
                        MainTabFeature.Tab.map.title,
                        systemImage: MainTabFeature.Tab.map.systemImage
                    )
                }
                .tag(MainTabFeature.Tab.map)
                
                // 기록 탭
                RunningRecordListView(store: store.scope(state: \ .runningRecordList, action: MainTabFeature.Action.runningRecordList))
                    .tabItem {
                        Label("기록", systemImage: "list.bullet")
                    }
                    .tag(MainTabFeature.Tab.record)
            }
            .accentColor(.blue)
        }
    }
}

#Preview {
    MainTabView(
        store: Store(initialState: MainTabFeature.State()) {
            MainTabFeature()
        }
    )
} 