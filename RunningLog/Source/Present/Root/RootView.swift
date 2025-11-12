//
//  RootView.swift
//  RunningLog
//
//  Created by Den on 11/12/25.
//


import SwiftUI
import ComposableArchitecture

struct RootView: View {
    let store: StoreOf<RootFeature>
    
    var body: some View {
        ZStack {
            if store.isFirstLaunchDetermined && store.isStoreLoaded {
                IfLetStore(store.scope(state: \.onboarding, action: \.onboarding)) { store in
                    OnboardingView(store: store)
                }
                
                IfLetStore(store.scope(state: \.mainTab, action: \.mainTab)) { store in
                    MainTabView(store: store)
                }
            } else {
                VStack {
                    Spacer()
                    ProgressView("loading_database")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                    Spacer()
                }
            }
        }
        .onAppear {
            store.send(.loadStore)
            store.send(.loadInitialState)
        }
    }
}
