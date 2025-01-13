// Source/Utils/AppTheme.swift
import SwiftUI

struct AppTheme {
    // Colors
    static let primary = Color("PrimaryTeal")
    static let secondary = Color("SecondaryBlue")
    static let accent = Color("AccentPurple") // New accent color
    static let background = Color.white
    static let surface = Color("SurfaceGray") // New surface color
    static let text = Color("TextColor")
    
    // Gradients
    static let gradient = LinearGradient(
        colors: [primary.opacity(0.9), secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Shadows
    static let shadowLight = Color.black.opacity(0.1)
    static let shadowMedium = Color.black.opacity(0.15)
    
    // Common styles
    static func cardStyle<S: Shape>(_ shape: S) -> some View {
        shape
            .fill(Color.white)
            .shadow(color: shadowLight, radius: 15, x: 0, y: 5)
    }
    
    static let buttonStyle = AnyShapeStyle(
        LinearGradient(
            colors: [primary, primary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
