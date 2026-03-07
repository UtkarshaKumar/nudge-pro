import SwiftUI

struct LinearButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case ghost
        case destructive
    }
    
    init(
        title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(title)
                    .font(.button)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(background)
            .cornerRadius(CornerRadius.button)
        }
        .buttonStyle(.plain)
    }
    
    private var background: some View {
        Group {
            switch style {
            case .primary:
                LinearGradient(
                    colors: [.accentPrimary, .accentSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case .secondary:
                Color.surface
            case .ghost:
                Color.clear
            case .destructive:
                Color.error
            }
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .textPrimary
        case .ghost:
            return .accentPrimary
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        LinearButton(title: "Get Started", icon: "arrow.right", style: .primary) {}
        LinearButton(title: "Learn More", icon: "info.circle", style: .secondary) {}
        LinearButton(title: "Skip", style: .ghost) {}
        LinearButton(title: "Delete", icon: "trash", style: .destructive) {}
    }
    .padding(32)
    .background(Color.background)
}
