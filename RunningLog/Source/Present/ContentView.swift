//
//  ContentView.swift
//  RunningLog
//
//  Created by Den on 5/22/25.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    var body: some View {
        MainTabView(
            store: Store(initialState: MainTabFeature.State()) {
                MainTabFeature()
                }
        )
    }
}

#Preview {
    ContentView()
}
