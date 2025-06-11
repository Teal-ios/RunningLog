//
//  Design.swift
//  RunningLog
//
//  Created by Den on 5/26/25.
//

import SwiftUI

enum DesignSystem {
    enum Font: String {
        case nanumSquareLight = "NanumSquareNeo-aLt"
    }
}

extension Font {
    static let nanumLight16: Font = .custom(DesignSystem.Font.nanumSquareLight.rawValue, size: 16)
}

struct RLColor {
    static let primary = Color(red: 52/255, green: 116/255, blue: 181/255)    // 포레스트 그린
    static let secondary = Color(red: 87/255, green: 143/255, blue: 202/255)  // 스카이 블루
    static let accent = Color(red: 161/255, green: 227/255, blue: 249/255)     // 선셋 오렌지
    static let white = Color(red: 209/255, green: 248/255, blue: 239/255)     // 선셋 오렌지
}
