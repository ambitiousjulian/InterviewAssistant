//
//  MockInterviewLoadingOverlay.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/15/25.
//
import SwiftUI


struct MockInterviewLoadingOverlay: View {
    @State private var isAnimating = false
    let message: String
    
    var body: some View {
        ZStack {
            // Blur background
            Color.black
                .opacity(0.4)
                .ignoresSafeArea()
            
            // Loading card
            VStack(spacing: 25) {
                // Animated icon
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 50, height: 50)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                }
                
                VStack(spacing: 12) {
                    Text("Preparing Interview")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.7))
                    .shadow(color: Color.white.opacity(0.1), radius: 10)
            )
            .transition(.scale.combined(with: .opacity))
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
