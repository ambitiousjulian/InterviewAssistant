// Source/Services/FirebaseManager.swift
import Firebase
import FirebaseAuth
import Foundation

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private init() {}
    
    func configure() {
        FirebaseApp.configure()
    }
    
    // Convert Firebase User to our custom User model
    func convertFirebaseUser(_ firebaseUser: FirebaseAuth.User?) -> User? {
        guard let firebaseUser = firebaseUser else { return nil }
        
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            name: firebaseUser.displayName,
            profileImageURL: firebaseUser.photoURL?.absoluteString
        )
    }
    
    // Sign in with email and password
    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        guard let user = convertFirebaseUser(result.user) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"])
        }
        return user
    }
    
    // Sign out
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // Get current user
    func getCurrentUser() -> User? {
        guard let firebaseUser = Auth.auth().currentUser else { return nil }
        return convertFirebaseUser(firebaseUser)
    }
    
    // Update user profile
    func updateProfile(name: String) async throws {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = name
        try await changeRequest?.commitChanges()
    }
}

// Make sure your User model looks like this:
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let profileImageURL: String?
}
