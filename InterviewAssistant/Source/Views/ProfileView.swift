import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isAnimating = false
    @Environment(\.colorScheme) var colorScheme
    @State private var showDeleteAccount = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        profileHeader
                            .offset(y: isAnimating ? 0 : -30)
                        
                        mainContent
                            .offset(y: isAnimating ? 0 : 30)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingResumeInput) {
                ResumeInputView(viewModel: viewModel)
            }
            .sheet(isPresented: $showDeleteAccount) {
                DeleteAccountView()
                    .environmentObject(authViewModel)
            }
            .alert("Success", isPresented: $viewModel.showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your profile has been updated successfully.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    isAnimating = true
                }
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
                Text(viewModel.user?.name ?? "Add Your Name")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.text)
                
                Text(Auth.auth().currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.text.opacity(0.7))
            }
        }
        .padding(.vertical, 20)
    }
    
    private var mainContent: some View {
        VStack(spacing: 20) {
            personalInfoCard
            resumeCard
            actionButtons
        }
        .padding(.horizontal)
    }
    
    // First, update the CustomTextField implementation:
    struct CustomTextField: View {
        let placeholder: String
        @Binding var text: String
        let systemImage: String
        var isDisabled: Bool = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(placeholder)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.text.opacity(0.7))
                
                HStack {
                    Image(systemName: systemImage)
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 20)
                    
                    TextField(placeholder, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .disabled(isDisabled)
                }
                .padding()
                .background(AppTheme.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    // Then update the personalInfoCard implementation:
    private var personalInfoCard: some View {
        ProfileCard(title: "Personal Information", icon: "person.fill") {
            VStack(spacing: 15) {
                CustomTextField(
                    placeholder: "Full Name",
                    text: Binding(
                        get: { viewModel.user?.name ?? "" },
                        set: { viewModel.updateUserField(\.name, value: $0) }
                    ),
                    systemImage: "person.text.rectangle"
                )
                
                CustomTextField(
                    placeholder: "Email Address",
                    text: .constant(Auth.auth().currentUser?.email ?? ""),
                    systemImage: "envelope.fill",
                    isDisabled: true
                )
            }
        }
    }
    
    private var resumeCard: some View {
        ProfileCard(title: "Resume", icon: "doc.text.fill") {
            VStack(spacing: 15) {
                if let resumeAnalysis = viewModel.user?.resumeAnalysis {
                    resumeAnalysisView(resumeAnalysis)
                } else {
                    resumeUploadPrompt
                }
            }
        }
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
                
                Text("We'll analyze your resume to enhance your interview preparation.")
                    .font(.caption)
                    .foregroundColor(AppTheme.text.opacity(0.7))
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
                        .foregroundColor(AppTheme.secondary)
                    
                    Text("Last updated: \(analysis.lastUpdated.formatted(.dateTime.day().month()))")
                        .font(.caption)
                        .foregroundColor(AppTheme.text.opacity(0.7))
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
                .foregroundColor(AppTheme.surface)
                .cornerRadius(15)
            }
            .disabled(!viewModel.hasChanges)
            
            Button {
                viewModel.signOut()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                    Text("Sign Out")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(15)
            }
            
            Button {
                viewModel.user?.resumeAnalysis = nil
                viewModel.saveProfile()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Resume Analysis")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.text.opacity(0.1))
                .foregroundColor(AppTheme.text)
                .cornerRadius(15)
            }
            
            // Add Delete Account Button
            Button(action: { showDeleteAccount = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Account")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(15)
            }
        }
    }
    
    private var deleteAccountButton: some View {
        Button(action: { showDeleteAccount = true }) {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete Account")
            }
            .foregroundColor(.red)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .cornerRadius(15)
        }
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountView()
        }
    }
}

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
            .padding(.bottom, 5)
            
            content()
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(15)
        .shadow(color: AppTheme.shadowLight, radius: 10, x: 0, y: 5)
    }
}

// Helper view for flowing layout of skills
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.positions[index].x + bounds.minX,
                                    y: result.positions[index].y + bounds.minY),
                         proposal: ProposedViewSize(result.sizes[index]))
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint]
        var sizes: [CGSize]
        var size: CGSize
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var sizes: [CGSize] = []
            
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            var rowMaxY: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && !positions.isEmpty {
                    x = 0
                    y = rowMaxY + spacing
                }
                
                positions.append(CGPoint(x: x, y: y))
                sizes.append(size)
                
                rowHeight = max(rowHeight, size.height)
                rowMaxY = y + rowHeight
                x += size.width + spacing
            }
            
            self.positions = positions
            self.sizes = sizes
            self.size = CGSize(width: maxWidth, height: rowMaxY)
        }
    }
}
