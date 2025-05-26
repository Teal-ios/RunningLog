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
