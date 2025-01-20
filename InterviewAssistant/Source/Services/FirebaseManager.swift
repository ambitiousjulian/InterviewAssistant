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
    let db = Firestore.firestore()
    
    private init() {}
    
    func configure() {
        FirebaseApp.configure()
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return try await fetchUserProfile(uid: result.user.uid)
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
                resumeAnalysis: nil
            )
            try await updateUserProfile(user)
            return user
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // MARK: - User Profile Methods
    
    func getCurrentUser() async throws -> User? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        
        do {
            let document = try await db.collection("users").document(firebaseUser.uid).getDocument()
            if document.exists {
                let user = try document.data(as: User.self)
                return user
            } else {
                // Create a new user if document doesn't exist
                let newUser = User(
                    id: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    name: "",
                    resumeAnalysis: nil
                )
                try await updateUserProfile(newUser)
                return newUser
            }
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
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
            try await db.collection("users").document(userId).updateData([
                "resumeAnalysis": [
                    "skills": analysis.skills,
                    "summary": analysis.summary,
                    "lastUpdated": Timestamp(date: analysis.lastUpdated)
                ]
            ])
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func getResumeAnalysis(userId: String) async throws -> User.ResumeAnalysis? {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data()?["resumeAnalysis"] as? [String: Any],
               let skills = data["skills"] as? [String],
               let summary = data["summary"] as? String,
               let lastUpdatedTimestamp = data["lastUpdated"] as? Timestamp {
                return User.ResumeAnalysis(
                    skills: skills,
                    summary: summary,
                    lastUpdated: lastUpdatedTimestamp.dateValue()
                )
            }
            return nil
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
            resumeAnalysis: nil
        )
    }
}
