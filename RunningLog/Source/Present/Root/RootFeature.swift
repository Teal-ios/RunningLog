//
//  RootFeature.swift
//  RunningLog
//
//  Created by Den on 11/12/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct RootFeature {
    @ObservableState
    struct State: Equatable {
        var mainTab: MainTabFeature.State?
        var onboarding: OnboardingFeature.State?
        
        var isStoreLoaded: Bool = false
        var isFirstLaunchDetermined: Bool = false
        
        init() {}
    }
    
    enum Action {
        case loadInitialState
        case initialLoadFinished(isFirstLaunch: Bool)
        
        case loadStore
        case storeLoaded
        
        case onboarding(OnboardingFeature.Action)
        case mainTab(MainTabFeature.Action)
    }
    
    @Dependency(\.userDefaults) var userDefaultsClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadInitialState:
                return .run { send in
                    let isFirst = try await userDefaultsClient.load(forKey: "firstLaunch") as Bool?
                    await send(.initialLoadFinished(isFirstLaunch: isFirst ?? true))
                }
            
            case let .initialLoadFinished(isFirstLaunch):
                guard !state.isFirstLaunchDetermined else { return .none }
                state.isFirstLaunchDetermined = true
                
                if isFirstLaunch {
                    state.onboarding = OnboardingFeature.State()
                } else {
                    state.mainTab = MainTabFeature.State()
                }
                return .none

            case .loadStore:
                if PersistenceController.shared.isStoreLoaded {
                    return .send(.storeLoaded)
                }
                
                return .run { send in
                    await withTaskCancellation(id: "StoreLoading", cancelInFlight: true) {
                        for await _ in NotificationCenter.default.notifications(named: PersistenceController.storeLoadedNotification) {
                            await send(.storeLoaded)
                            break
                        }
                    }
                }
                
            case .storeLoaded:
                state.isStoreLoaded = true
                return .none
                
            case .onboarding(.delegate(.completeOnboarding)):
                state.onboarding = nil
                state.mainTab = MainTabFeature.State()
                return .run { _ in
                    try await userDefaultsClient.save(false, forKey: "firstLaunch")
                }
                
            case .onboarding, .mainTab:
                return .none
            }
        }
        .ifLet(\.onboarding, action: /Action.onboarding) {
            OnboardingFeature()
        }
        .ifLet(\.mainTab, action: /Action.mainTab) {
            MainTabFeature()
        }
    }
}
