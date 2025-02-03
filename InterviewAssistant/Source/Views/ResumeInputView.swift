import SwiftUI

struct ResumeInputView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Error Banner
                if let error = viewModel.resumeAnalysisError {
                    errorBanner(error)
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Section
                        headerSection
                            .offset(y: isAnimating ? 0 : -30)
                        
                        // Analyze Button
                        analyzeButton
                            .padding(.horizontal)
                        
                        // Input Section with Error Display
                        if let error = viewModel.resumeAnalysisError {
                            errorView(error)
                                .padding(.horizontal)
                        }
                        
                        // Clipboard Button
                        pasteClipboardButton
                        
                        // Main Input Section
                        inputSection
                            .offset(y: isAnimating ? 0 : 30)
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
                .onTapGesture {
                    dismissKeyboard()
                }
            }
            .navigationTitle("Resume Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.primary)
                .padding()
                .background(
                    Circle()
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 100, height: 100)
                )
            
            Text("Resume Analysis")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Paste your resume text below for analysis")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resume Text")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            TextEditor(text: $viewModel.resumeText)
                .frame(minHeight: 200)
                .padding()
                .background(AppTheme.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(.vertical)
    }
    
    private var pasteClipboardButton: some View {
        Button {
            if let clipboardText = UIPasteboard.general.string {
                viewModel.resumeText = clipboardText
            }
        } label: {
            HStack {
                Image(systemName: "doc.on.clipboard")
                Text("Paste from Clipboard")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primary.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var analyzeButton: some View {
        Button {
            dismissKeyboard()
            viewModel.analyzeAndSaveResume()
        } label: {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("Analyze Resume")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.resumeText.isEmpty ? AppTheme.primary.opacity(0.3) : AppTheme.primary)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.resumeText.isEmpty)
    }
    
    private func errorBanner(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(error)
                .font(.subheadline)
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red)
    }
    
    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .blur(radius: 2)
            
            // Loading card
            VStack(spacing: 20) {
                // Animated circle
                ZStack {
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(AppTheme.primary, lineWidth: 8)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                        .onAppear {
                            isAnimating = true
                        }
                }
                
                VStack(spacing: 8) {
                    Text("Analyzing Resume")
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                    
                    Text("This may take a few moments...")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.text.opacity(0.7))
                }
                
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 8, height: 8)
                            .opacity(isAnimating ? 1 : 0.3)
                            .animation(
                                .easeInOut(duration: 0.4)
                                .repeatForever()
                                .delay(0.3 * Double(index)),
                                value: isAnimating
                            )
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.surface)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview
struct ResumeInputView_Previews: PreviewProvider {
    static var previews: some View {
        ResumeInputView(viewModel: ProfileViewModel())
    }
}
