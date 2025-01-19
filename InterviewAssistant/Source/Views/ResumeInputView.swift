//
//  ResumeInputView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/19/25.
//


// Source/Views/ResumeInputView.swift
import SwiftUI

struct ResumeInputView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedInputMethod = 0
    @State private var showingDocumentPicker = false
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header Section
                    headerSection
                        .offset(y: isAnimating ? 0 : -30)
                    
                    // Input Method Selector
                    Picker("Input Method", selection: $selectedInputMethod) {
                        Text("Paste Text").tag(0)
                        Text("Upload File").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Input Section
                    inputSection
                        .offset(y: isAnimating ? 0 : 30)
                    
                    // Analysis Status
                    if viewModel.isAnalyzing {
                        analysisProgressView
                    }
                    
                    // Error Display
                    if let error = viewModel.resumeAnalysisError {
                        errorView(error)
                    }
                    
                    // Action Buttons
                    actionButtons
                        .offset(y: isAnimating ? 0 : 30)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [AppTheme.primary.opacity(0.1), AppTheme.secondary.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Resume Upload")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Done") {
                    viewModel.analyzeAndSaveResume()
                }
                .disabled(viewModel.resumeText.isEmpty)
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.primary)
                .padding()
                .background(
                    Circle()
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 100, height: 100)
                )
            
            Text("Upload Your Resume")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("We'll analyze your resume to provide better interview preparation")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var inputSection: some View {
        Group {
            if selectedInputMethod == 0 {
                // Text Input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Paste your resume text")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextEditor(text: $viewModel.resumeText)
                        .frame(minHeight: 200)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 10)
                }
            } else {
                // File Upload
                VStack {
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        VStack(spacing: 15) {
                            Image(systemName: "arrow.up.doc")
                                .font(.system(size: 30))
                            Text("Upload PDF or Word Document")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 10)
                    }
                    .foregroundColor(AppTheme.primary)
                    
                    Text("Supported formats: PDF, DOC, DOCX")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical)
    }
    
    private var analysisProgressView: some View {
        VStack(spacing: 15) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing your resume...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
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
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button {
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
                .cornerRadius(15)
            }
            .disabled(viewModel.resumeText.isEmpty)
            
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.gray)
                    .cornerRadius(15)
            }
        }
    }
}

// MARK: - Preview
struct ResumeInputView_Previews: PreviewProvider {
    static var previews: some View {
        ResumeInputView(viewModel: ProfileViewModel())
    }
}
