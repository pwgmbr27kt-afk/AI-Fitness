import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary accent
    static let apexCyan       = Color(hex: "#00D4FF")
    static let apexBlue       = Color(hex: "#007AFF")
    static let apexPurple     = Color(hex: "#9B59B6")

    // Status colors
    static let apexGreen      = Color(hex: "#4CAF50")
    static let apexOrange     = Color(hex: "#FF9800")
    static let apexRed        = Color(hex: "#F44336")
    static let apexYellow     = Color(hex: "#FFD700")

    // Background layers
    static let apexBackground = Color(hex: "#0A0A0F")
    static let apexSurface    = Color(hex: "#12121A")
    static let apexCard       = Color(hex: "#1A1A28")
    static let apexBorder     = Color.white.opacity(0.08)

    // Text
    static let apexTextPrimary   = Color.white
    static let apexTextSecondary = Color.white.opacity(0.6)
    static let apexTextTertiary  = Color.white.opacity(0.35)

    // Gradient helpers
    static let apexAccentGradient = LinearGradient(
        colors: [.apexCyan, .apexBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let apexDarkGradient = LinearGradient(
        colors: [Color(hex: "#0A0A0F"), Color(hex: "#12121A")],
        startPoint: .top,
        endPoint: .bottom
    )

    // Hex initialiser
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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
    static let apexLargeTitle  = Font.system(size: 34, weight: .bold,   design: .rounded)
    static let apexTitle       = Font.system(size: 24, weight: .bold,   design: .rounded)
    static let apexTitle2      = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let apexHeadline    = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let apexBody        = Font.system(size: 15, weight: .regular, design: .rounded)
    static let apexCallout     = Font.system(size: 13, weight: .medium,  design: .rounded)
    static let apexCaption     = Font.system(size: 11, weight: .regular, design: .rounded)
    static let apexNumber      = Font.system(size: 28, weight: .bold,   design: .monospaced)
}

// MARK: - Spacing
enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum Radius {
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 28
    static let pill: CGFloat = 100
}

// MARK: - ShapeStyle extensions (enables .foregroundStyle(.apexCyan) etc.)
extension ShapeStyle where Self == Color {
    static var apexCyan:          Color { .apexCyan }
    static var apexBlue:          Color { .apexBlue }
    static var apexPurple:        Color { .apexPurple }
    static var apexGreen:         Color { .apexGreen }
    static var apexOrange:        Color { .apexOrange }
    static var apexRed:           Color { .apexRed }
    static var apexYellow:        Color { .apexYellow }
    static var apexBackground:    Color { .apexBackground }
    static var apexSurface:       Color { .apexSurface }
    static var apexCard:          Color { .apexCard }
    static var apexTextPrimary:   Color { .apexTextPrimary }
    static var apexTextSecondary: Color { .apexTextSecondary }
    static var apexTextTertiary:  Color { .apexTextTertiary }
}

extension ShapeStyle where Self == LinearGradient {
    static var apexAccentGradient: LinearGradient { .init(colors: [.apexCyan, .apexBlue], startPoint: .topLeading, endPoint: .bottomTrailing) }
    static var apexDarkGradient:   LinearGradient { .init(colors: [Color(hex: "#0A0A0F"), Color(hex: "#12121A")], startPoint: .top, endPoint: .bottom) }
}

// MARK: - Shadow
extension View {
    func apexShadow(color: Color = .apexCyan, radius: CGFloat = 20) -> some View {
        self.shadow(color: color.opacity(0.2), radius: radius, x: 0, y: 8)
    }

    func glowEffect(color: Color = .apexCyan, radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
}
