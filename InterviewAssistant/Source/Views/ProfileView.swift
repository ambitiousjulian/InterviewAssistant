import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Info") {
                    TextField("Name", text: $viewModel.name)
                    TextField("Email", text: .constant(Auth.auth().currentUser?.email ?? ""))
                        .disabled(true)
                }
                
                Section("Job Preferences") {
                    TextField("Target Role", text: $viewModel.targetRole)
                    TextField("Target Industry", text: $viewModel.targetIndustry)
                    Picker("Experience Level", selection: $viewModel.experienceLevel) {
                        ForEach(UserProfile.JobPreferences.ExperienceLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
                
                Section("Current Experience") {
                    Stepper("Years of Experience: \(viewModel.yearsOfExperience)", value: $viewModel.yearsOfExperience, in: 0...50)
                    TextField("Current Role", text: $viewModel.currentRole)
                    TextField("Current Industry", text: $viewModel.currentIndustry)
                }
                
                Section {
                    Button("Save Changes") {
                        viewModel.saveProfile()
                    }
                    .disabled(!viewModel.hasChanges)
                }
                
                Section {
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut()
                }
            }
            .alert("Profile Updated", isPresented: $viewModel.showingSaveAlert) {
                Button("OK") { }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
}