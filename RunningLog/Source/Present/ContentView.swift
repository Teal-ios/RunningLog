//
//  ContentView.swift
//  RunningLog
//
//  Created by Den on 5/22/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Rectangle()
                .fill(RLColor.primary)
            Rectangle()
                .fill(RLColor.secondary)
            Rectangle()
                .fill(RLColor.accent)
            Rectangle()
                .fill(RLColor.white)
            Text("Hello, world!")
                .font(.nanumLight16)
        }
        .padding()
        .onAppear() {
            for fontFamily in UIFont.familyNames {
                for fontName in UIFont.fontNames(forFamilyName: fontFamily) {
                    print(fontName)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
