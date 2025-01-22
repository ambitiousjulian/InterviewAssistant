//
//  AnimatedGradientBackground.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//
// Source/Utils/AnimatedGradientBackground.swift
import SwiftUI

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.primary.opacity(0.8),
                    AppTheme.secondary.opacity(0.6),
                    AppTheme.accent.opacity(0.4)
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .animation(
                .easeInOut(duration: 5.0).repeatForever(autoreverses: true),
                value: animateGradient
            )
            
            WaveBackground()
        }
        .onAppear {
            animateGradient = true
        }
    }
}

// Preview Provider
struct AnimatedGradientBackground_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedGradientBackground()
    }
}
