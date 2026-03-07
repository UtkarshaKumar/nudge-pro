import SwiftUI
import AppKit

// MARK: - Color Theme
extension Color {
    // Background - adapts to light/dark mode
    static var background: Color {
        Color(nsColor: NSColor.windowBackgroundColor)
    }
    static var backgroundSecondary: Color {
        Color(nsColor: NSColor.controlBackgroundColor)
    }
    static var surface: Color {
        Color(nsColor: NSColor.textBackgroundColor)
    }
    
    // Border
    static var border: Color {
        Color(nsColor: NSColor.separatorColor)
    }
    static var borderHover: Color {
        Color(nsColor: NSColor.unemphasizedSelectedContentBackgroundColor)
    }
    
    // Text - adapts to light/dark mode
    static var textPrimary: Color {
        Color(nsColor: NSColor.labelColor)
    }
    static var textSecondary: Color {
        Color(nsColor: NSColor.secondaryLabelColor)
    }
    static var textTertiary: Color {
        Color(nsColor: NSColor.tertiaryLabelColor)
    }
    
    // Accent
    static let accentPrimary = Color(hex: "8B5CF6")
    static let accentSecondary = Color(hex: "6366F1")
    
    // Semantic - these can stay as fixed colors
    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")
    static let recording = Color(hex: "F43F5E")
    
    // Gradient
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [.accentPrimary, .accentSecondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    static let appTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let screenTitle = Font.system(size: 24, weight: .semibold, design: .default)
    static let sectionHeader = Font.system(size: 18, weight: .semibold, design: .default)
    static let body = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    static let caption = Font.system(size: 11, weight: .regular, design: .default)
    static let button = Font.system(size: 14, weight: .medium, design: .default)
    static let mono = Font.system(size: 12, weight: .regular, design: .monospaced)
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum CornerRadius {
    static let button: CGFloat = 8
    static let card: CGFloat = 12
    static let modal: CGFloat = 16
    static let input: CGFloat = 6
}
