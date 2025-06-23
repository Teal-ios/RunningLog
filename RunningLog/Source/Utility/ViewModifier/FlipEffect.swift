import SwiftUI

// 3D Flip 효과 Modifier (iOS 16+)
struct FlipEffect: ViewModifier {
    let angle: Double
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
            .animation(.easeInOut(duration: 0.5), value: angle)
    }
} 