import SwiftUI

struct AppTheme {
    static let primary = Color("PrimaryTeal")
    static let secondary = Color("SecondaryBlue")
    static let background = Color("BackgroundColor")
    static let text = Color("TextColor")
    
    static let gradient = LinearGradient(
        colors: [primary.opacity(0.8), secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
