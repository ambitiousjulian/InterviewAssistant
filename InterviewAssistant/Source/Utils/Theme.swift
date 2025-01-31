import SwiftUI
enum AppTheme {
    // Base Colors
    static let primary = Color(hex: "#4A90E2")
    static let secondary = Color(hex: "#7B68EE")
    static let accent = Color(hex: "#FF6B6B")
    static let purple = Color(hex: "#9B59B6")
    
    // Gradient Sets
    static let gradientStart = Color(hex: "#4A90E2")
    static let gradientEnd = Color(hex: "#7B68EE")
    static let gradientAccent = Color(hex: "#FF6B6B")
    
    // Text Colors
    static let text = Color(hex: "#2D3436")
    static let textSecondary = Color(hex: "#636E72")
    
    // Success/Error Colors
    static let successGreen = Color(hex: "#2ECC71")
    static let warningOrange = Color(hex: "#E67E22")
    static let errorRed = Color(hex: "#E74C3C")
    
    // Background Colors
    static let background = Color(hex: "#F5F6FA")
    static let surfaceLight = Color.white.opacity(0.95)
    
    // Shadow Colors
    static let shadowLight = Color.black.opacity(0.05)
    static let shadowMedium = Color.black.opacity(0.1)
    
    // Surface Colors
    static let surface = Color.white
    static let surfaceDark = Color(hex: "#F0F3F7")
    static let surfaceHighlight = Color.white.opacity(0.95)
    
    // If you're using these variations, add them too
    static let surfaceSecondary = Color(hex: "#F5F7FA")
    static let surfaceAccent = Color(hex: "#EDF2F7")
    static let surfaceInteractive = Color(hex: "#E2E8F0")
    
    // Gradient Presets
    static let primaryGradient = LinearGradient(
        colors: [gradientStart, gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [accent, purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [
            primary.opacity(0.1),
            secondary.opacity(0.1),
            accent.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Animation Durations
    static let quickAnimation: Double = 0.3
    static let standardAnimation: Double = 0.5
    static let slowAnimation: Double = 0.8
    
    // Dimensions
    static let cornerRadius: CGFloat = 15
    static let buttonHeight: CGFloat = 50
    static let iconSize: CGFloat = 24
    
    // Padding
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    
    // Custom ViewModifiers
    struct GlassBackground: ViewModifier {
        func body(content: Content) -> some View {
            content
                .background(
                    Color.white
                        .opacity(0.7)
                        .blur(radius: 0.5)
                )
                .background(
                    Color.white
                        .opacity(0.4)
                )
                .cornerRadius(AppTheme.cornerRadius)
        }
    }
    
    struct InteractiveScale: ViewModifier {
        @State private var isPressed = false
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isPressed ? 0.98 : 1)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPressed)
                .onTapGesture {
                    withAnimation {
                        isPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isPressed = false
                        }
                    }
                }
        }
    }
    
    struct FloatingAnimation: ViewModifier {
        @State private var isAnimating = false
        
        func body(content: Content) -> some View {
            content
                .offset(y: isAnimating ? -5 : 5)
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
        }
    }
}

// Extension for View modifiers
extension View {
    func glassBackground() -> some View {
        modifier(AppTheme.GlassBackground())
    }
    
    func interactiveScale() -> some View {
        modifier(AppTheme.InteractiveScale())
    }
    
    func floatingAnimation() -> some View {
        modifier(AppTheme.FloatingAnimation())
    }
}

// Helper for gradient text
extension View {
    func gradientForeground(colors: [Color]) -> some View {
        self.overlay(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .mask(self)
    }
}

// Helper for hex colors
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
