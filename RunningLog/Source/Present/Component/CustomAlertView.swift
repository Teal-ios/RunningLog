import SwiftUI

// MARK: - 커스텀 Alert 뷰
struct CustomAlertView: View {
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Text(title)
                    .font(.title3).bold()
                    .foregroundColor(.primary)
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        Text(cancelTitle)
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 32)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut, value: 1)
    }
} 