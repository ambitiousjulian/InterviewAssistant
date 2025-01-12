import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func signIn(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return User(id: result.user.uid, 
                   email: result.user.email ?? "", 
                   name: result.user.displayName, 
                   profileImageURL: result.user.photoURL?.absoluteString)
    }
}
