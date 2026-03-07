import SwiftUI

struct PrimaryButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [.accentPrimary, .accentSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(CornerRadius.button)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.surface)
            .cornerRadius(CornerRadius.button)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct GhostButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundColor(.accentPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}
