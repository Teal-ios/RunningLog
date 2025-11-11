//
//  OnboardingData.swift
//  RunningLog
//
//  Created by Den on 11/11/25.
//

import Foundation

struct OnboardingData: Identifiable {
    let id = UUID()
    let iconName: String
    let title: String
    let description: String
    let iconColor: Color
}
