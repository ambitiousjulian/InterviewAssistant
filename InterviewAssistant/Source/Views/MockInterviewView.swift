//
//  MockInterviewView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//
import SwiftUI

struct MockInterviewView: View {
    @StateObject private var viewModel = MockInterviewViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    @FocusState private var isResponseFocused: Bool
    
    var body: some View {
        ZStack {
            // Enhanced Background
            LinearGradient(
                colors: [
                    AppTheme.primary.opacity(0.1),
                    AppTheme.secondary.opacity(0.1),
                    AppTheme.accent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                switch viewModel.currentState {
                case .setup:
                    setupView
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .inProgress:
                    interviewView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                case .reviewing:
                    if !viewModel.isLoading {
                        analysisView
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                default:
                    EmptyView()
                }
            }
            
            if viewModel.isLoading {
                MockInterviewLoadingOverlay(message: loadingMessage)
                    .transition(.opacity)
                    .zIndex(1) // Ensure overlay is always on top
            }
        }
        .navigationTitle("Mock Interview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.currentState != .setup {
                    Button(action: {
                        withAnimation(.spring()) {
                            viewModel.endInterview()
                        }
                    }) {
                        Text("End Interview")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppTheme.primary.opacity(0.1))
                            )
                    }
                }
            }
            
            ToolbarItem(placement: .keyboard) {
                if isResponseFocused {
                    Button("Done") {
                        isResponseFocused = false
                    }
                }
            }
        }
    }
   
    private var loadingMessage: String {
            switch viewModel.currentState {
            case .setup:
                return "Generating tailored questions for\n\(viewModel.jobTitle) position"
            case .reviewing:
                return "Analyzing your interview responses"
            default:
                return "Processing..."
            }
        }
    
    private var setupView: some View {
        VStack(spacing: 25) {
            Text("Setup Mock Interview")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.text)
                .opacity(isAnimating ? 1 : 0)
            
            // Job Title Input with modern styling
            VStack(alignment: .leading, spacing: 8) {
                Label("Job Title", systemImage: "briefcase.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.purple)
                
                TextField("e.g. iOS Developer", text: $viewModel.jobTitle)
                    .textFieldStyle(ModernTextFieldStyle())
                    .autocapitalization(.words)
            }
            .offset(y: isAnimating ? 0 : 20)
            .opacity(isAnimating ? 1 : 0)
            
            // Experience Level Picker with modern styling
            VStack(alignment: .leading, spacing: 8) {
                Label("Experience Level", systemImage: "chart.bar.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.purple)
                
                Picker("Experience Level", selection: $viewModel.experienceLevel) {
                    ForEach(ExperienceLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: AppTheme.shadowLight, radius: 10)
                )
            }
            .offset(y: isAnimating ? 0 : 20)
            .opacity(isAnimating ? 1 : 0)
            
            // Modern Start Button
            Button(action: {
                withAnimation(.spring()) {
                    viewModel.startInterview()
                }
            }) {
                Text("Start Interview")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: viewModel.canStartInterview ?
                                [AppTheme.purple, AppTheme.secondary] :
                                [Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(
                        color: viewModel.canStartInterview ?
                            AppTheme.purple.opacity(0.3) : Color.clear,
                        radius: 10, y: 5
                    )
            }
            .disabled(!viewModel.canStartInterview)
            .offset(y: isAnimating ? 0 : 20)
            .opacity(isAnimating ? 1 : 0)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: AppTheme.shadowLight, radius: 20)
        )
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    private var interviewView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Modern Progress and Counter
                VStack(spacing: 8) {
                    ProgressView(value: Double(viewModel.interview?.currentQuestionIndex ?? 0),
                               total: Double(viewModel.interview?.questions.count ?? 1))
                        .progressViewStyle(ModernProgressViewStyle())
                    
                    if let interview = viewModel.interview {
                        Text("Question \(interview.currentQuestionIndex + 1) of \(interview.questions.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.text.opacity(0.6))
                    }
                }
                .padding(.horizontal)
                
                if let interview = viewModel.interview {
                    QuestionCard(question: interview.questions[interview.currentQuestionIndex])
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your Response", systemImage: "text.bubble.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.purple)
                        
                        ResponseInput(text: $viewModel.currentResponse, isFocused: _isResponseFocused)
                    }
                    .padding(.horizontal)
                    
                    SubmitButton(action: {
                        isResponseFocused = false
                        withAnimation {
                            viewModel.submitResponse()
                        }
                    }, isEnabled: !viewModel.currentResponse.isEmpty)
                    .padding(.top)
                }
            }
            .padding(.vertical)
        }
        .background(Color.white.opacity(0.5))
    }
    
    private var analysisView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                Text("Interview Analysis")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("\(viewModel.jobTitle) - \(viewModel.experienceLevel.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Score Card
                ScoreCard(score: viewModel.interview?.analysis?.overallScore ?? 0)
                    .padding(.horizontal)
                
                // Strengths
                FeedbackSection(
                    title: "Key Strengths",
                    items: viewModel.interview?.analysis?.strengths ?? [],
                    color: .green
                )
                .padding(.horizontal)
                
                // Improvements
                FeedbackSection(
                    title: "Areas for Growth",
                    items: viewModel.interview?.analysis?.improvements ?? [],
                    color: .orange
                )
                .padding(.horizontal)
                
                // Detailed Feedback
                DetailedFeedbackSection(
                    feedback: viewModel.interview?.analysis?.detailedFeedback ?? []
                )
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        withAnimation {
                            viewModel.startNewInterview()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Start New Interview")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.gray)
                            .cornerRadius(15)
                    }
                }
                .padding()
            }
            .padding(.bottom, 30)
        }
        .background(Color.gray.opacity(0.05))
    }
}

// Supporting Views
struct QuestionCard: View {
    let question: InterviewQuestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question Type Badge
            HStack {
                Text(question.type.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(typeColor)
                    )
                
                Spacer()
                
                // Optional: Add question number or other metadata here
            }
            
            // Question Text
            ScrollView {
                Text(question.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 150) // Adjust this value as needed
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
        )
    }
    
    private var typeColor: Color {
        switch question.type {
        case .behavioral:
            return Color.blue
        case .technical:
            return Color.purple
        case .situational:
            return Color.green
        }
    }
}

struct ResponseInput: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    
    var body: some View {
        TextEditor(text: $text)
            .focused($isFocused)
            .frame(height: 150)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isFocused ? AppTheme.primary : AppTheme.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: AppTheme.shadowLight, radius: 10)
    }
}
struct SubmitButton: View {
    let action: () -> Void
    let isEnabled: Bool
    
    var body: some View {
        Button(action: action) {
            Text("Submit Response")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isEnabled ?
                    AppTheme.primary :
                    AppTheme.primary.opacity(0.5)
                )
                .cornerRadius(15)
        }
        .disabled(!isEnabled)
        .padding(.horizontal)
    }
}

// Modern TextFieldStyle
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: AppTheme.shadowLight, radius: 8)
    }
}

// Modern ProgressViewStyle
struct ModernProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0))
                    .frame(height: 8)
            }
        }
        .frame(height: 8)
    }
}
