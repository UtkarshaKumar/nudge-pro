import SwiftUI

/// Design tokens for consistent styling
enum DesignTokens {
    enum Icons {
        static let record = "record.circle"
        static let calendar = "calendar"
        static let search = "magnifyingglass"
        static let meeting = "person.3"
        static let transcript = "doc.text"
        static let ai = "cpu"
        static let info = "info.circle"
    }

    enum Colors {
        static let background = Color(NSColor.windowBackgroundColor)
        static let text = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color.gray
        static let surface = Color(NSColor.controlBackgroundColor)
        static let accent = Color.accentColor
        static let warning = Color.orange
        static let success = Color.green
        static let secondaryBackground = Color(NSColor.unemphasizedSelectedContentBackgroundColor)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title = Font.system(size: 22, weight: .bold)
        static let title2 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 13, weight: .regular)
        static let callout = Font.system(size: 13, weight: .regular)
        static let subheadline = Font.system(size: 13, weight: .regular)
        static let footnote = Font.system(size: 12, weight: .regular)
        static let caption1 = Font.system(size: 11, weight: .regular)
        static let caption2 = Font.system(size: 10, weight: .regular)
        
        // Backward compatible aliases
        static let caption = caption1
    }

    enum CornerRadius {
        static let card: CGFloat = 12
        static let input: CGFloat = 6
    }
}
