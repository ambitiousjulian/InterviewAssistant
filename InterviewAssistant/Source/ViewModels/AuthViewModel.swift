// Source/ViewModels/AuthViewModel.swift
import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
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
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    func signOut() {
        do {
            try FirebaseManager.shared.signOut()
        } catch {
            print("[ERROR] Sign out error: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }
}
