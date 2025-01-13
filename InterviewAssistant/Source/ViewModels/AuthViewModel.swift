// Source/ViewModels/AuthViewModel.swift
import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private var handler: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        handler = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    self?.currentUser = FirebaseManager.shared.convertFirebaseUser(firebaseUser)
                    self?.isAuthenticated = true
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Task {
            do {
                let user = try await FirebaseManager.shared.signIn(email: email, password: password)
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
            } catch {
                print("Sign in error: \(error.localizedDescription)")
            }
        }
    }
    
    func signOut() {
        do {
            try FirebaseManager.shared.signOut()
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
    }
}
