//
//  ViewModifiers.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//
import SwiftUI

struct GlassomorphicBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Color.white.opacity(0.7)
                    .blur(radius: 0.5)
                    .background(.ultraThinMaterial)
            )
            .cornerRadius(20)
            .shadow(color: AppTheme.shadowLight, radius: 10)
    }
}

extension View {
    func glassomorphic() -> some View {
        modifier(GlassomorphicBackground())
    }
}
