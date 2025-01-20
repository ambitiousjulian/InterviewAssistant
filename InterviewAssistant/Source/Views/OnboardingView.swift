//
//  OnboardingView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/19/25.
//

import SwiftUI


struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var showResumeInput = false
    
    let steps = [
        OnboardingStep(
            title: "Welcome to Next Job AI",
            subtitle: "Your personal interview preparation assistant",
            image: "wand.and.stars.inverse",
            color: AppTheme.primary
        ),
        OnboardingStep(
            title: "Personalized Responses",
            subtitle: "Upload your resume to get tailored interview answers",
            image: "doc.text.viewfinder",
            color: AppTheme.secondary
        ),
        OnboardingStep(
            title: "Practice Makes Perfect",
            subtitle: "Practice with AI-powered mock interviews",
            image: "person.2.wave.2",
            color: AppTheme.purple
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    steps[currentStep].color.opacity(0.2),
                    steps[currentStep].color.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Image
                Image(systemName: steps[currentStep].image)
                    .font(.system(size: 100))
                    .foregroundColor(steps[currentStep].color)
                    .symbolEffect(.bounce)
                    .padding()
                    .background(
                        Circle()
                            .fill(steps[currentStep].color.opacity(0.1))
                            .frame(width: 180, height: 180)
                    )
                
                // Text content
                VStack(spacing: 12) {
                    Text(steps[currentStep].title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(steps[currentStep].subtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(currentStep == index ? steps[currentStep].color : .gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom)
                
                // Action button
                Button(action: handleAction) {
                    Text(currentStep == steps.count - 1 ? "Get Started" : "Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(steps[currentStep].color)
                        .cornerRadius(15)
                        .shadow(color: steps[currentStep].color.opacity(0.5), radius: 10)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showResumeInput) {
            ResumeInputView(viewModel: ProfileViewModel())
        }
        .transition(.opacity)
    }
    
    private func handleAction() {
        withAnimation {
            if currentStep < steps.count - 1 {
                currentStep += 1
            } else {
                authViewModel.completeOnboarding() // This will handle everything
            }
        }
    }
}

struct OnboardingStep {
    let title: String
    let subtitle: String
    let image: String
    let color: Color
}
