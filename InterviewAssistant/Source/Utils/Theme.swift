import SwiftUI
// First, update AppTheme.swift with more vibrant colors
struct AppTheme {
    // Modern, vibrant color palette
    static let primary = Color(hex: "#FF6B6B") // Vibrant coral
    static let secondary = Color(hex: "#4ECDC4") // Turquoise
    static let accent = Color(hex: "#FFE66D") // Sunny yellow
    static let purple = Color(hex: "#6C5CE7") // Electric purple
    static let background = Color(hex: "#F7F7F7")
    static let surface = Color(hex: "#FFFFFF")
    static let text = Color(hex: "#2D3436")
    
    // Gradients
    static let gradient = LinearGradient(
        colors: [
            Color(hex: "#FF6B6B"),
            Color(hex: "#4ECDC4")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [
            Color(hex: "#6C5CE7"),
            Color(hex: "#45AAF2")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Shadows
    static let shadowLight = Color.black.opacity(0.1)
    static let shadowMedium = Color.black.opacity(0.15)
    
    // Helper method for hex colors
    static func color(_ hex: String) -> Color {
        Color(hex: hex)
    }
}

// Add this extension for hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
