import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            AppTheme.gradient
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                welcomeSection
                inputSection
                actionButtons
                developmentButtons
            }
            .padding()
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
        }
        .alert("Authentication", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var welcomeSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.badge.shield.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            Text(isRegistering ? "Create Account" : "Welcome Back")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.top, 50)
    }
    
    private var inputSection: some View {
        VStack(spacing: 15) {
            CustomTextField(text: $email, placeholder: "Email", systemImage: "envelope")
            CustomTextField(text: $password, placeholder: "Password", systemImage: "lock", isSecure: true)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button(action: handleAuthentication) {
                Text(isRegistering ? "Sign Up" : "Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(AppTheme.primary)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            
            Button(action: { isRegistering.toggle() }) {
                Text(isRegistering ? "Already have an account? Sign In" : "Need an account? Sign Up")
                    .foregroundColor(.white)
            }
        }
    }
    
    @ViewBuilder
    private var developmentButtons: some View {
        #if DEBUG
        VStack {
            Divider()
                .background(Color.white)
                .padding(.vertical)
            
            Button("Quick Dev Login") {
                isLoading = true
                email = "test@test.com"
                password = "password123"
                createDevAccountIfNeeded()
            }
            .foregroundColor(.white)
        }
        #endif
    }
    
    private func handleAuthentication() {
        isLoading = true
        if isRegistering {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                handleAuthResult(result, error)
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                handleAuthResult(result, error)
            }
        }
    }
    
    private func handleAuthResult(_ result: AuthDataResult?, _ error: Error?) {
        isLoading = false
        if let error = error {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func createDevAccountIfNeeded() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if error != nil {
                // Account might exist, try signing in
                Auth.auth().signIn(withEmail: email, password: password) { result, error in
                    isLoading = false
                    if let error = error {
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }
            } else {
                isLoading = false
            }
        }
    }
}
