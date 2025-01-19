// Source/Services/FirebaseManager.swift
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation

enum FirebaseError: LocalizedError {
    case notSignedIn
    case userNotFound
    case invalidData
    case networkError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "User is not signed in"
        case .userNotFound:
            return "User not found"
        case .invalidData:
            return "Invalid data format"
        case .networkError:
            return "Network connection error"
        case .unknownError(let message):
            return message
        }
    }
}

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func configure() {
        FirebaseApp.configure()
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = try await fetchUserProfile(uid: result.user.uid)
            return user
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = User(
                id: result.user.uid,
                email: email,
                name: name,
                profileImageURL: nil,
                profile: User.Profile(
                    jobPreferences: User.JobPreferences(
                        targetRole: "",
                        targetIndustry: "",
                        experienceLevel: .entry
                    ),
                    experience: User.Experience(
                        yearsOfExperience: 0,
                        currentRole: "",
                        currentIndustry: ""
                    )
                ),
                resumeAnalysis: nil
            )
            
            try await updateUserProfile(user)
            return user
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    // MARK: - User Profile Methods
    
    func getCurrentUser() async throws -> User? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        return try await fetchUserProfile(uid: firebaseUser.uid)
    }
    
    func updateUserProfile(_ user: User) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseError.notSignedIn
        }
        
        do {
            try await db.collection("users").document(uid).setData(from: user)
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func fetchUserProfile(uid: String) async throws -> User {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if document.exists {
                let user = try document.data(as: User.self)
                return user
            } else {
                throw FirebaseError.userNotFound
            }
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    // MARK: - Resume Methods
    
    func updateResumeAnalysis(userId: String, analysis: User.ResumeAnalysis) async throws {
        do {
            try await db.collection("users").document(userId)
                .updateData(["resumeAnalysis": analysis])
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func getResumeAnalysis(userId: String) async throws -> User.ResumeAnalysis? {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data(),
               let analysisData = data["resumeAnalysis"] as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: analysisData)
                return try JSONDecoder().decode(User.ResumeAnalysis.self, from: jsonData)
            }
            return nil
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    // MARK: - Profile Image Methods
    
    func updateProfileImage(userId: String, imageURL: String) async throws {
        do {
            try await db.collection("users").document(userId)
                .updateData(["profileImageURL": imageURL])
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    func convertFirebaseUser(_ firebaseUser: FirebaseAuth.User?) -> User? {
        guard let firebaseUser = firebaseUser else { return nil }
        
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            name: firebaseUser.displayName ?? "",
            profileImageURL: firebaseUser.photoURL?.absoluteString,
            profile: nil,
            resumeAnalysis: nil
        )
    }
    
    func updateProfile(name: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw FirebaseError.notSignedIn
        }
        
        do {
            let changeRequest = currentUser.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
}
