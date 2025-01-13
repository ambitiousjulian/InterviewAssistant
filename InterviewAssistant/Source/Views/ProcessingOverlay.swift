//
//  ProcessingOverlay.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//

import SwiftUI

struct ProcessingOverlay: View {
    @State private var isAnimating = false
    @State private var dotOpacity1 = false
    @State private var dotOpacity2 = false
    @State private var dotOpacity3 = false
    
    private let tips = [
        "Analyzing your question...",
        "Crafting professional response...",
        "Preparing key points...",
        "Structuring STAR format...",
        "Optimizing answer length..."
    ]
    
    @State private var currentTipIndex = 0
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 25) {
                // Animated Icon
                ZStack {
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 1)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    Image(systemName: "brain")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.primary)
                }
                
                // Status Text
                VStack(spacing: 12) {
                    Text(tips[currentTipIndex])
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .id(currentTipIndex) // Forces animation
                    
                    // Animated dots
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.white)
                            .frame(width: 6, height: 6)
                            .opacity(dotOpacity1 ? 1 : 0.3)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 6, height: 6)
                            .opacity(dotOpacity2 ? 1 : 0.3)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 6, height: 6)
                            .opacity(dotOpacity3 ? 1 : 0.3)
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(
                        colors: [.white.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Rotate loading indicator
        isAnimating = true
        
        // Animate dots
        withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
            dotOpacity1 = true
        }
        
        withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(0.2)) {
            dotOpacity2 = true
        }
        
        withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(0.4)) {
            dotOpacity3 = true
        }
        
        // Cycle through tips
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation {
                currentTipIndex = (currentTipIndex + 1) % tips.count
            }
        }
    }
}

// Preview
struct ProcessingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingOverlay()
    }
}
