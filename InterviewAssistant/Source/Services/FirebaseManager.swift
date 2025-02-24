import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import Foundation

enum FirebaseError: LocalizedError {
    case notSignedIn
    case userNotFound
    case invalidData
    case networkError
    case unknownError(String)
    case reauthenticationRequired
    case deletionError
    case userDataDeletionError
    
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
        case .reauthenticationRequired:
            return "Please re-enter your password to continue"
        case .deletionError:
            return "Failed to delete account"
        case .userDataDeletionError:
            return "Failed to delete user data"
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
                resumeAnalysis: nil,
                subscriptionStatus: User.SubscriptionStatus.defaultStatus
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
                    resumeAnalysis: nil,
                    subscriptionStatus: User.SubscriptionStatus.defaultStatus
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
            resumeAnalysis: nil,
            subscriptionStatus: User.SubscriptionStatus.defaultStatus 
        )
    }
    // Main deletion method
    func deleteUserAccount(password: String) async throws {
        guard let currentUser = Auth.auth().currentUser,
              let email = currentUser.email else {
            throw FirebaseError.notSignedIn
        }
        
        do {
            // 1. Reauthenticate user
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await currentUser.reauthenticate(with: credential)
            
            // 2. Delete all user data
            try await deleteAllUserData(userId: currentUser.uid)
            
            // 3. Delete authentication account
            try await currentUser.delete()
            
            // 4. Clear local storage
            clearLocalStorage(for: currentUser.uid)
            
            // 5. Sign out
            try Auth.auth().signOut()
            
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.requiresRecentLogin.rawValue:
                throw FirebaseError.reauthenticationRequired
            case AuthErrorCode.weakPassword.rawValue:
                throw FirebaseError.invalidData
            default:
                throw FirebaseError.deletionError
            }
        }
    }
    
    func fetchSubscriptionStatus(userId: String) async throws -> User.SubscriptionStatus {
            do {
                let document = try await db.collection("users").document(userId).getDocument()
                if let data = document.data()?["subscriptionStatus"] as? [String: Any] {
                    return try Firestore.Decoder().decode(User.SubscriptionStatus.self, from: data)
                }
                return User.SubscriptionStatus.defaultStatus
            } catch {
                throw FirebaseError.unknownError(error.localizedDescription)
            }
        }
        
        func updateSubscriptionStatus(userId: String, status: User.SubscriptionStatus) async throws {
            do {
                let data = try Firestore.Encoder().encode(status)
                try await db.collection("users").document(userId).updateData([
                    "subscriptionStatus": data
                ])
            } catch {
                throw FirebaseError.unknownError(error.localizedDescription)
            }
        }
        
        func decrementFreeInterviews(userId: String) async throws {
            do {
                try await db.collection("users").document(userId).updateData([
                    "subscriptionStatus.freeInterviewsRemaining": FirebaseFirestore.FieldValue.increment(Int64(-1))
                ])
            } catch {
                throw FirebaseError.unknownError(error.localizedDescription)
            }
        }

        func resetFreeInterviews(userId: String) async throws {
            do {
                try await db.collection("users").document(userId).updateData([
                    "subscriptionStatus.freeInterviewsRemaining": 1
                ])
            } catch {
                throw FirebaseError.unknownError(error.localizedDescription)
            }
        }
    
    // Delete all user data from Firestore
    private func deleteAllUserData(userId: String) async throws {
        do {
            // Delete user document
            try await db.collection("users").document(userId).delete()
            
            // Delete resume analysis
            try await deleteResumeAnalysis(userId: userId)
            
            // Add any other data deletion here
            // Example: Delete user's chat history, preferences, etc.
            
        } catch {
            throw FirebaseError.userDataDeletionError
        }
    }
    
    // Delete resume analysis specifically
    private func deleteResumeAnalysis(userId: String) async throws {
        do {
            try await db.collection("users").document(userId).updateData([
                "resumeAnalysis": FieldValue.delete()
            ])
        } catch {
            print("[WARNING] Failed to delete resume analysis: \(error.localizedDescription)")
            // Don't throw here, as this is not critical
        }
    }
    
    // Clear local storage
    private func clearLocalStorage(for userId: String) {
        let userDefaults = UserDefaults.standard
        let keysToRemove = [
            "hasCompletedOnboarding_\(userId)",
            "isFirstTimeUser_\(userId)",
            // Add any other user-specific keys
        ]
        
        keysToRemove.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
        userDefaults.synchronize()
    }
    
    // Verify deletion
    func verifyDeletion(userId: String) async throws -> Bool {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            return !document.exists
        } catch {
            throw FirebaseError.networkError
        }
    }
    
    private func logDeletionRequest(userId: String) async {
        do {
            try await db.collection("deletion_logs").addDocument(data: [
                "userId": userId,
                "requestedAt": FieldValue.serverTimestamp(),
                "status": "requested",
                "platform": "iOS",
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ])
        } catch {
            print("[WARNING] Failed to log deletion request: \(error.localizedDescription)")
        }
    }
    
    private func updateDeletionLog(userId: String, status: String) async {
        do {
            let query = db.collection("deletion_logs")
                .whereField("userId", isEqualTo: userId)
                .whereField("status", isEqualTo: "requested")
                .limit(to: 1)
            
            let documents = try await query.getDocuments()
            if let document = documents.documents.first {
                try await document.reference.updateData([
                    "status": status,
                    "completedAt": FieldValue.serverTimestamp()
                ])
            }
        } catch {
            print("[WARNING] Failed to update deletion log: \(error.localizedDescription)")
        }
    }
}
