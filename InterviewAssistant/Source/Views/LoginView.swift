import SwiftUI
import FirebaseAuth

// Complete LoginView
struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isAnimating = false
    @State private var showEULA = false
    @State private var hasAgreedToEULA = false
    
    var body: some View {
        ZStack {
            // Animated Background
            AnimatedGradientBackground()
        
            ScrollView {
                VStack(spacing: 30) {
                    welcomeSection
                        .offset(y: isAnimating ? 0 : -50)
                        .opacity(isAnimating ? 1 : 0)
                    
                    VStack(spacing: 25) {
                        inputSection
                        actionButtons
                        developmentButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 30)
                    .background(
                        Color.white.opacity(0.9)
                            .background(AppTheme.surface)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10)
                    .offset(y: isAnimating ? 0 : 50)
                    .opacity(isAnimating ? 1 : 0)
                }
                .padding()
            }
        }
        .alert("Authentication", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if isLoading {
                LoadingView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                isAnimating = true
            }
        }
        .sheet(isPresented: $showEULA) {
            EULAView(hasAgreed: $hasAgreedToEULA) {
                Task {
                    do {
                        isLoading = true
                        try await viewModel.signUp(email: email, password: password)
                    } catch {
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                    isLoading = false
                }
            }
            .interactiveDismissDisabled() // Prevents dismissal by swipe
        }
    }
    
    private var welcomeSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.badge.shield.checkmark.fill")
                .font(.system(size: 70, weight: .light))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, options: .repeating)
            
            Text(isRegistering ? "Create Account" : "Next Job AI")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 40)
    }
    
    private var inputSection: some View {
        VStack(spacing: 20) {
            ModernTextField(text: $email,
                          placeholder: "Email",
                          icon: "envelope.fill")
            
            ModernTextField(text: $password,
                          placeholder: "Password",
                          icon: "lock.fill",
                          isSecure: true)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            Button(action: handleAuthentication) {
                HStack {
                    Text(isRegistering ? "Create Account" : "Sign In")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
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
                .shadow(color: AppTheme.primary.opacity(0.5),
                       radius: 10, x: 0, y: 5)
            }
            
            Button(action: {
                withAnimation(.spring()) {
                    isRegistering.toggle()
                }
            }) {
                Text(isRegistering ? "Already have an account?" : "Need an account?")
                    .foregroundColor(AppTheme.secondary)
                    .fontWeight(.medium)
            }
        }
    }
    
    @ViewBuilder
    private var developmentButtons: some View {
        #if DEBUG
        VStack {
            Divider()
                .background(AppTheme.secondary.opacity(0.3))
                .padding(.vertical)
            
            Button("Quick Dev Login") {
                isLoading = true
                email = "test@test.com"
                password = "password123"
                createDevAccountIfNeeded()
            }
            .foregroundColor(AppTheme.secondary)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(10)
        }
        #endif
    }
    
    private func handleAuthResult(_ result: AuthDataResult?, _ error: Error?) {
        isLoading = false
        if let error = error {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func handleAuthentication() {
        if isRegistering && !hasAgreedToEULA {
            showEULA = true
            return
        }
        Task {
            do {
                isLoading = true
                if isRegistering {
                    try await viewModel.signUp(email: email, password: password)
                } else {
                    try await viewModel.signIn(email: email, password: password)
                }
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
            isLoading = false
        }
    }

    private func createDevAccountIfNeeded() {
        Task {
            do {
                try await viewModel.signUp(email: email, password: password)
            } catch {
                // Account might exist, try signing in
                do {
                    try await viewModel.signIn(email: email, password: password)
                } catch {
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
            isLoading = false
        }
    }
}

// Supporting Views
struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primary)
                .frame(width: 40)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 15) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("Please wait...")
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
}

// Preview Provider
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
