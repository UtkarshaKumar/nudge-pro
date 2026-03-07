import SwiftUI

struct LinearCard<Content: View>: View {
    let content: Content
    let isSelected: Bool
    
    init(isSelected: Bool = false, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isSelected = isSelected
    }
    
    var body: some View {
        content
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .fill(Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(
                        isSelected ? Color.accentPrimary : Color.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
    }
}

#Preview {
    VStack(spacing: 16) {
        LinearCard {
            Text("Default card")
                .foregroundColor(.textPrimary)
        }
        
        LinearCard(isSelected: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected card")
                    .font(.sectionHeader)
                    .foregroundColor(.textPrimary)
                Text("This is a selected state")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
        }
    }
    .padding(32)
    .background(Color.background)
}
