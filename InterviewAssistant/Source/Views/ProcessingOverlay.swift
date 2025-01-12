//
//  ProcessingOverlay.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//


import SwiftUI

// Processing Overlay
struct ProcessingOverlay: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false),
                             value: isAnimating)
                
                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
