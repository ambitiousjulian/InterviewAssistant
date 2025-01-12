import SwiftUI
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    @Published var name = ""
    @Published var targetRole = ""
    @Published var targetIndustry = ""
    @Published var experienceLevel = UserProfile.JobPreferences.ExperienceLevel.entry
    @Published var yearsOfExperience = 0
    @Published var currentRole = ""
    @Published var currentIndustry = ""
    
    @Published var isLoading = false
    @Published var showingSaveAlert = false
    
    private var originalProfile: UserProfile?
    
    var hasChanges: Bool {
        let currentProfile = createProfile()
        return originalProfile != currentProfile
    }
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        // TODO: Load from Firebase/local storage
        // For now, we'll use mock data
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            // Mock data
            self.name = "John Doe"
            self.targetRole = "iOS Developer"
            self.targetIndustry = "Technology"
            self.experienceLevel = .midLevel
            self.yearsOfExperience = 3
            self.currentRole = "Junior Developer"
            self.currentIndustry = "Software"
            
            self.originalProfile = self.createProfile()
        }
    }
    
    func saveProfile() {
        isLoading = true
        // TODO: Save to Firebase/local storage
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.showingSaveAlert = true
            self.originalProfile = self.createProfile()
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    private func createProfile() -> UserProfile {
        UserProfile(
            id: Auth.auth().currentUser?.uid ?? "",
            name: name,
            email: Auth.auth().currentUser?.email ?? "",
            jobPreferences: .init(
                targetRole: targetRole,
                targetIndustry: targetIndustry,
                experienceLevel: experienceLevel
            ),
            experience: .init(
                yearsOfExperience: yearsOfExperience,
                currentRole: currentRole,
                currentIndustry: currentIndustry
            )
        )
    }
}