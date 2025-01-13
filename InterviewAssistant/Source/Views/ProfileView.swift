//
//  ProfileView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSignOutAlert = false
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Profile Header
                    profileHeader
                        .offset(y: isAnimating ? 0 : -30)
                    
                    // Main Content Cards
                    VStack(spacing: 20) {
                        // Personal Info
                        ProfileCard(title: "Personal Info", icon: "person.fill") {
                            VStack(spacing: 15) {
                                ProfileTextField(
                                    title: "Name",
                                    text: $viewModel.name,
                                    icon: "person.text.rectangle"
                                )
                                
                                ProfileTextField(
                                    title: "Email",
                                    text: .constant(Auth.auth().currentUser?.email ?? ""),
                                    icon: "envelope.fill",
                                    isDisabled: true
                                )
                            }
                        }
                        
                        // Job Preferences
                        ProfileCard(title: "Job Preferences", icon: "briefcase.fill") {
                            VStack(spacing: 15) {
                                ProfileTextField(
                                    title: "Target Role",
                                    text: $viewModel.targetRole,
                                    icon: "target"
                                )
                                
                                ProfileTextField(
                                    title: "Target Industry",
                                    text: $viewModel.targetIndustry,
                                    icon: "building.2"
                                )
                                
                                ExperiencePicker(selection: $viewModel.experienceLevel)
                            }
                        }
                        
                        // Current Experience
                        ProfileCard(title: "Current Experience", icon: "clock.fill") {
                            VStack(spacing: 15) {
                                ExperienceStepper(
                                    value: $viewModel.yearsOfExperience,
                                    range: 0...50
                                )
                                
                                ProfileTextField(
                                    title: "Current Role",
                                    text: $viewModel.currentRole,
                                    icon: "person.text.rectangle"
                                )
                                
                                ProfileTextField(
                                    title: "Current Industry",
                                    text: $viewModel.currentIndustry,
                                    icon: "building"
                                )
                            }
                        }
                        
                        // Action Buttons
                        actionButtons
                    }
                    .padding(.horizontal)
                    .offset(y: isAnimating ? 0 : 30)
                }
            }
            .background(
                backgroundGradient
                    .opacity(0.1)
                    .ignoresSafeArea()
            )
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
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
                    LoadingView()
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(AppTheme.primary)
            }
            
            VStack(spacing: 5) {
                Text(viewModel.name.isEmpty ? "Add Your Name" : viewModel.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(Auth.auth().currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 20)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button {
                viewModel.saveProfile()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Save Changes")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.hasChanges ? AppTheme.primary : AppTheme.primary.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .disabled(!viewModel.hasChanges)
            
            Button {
                showingSignOutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(15)
            }
        }
        .padding(.vertical)
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                AppTheme.primary.opacity(0.1),
                AppTheme.secondary.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Supporting Views
struct ProfileCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                Text(title)
                    .font(.headline)
            }
            
            content()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var isDisabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                TextField("", text: $text)
                    .disabled(isDisabled)
            }
            .padding()
            .background(AppTheme.surface)
            .cornerRadius(12)
        }
    }
}

struct ExperiencePicker: View {
    @Binding var selection: UserProfile.JobPreferences.ExperienceLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Experience Level")
                .font(.caption)
                .foregroundColor(.gray)
            
            Picker("", selection: $selection) {
                ForEach(UserProfile.JobPreferences.ExperienceLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

struct ExperienceStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack {
            Text("Years of Experience")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            HStack {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(AppTheme.primary)
                }
                
                Text("\(value)")
                    .frame(minWidth: 40)
                    .font(.headline)
                
                Button {
                    if value < range.upperBound {
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(AppTheme.surface)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
