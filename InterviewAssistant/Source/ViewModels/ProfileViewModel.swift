// Source/ViewModels/ProfileViewModel.swift
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
    @Published var isAnalyzing = false
    private var originalUser: User?
    
    var hasChanges: Bool {
        return originalUser != user
    }
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        isLoading = true
        
        Task {
            do {
                let currentUser = try await FirebaseManager.shared.getCurrentUser()
                await MainActor.run {
                    self.user = currentUser
                    self.originalUser = currentUser
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func saveProfile() {
        guard var updatedUser = user else { return }
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
    
    func analyzeAndSaveResume() {
        guard !resumeText.isEmpty else { return }
        isLoading = true
        
        Task {
            do {
                let analysis = try await ResumeAnalyzer.shared.analyzeResume(resumeText)
                
                // Update user with new resume analysis
                if var updatedUser = user {
                    updatedUser.resumeAnalysis = analysis
                    try await FirebaseManager.shared.updateUserProfile(updatedUser)
                    
                    await MainActor.run {
                        self.user = updatedUser
                        self.originalUser = updatedUser
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
    
    // Helper method to update specific user fields
    func updateUserField(_ keyPath: WritableKeyPath<User, String>, value: String) {
        if var updatedUser = user {
            updatedUser[keyPath: keyPath] = value
            user = updatedUser
        }
    }
    
    // Helper method to update profile fields
    func updateProfileField<T>(_ keyPath: WritableKeyPath<User.Profile, T>, value: T) {
        if var updatedUser = user {
            if updatedUser.profile == nil {
                updatedUser.profile = User.Profile(
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
                )
            }
            updatedUser.profile?[keyPath: keyPath] = value
            user = updatedUser
        }
    }
}

// MARK: - Error Handling Extension
extension ProfileViewModel {
    enum ProfileError: LocalizedError {
        case userNotFound
        case updateFailed
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .userNotFound:
                return "User profile not found"
            case .updateFailed:
                return "Failed to update profile"
            case .invalidData:
                return "Invalid profile data"
            }
        }
    }
}
