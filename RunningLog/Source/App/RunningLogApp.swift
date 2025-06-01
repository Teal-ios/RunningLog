//
//  RunningLogApp.swift
//  RunningLog
//
//  Created by Den on 5/22/25.
//

import SwiftUI
import ComposableArchitecture

@main
struct RunningLogApp: App {
    var body: some Scene {
        WindowGroup {
            WeatherView(
                 store: Store(initialState: WeatherFeature.State()) {
                     WeatherFeature()
                 }
             )
        }
    }
}
