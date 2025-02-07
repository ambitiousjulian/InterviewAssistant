//
//  CTAView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 2/6/25.
//
import SwiftUI

struct CTAView: View {
    @State private var showLoginView = false
    @State private var isAnimating = false
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            ScrollView {
                VStack(spacing: 40) {
                    // Header Section
                    headerSection
                        .offset(y: isAnimating ? 0 : -30)
                    
                    // Features Section
                    featuresSection
                        .offset(y: isAnimating ? 0 : 30)
                    
                    // Benefits Section
                    benefitsSection
                        .offset(y: isAnimating ? 0 : 60)
                    
                    // Call to Action Button
                    ctaButton
                        .offset(y: isAnimating ? 0 : 90)
                }
                .padding()
                .opacity(isAnimating ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                isAnimating = true
            }
        }
        .sheet(isPresented: $showLoginView) {
            LoginView()
                .environmentObject(viewModel)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
                .symbolEffect(.bounce, options: .repeating)
            
            Text("Master Your\nInterview Game")
                .font(.system(size: 40, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Text("AI-Powered Interview Preparation\nTailored to Your Experience")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.top, 40)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 20) {
            FeatureRow(icon: "wand.and.stars.inverse", title: "Personalized AI Coaching", description: "Upload your resume for custom-tailored interview preparation")
            FeatureRow(icon: "person.2.wave.2", title: "Real-time Practice", description: "Interactive mock interviews with instant feedback")
            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Skill Analytics", description: "Track your progress and identify improvement areas")
        }
    }
    
    private var benefitsSection: some View {
        VStack(spacing: 25) {
            Text("Why Choose Next Job AI?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                BenefitCard(number: "01", title: "Smart Analysis", description: "AI analyzes your experience")
                BenefitCard(number: "02", title: "Custom Path", description: "Personalized learning journey")
            }
            
            HStack(spacing: 20) {
                BenefitCard(number: "03", title: "Real Practice", description: "Industry-specific scenarios")
                BenefitCard(number: "04", title: "Expert Tips", description: "Professional insights")
            }
        }
    }
    
    private var ctaButton: some View {
        Button(action: {
            showLoginView = true
        }) {
            HStack {
                Text("Get Started Free")
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right.circle.fill")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primary.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: AppTheme.primary.opacity(0.5), radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 20)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppTheme.primary)
                .frame(width: 50, height: 50)
                .background(.white)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct BenefitCard: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(number)
                .font(.caption)
                .foregroundColor(AppTheme.primary)
                .padding(8)
                .background(.white)
                .cornerRadius(8)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}
