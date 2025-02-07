import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                AuthenticatedProfileView()
            } else {
                ProfileCTAView()
            }
        }
    }
}

struct ProfileCTAView: View {
    @State private var isAnimating = false
    @State private var showLoginView = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // Header
                        headerSection
                            .offset(y: isAnimating ? 0 : -30)
                        
                        // Features
                        featuresSection
                            .offset(y: isAnimating ? 0 : 30)
                        
                        // Call to Action
                        ctaSection
                            .offset(y: isAnimating ? 0 : 60)
                    }
                    .padding()
                    .opacity(isAnimating ? 1 : 0)
                }
            }
            .sheet(isPresented: $showLoginView) {
                LoginView()
                    .environmentObject(authViewModel)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.shield.checkmark.fill")
                .font(.system(size: 70))
                .foregroundColor(AppTheme.primary)
                .symbolEffect(.bounce, options: .repeating)
            
            Text("Unlock Personalized\nInterview Preparation")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.text)
            
            Text("Upload your resume and let AI tailor your interview experience")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.text.opacity(0.7))
        }
        .padding(.vertical)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 25) {
            FeatureCard(
                icon: "doc.text.magnifyingglass",
                title: "Smart Resume Analysis",
                description: "Get personalized interview questions based on your experience"
            )
            
            FeatureCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Progress Tracking",
                description: "Monitor your improvement and get targeted suggestions"
            )
            
            FeatureCard(
                icon: "briefcase.fill",
                title: "Industry-Specific Practice",
                description: "Practice with questions tailored to your field"
            )
        }
    }
    
    private var ctaSection: some View {
        VStack(spacing: 20) {
            Button(action: {
                showLoginView = true
            }) {
                HStack {
                    Text("Get Started")
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
            
            Text("Create a free account to unlock all features")
                .font(.footnote)
                .foregroundColor(AppTheme.text.opacity(0.7))
        }
        .padding(.vertical)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
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
                    .lineLimit(2)
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(15)
        .shadow(color: AppTheme.shadowLight, radius: 5)
    }
}
