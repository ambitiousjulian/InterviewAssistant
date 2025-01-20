import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var showOnboarding = false
    @Published var isFirstTimeUser = false
    
    private var handler: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        handler = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    do {
                        let user = try await FirebaseManager.shared.fetchUserProfile(uid: firebaseUser.uid)
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        
                        // Check if user has completed onboarding
                        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding_\(user.id)")
                        self?.showOnboarding = !hasCompletedOnboarding
                        self?.isFirstTimeUser = !hasCompletedOnboarding
                        
                    } catch {
                        print("[ERROR] Failed to fetch user profile: \(error)")
                        self?.error = error.localizedDescription
                    }
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await FirebaseManager.shared.signIn(email: email, password: password)
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    @MainActor
    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await FirebaseManager.shared.signUp(email: email, password: password, name: email.components(separatedBy: "@").first ?? "")
            self.currentUser = user
            self.isAuthenticated = true
            self.showOnboarding = true
            self.isFirstTimeUser = true
            
            // Don't mark as completed yet for new users
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding_\(user.id)")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    func completeOnboarding() {
        if let userId = currentUser?.id {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_\(userId)")
            showOnboarding = false
            isFirstTimeUser = true  // Keep this true to ensure we go to profile page
        }
    }
    
    func signOut() {
        do {
            try FirebaseManager.shared.signOut()
            // Clear any stored onboarding states if needed
            if let userId = currentUser?.id {
                // Optionally reset onboarding state on sign out
                // UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding_\(userId)")
            }
        } catch {
            print("[ERROR] Sign out error: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }
}
