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
                                    text: Binding(
                                        get: { viewModel.user?.name ?? "" },
                                        set: { viewModel.updateUserField(\.name, value: $0) }
                                    ),
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
                        
                        // Resume Section
                        ProfileCard(title: "Resume & Experience", icon: "doc.text.fill") {
                            VStack(spacing: 15) {
                                if let resumeAnalysis = viewModel.user?.resumeAnalysis {
                                    resumeAnalysisView(resumeAnalysis)
                                } else {
                                    resumeUploadPrompt
                                }
                                
                                Divider()
                                    .padding(.vertical, 5)
                                
                                ProfileTextField(
                                    title: "Target Role",
                                    text: Binding(
                                        get: { viewModel.user?.profile?.jobPreferences.targetRole ?? "" },
                                        set: { viewModel.updateProfileField(\User.Profile.jobPreferences.targetRole, value: $0) }
                                    ),
                                    icon: "target"
                                )
                                
                                ProfileTextField(
                                    title: "Target Industry",
                                    text: Binding(
                                        get: { viewModel.user?.profile?.jobPreferences.targetIndustry ?? "" },
                                        set: { viewModel.updateProfileField(\User.Profile.jobPreferences.targetIndustry, value: $0) }
                                    ),
                                    icon: "building.2"
                                )
                                
                                ExperiencePicker(
                                    selection: Binding(
                                        get: { viewModel.user?.profile?.jobPreferences.experienceLevel ?? .entry },
                                        set: { viewModel.updateProfileField(\User.Profile.jobPreferences.experienceLevel, value: $0) }
                                    )
                                )
                            }
                        }
                        
                        // Current Experience
                        ProfileCard(title: "Current Experience", icon: "clock.fill") {
                            VStack(spacing: 15) {
                                ExperienceStepper(
                                    value: Binding(
                                        get: { viewModel.user?.profile?.experience.yearsOfExperience ?? 0 },
                                        set: { viewModel.updateProfileField(\User.Profile.experience.yearsOfExperience, value: $0) }
                                    ),
                                    range: 0...50
                                )
                                
                                ProfileTextField(
                                    title: "Current Role",
                                    text: Binding(
                                        get: { viewModel.user?.profile?.experience.currentRole ?? "" },
                                        set: { viewModel.updateProfileField(\User.Profile.experience.currentRole, value: $0) }
                                    ),
                                    icon: "person.text.rectangle"
                                )
                                
                                ProfileTextField(
                                    title: "Current Industry",
                                    text: Binding(
                                        get: { viewModel.user?.profile?.experience.currentIndustry ?? "" },
                                        set: { viewModel.updateProfileField(\User.Profile.experience.currentIndustry, value: $0) }
                                    ),
                                    icon: "building"
                                )
                            }
                        }
                        
                        actionButtons
                    }
                    .padding(.horizontal)
                    .offset(y: isAnimating ? 0 : 30)
                }
            }
            .background(backgroundGradient.opacity(0.1).ignoresSafeArea())
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
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $viewModel.showingResumeInput) {
                ResumeInputView(viewModel: viewModel)
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
    
    // MARK: - Component Views
    
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
                Text(viewModel.user?.name ?? "Add Your Name")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.text)
                
                Text(Auth.auth().currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 20)
    }
    
    private var resumeUploadPrompt: some View {
        Button {
            viewModel.showingResumeInput = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 30))
                    .foregroundColor(AppTheme.primary)
                
                Text("Upload Resume")
                    .font(.headline)
                    .foregroundColor(AppTheme.primary)
                
                Text("We'll analyze your resume to enhance your interview preparation")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primary.opacity(0.1))
            .cornerRadius(12)
        }
    }
    private func resumeAnalysisView(_ analysis: User.ResumeAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Resume Uploaded")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("Last updated: \(analysis.lastUpdated.formatted(.dateTime.day().month()))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button {
                    viewModel.showingResumeInput = true
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Skills")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                FlowLayout(spacing: 8) {
                    ForEach(analysis.skills, id: \.self) { skill in
                        Text(skill)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.primary.opacity(0.1))
                            .foregroundColor(AppTheme.primary)
                            .cornerRadius(12)
                    }
                }
            }
        }
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
                    .foregroundColor(AppTheme.text)
            }
            
            content()
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(15)
        .shadow(color: AppTheme.shadowLight, radius: 10, x: 0, y: 5)
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
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct ExperiencePicker: View {
    @Binding var selection: User.JobPreferences.ExperienceLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Experience Level")
                .font(.caption)
                .foregroundColor(.gray)
            
            Picker("", selection: $selection) {
                ForEach(User.JobPreferences.ExperienceLevel.allCases, id: \.self) { level in
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
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            spacing: spacing,
            subviews: subviews
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            spacing: spacing,
            subviews: subviews
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }
    
    struct FlowResult {
        var sizes: [CGSize]
        var positions: [CGPoint]
        var size: CGSize
        
        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var sizes = [CGSize]()
            var positions = [CGPoint]()
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxWidth: CGFloat = maxWidth
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > maxWidth {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                sizes.append(size)
                
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                maxWidth = max(maxWidth, currentX)
            }
            
            self.sizes = sizes
            self.positions = positions
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
