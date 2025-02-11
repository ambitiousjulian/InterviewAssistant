//
//  SubscriptionView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 2/11/25.
//

import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    AppTheme.primary.opacity(0.1),
                    AppTheme.secondary.opacity(0.1),
                    AppTheme.accent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    headerSection
                        .offset(y: isAnimating ? 0 : -30)
                    
                    // Features
                    featuresSection
                        .offset(y: isAnimating ? 0 : 30)
                    
                    // Pricing
                    pricingSection
                        .offset(y: isAnimating ? 0 : 60)
                    
                    // CTA Buttons
                    buttonsSection
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
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce)
            
            Text("Unlock Premium")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppTheme.text)
            
            Text("Take Your Interview Prep to the Next Level")
                .font(.title3)
                .foregroundColor(AppTheme.text.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 20) {
            FeatureRowSub(
                icon: "infinity.circle.fill",
                title: "Unlimited Interviews",
                description: "Practice as much as you want"
            )
            
            FeatureRowSub(
                icon: "brain.head.profile",
                title: "Advanced AI Analysis",
                description: "Get detailed feedback and insights"
            )
            
            FeatureRowSub(
                icon: "chart.line.uptrend.xyaxis.circle.fill",
                title: "Progress Tracking",
                description: "Monitor your improvement over time"
            )
            
            FeatureRowSub(
                icon: "person.2.circle.fill",
                title: "Industry-Specific",
                description: "Tailored to your field"
            )
        }
    }
    
    private var pricingSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 5) {
                Text("$3.99")
                    .font(.system(size: 40, weight: .bold))
                Text("/month")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            if subscriptionManager.freeInterviewsRemaining > 0 {
                Text("\(subscriptionManager.freeInterviewsRemaining) free interviews remaining")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondary)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 12)
                    .background(AppTheme.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical)
    }
    
    private var buttonsSection: some View {
        VStack(spacing: 15) {
            Button(action: {
                subscriptionManager.isSubscribed = true
                dismiss()
            }) {
                HStack {
                    Text("Start Premium")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right.circle.fill")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 10)
            }
            
            Button(action: { dismiss() }) {
                Text("Continue with Limited Access")
                    .foregroundColor(AppTheme.text.opacity(0.6))
                    .padding()
            }
            
            Text("Cancel anytime. Subscription auto-renews monthly.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top)
        }
    }
}

struct FeatureRowSub: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(AppTheme.primary)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(AppTheme.primary.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.text.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(color: AppTheme.shadowLight, radius: 5)
    }
}
