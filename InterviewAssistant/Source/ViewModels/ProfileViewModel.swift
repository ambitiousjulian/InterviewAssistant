import SwiftUI
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var showingSaveAlert = false
    @Published var showingResumeInput = false
    @Published var resumeText = ""
    @Published var resumeAnalysisError: String?
    @Published var errorMessage: String?
    
    private var originalUser: User?

    var hasChanges: Bool {
        return originalUser != user
    }
    
    init() {
        loadProfile()
    }
    
    // MARK: - Load Profile
    func loadProfile() {
        isLoading = true
        Task {
            do {
                if let currentUser = try await FirebaseManager.shared.getCurrentUser() {
                    await MainActor.run {
                        self.user = currentUser
                        self.originalUser = currentUser
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "No user found"
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Save Profile
    func saveProfile() {
        guard let updatedUser = user else { return }
        isLoading = true
        Task {
            do {
                try await FirebaseManager.shared.updateUserProfile(updatedUser)
                await MainActor.run {
                    self.originalUser = updatedUser
                    self.isLoading = false
                    self.showingSaveAlert = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Analyze and Save Resume
    func analyzeAndSaveResume() {
        guard !resumeText.isEmpty else { return }
        isLoading = true
        Task {
            do {
                let analysis = try await ResumeAnalyzer.shared.analyzeResume(resumeText)
                
                if var updatedUser = user {
                    updatedUser.resumeAnalysis = analysis
                    try await FirebaseManager.shared.updateUserProfile(updatedUser)
                    
                    await MainActor.run {
                        self.user = updatedUser
                        self.originalUser = updatedUser
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ResumeAnalysisUpdated"),
                            object: nil,
                            userInfo: ["analysis": analysis]
                        )
                        self.isLoading = false
                        self.showingResumeInput = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.resumeAnalysisError = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        Task {
            do {
                try FirebaseManager.shared.signOut()
                await MainActor.run {
                    self.user = nil
                    self.originalUser = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    func updateUserField(_ keyPath: WritableKeyPath<User, String>, value: String) {
        if var updatedUser = user {
            updatedUser[keyPath: keyPath] = value
            user = updatedUser
        }
    }
}
