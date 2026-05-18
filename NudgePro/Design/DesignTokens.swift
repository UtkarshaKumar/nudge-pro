import SwiftUI

/// Compatibility aliases for the Theme design system.
/// All values match Theme.swift. Prefer Theme's top-level types directly.
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

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Colors {
        static let text: Color = .textPrimary
        static let textSecondary: Color = .textSecondary
        static let textTertiary: Color = .textTertiary
        static let background: Color = .background
        static let surface: Color = .surface
        static let accent: Color = .accentPrimary
        static let warning: Color = .warning
        static let success: Color = .success
        static let secondaryBackground: Color = .backgroundSecondary
    }

    enum Typography {
        static let largeTitle = Font.appTitle
        static let title = Font.screenTitle
        static let title2 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.sectionHeader
        static let body = Font.body
        static let callout = Font.body
        static let subheadline = Font.body
        static let footnote = Font.bodySmall
        static let caption1 = Font.caption
        static let caption2 = Font.system(size: 10)
        static let caption = Font.caption
    }

    enum CornerRadius {
        static let card: CGFloat = 12
        static let input: CGFloat = 6
        static let button: CGFloat = 8
        static let modal: CGFloat = 16
    }
}
