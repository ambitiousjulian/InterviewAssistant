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
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.gradient
                .opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                switch viewModel.currentState {
                case .setup:
                    setupView
                        .transition(.move(edge: .leading))
                case .inProgress:
                    interviewView
                        .transition(.move(edge: .trailing))
                case .reviewing:
                    analysisView
                        .transition(.move(edge: .trailing))
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle("Mock Interview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.currentState != .setup {
                    Button("End Interview") {
                        withAnimation {
                            viewModel.endInterview()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    private var setupView: some View {
        VStack(spacing: 25) {
            Text("Setup Mock Interview")
                .font(.title2)
                .fontWeight(.bold)
                .opacity(isAnimating ? 1 : 0)
            
            // Job Title Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Job Title")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("e.g. iOS Developer", text: $viewModel.jobTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
            }
            .offset(y: isAnimating ? 0 : 20)
            .opacity(isAnimating ? 1 : 0)
            
            // Experience Level Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Experience Level")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Picker("Experience Level", selection: $viewModel.experienceLevel) {
                    ForEach(ExperienceLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
            }
            .offset(y: isAnimating ? 0 : 20)
            .opacity(isAnimating ? 1 : 0)
            
            // Start Button
            Button(action: {
                withAnimation(.spring()) {
                    viewModel.startInterview()
                }
            }) {
                Text("Start Interview")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        viewModel.canStartInterview ?
                        AppTheme.primary :
                        AppTheme.primary.opacity(0.5)
                    )
                    .cornerRadius(15)
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 5)
            }
            .disabled(!viewModel.canStartInterview)
            .offset(y: isAnimating ? 0 : 20)
            .opacity(isAnimating ? 1 : 0)
        }
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    private var interviewView: some View {
        VStack(spacing: 20) {
            // Progress Bar
            ProgressView(value: Double(viewModel.interview?.currentQuestionIndex ?? 0),
                        total: Double(viewModel.interview?.questions.count ?? 1))
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.primary))
                .padding(.horizontal)
            
            // Question Counter
            if let interview = viewModel.interview {
                Text("Question \(interview.currentQuestionIndex + 1) of \(interview.questions.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Question Card
                QuestionCard(question: interview.questions[interview.currentQuestionIndex])
                    .padding(.horizontal)
                
                // Response Input
                ResponseInput(text: $viewModel.currentResponse)
                    .padding(.horizontal)
                
                // Submit Button
                SubmitButton(action: {
                    withAnimation {
                        viewModel.submitResponse()
                    }
                }, isEnabled: !viewModel.currentResponse.isEmpty)
            }
        }
        .padding(.vertical)
    }
    
    private var analysisView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Overall Score
                ScoreCard(score: viewModel.interview?.analysis?.overallScore ?? 0)
                    .padding(.horizontal)
                
                // Strengths
                FeedbackSection(
                    title: "Strengths",
                    items: viewModel.interview?.analysis?.strengths ?? [],
                    color: .green
                )
                .padding(.horizontal)
                
                // Improvements
                FeedbackSection(
                    title: "Areas for Improvement",
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
                HStack(spacing: 20) {
                    Button("Start New Interview") {
                        withAnimation {
                            viewModel.reset()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            }
        }
    }
}

// Supporting Views
struct QuestionCard: View {
    let question: InterviewQuestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(question.type.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(typeColor)
                    )
                
                Spacer()
            }
            
            Text(question.text)
                .font(.title3)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private var typeColor: Color {
        switch question.type {
        case .behavioral:
            return .blue
        case .technical:
            return .purple
        case .situational:
            return .green
        }
    }
}

struct ResponseInput: View {
    @Binding var text: String
    
    var body: some View {
        TextEditor(text: $text)
            .frame(height: 150)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(AppTheme.primary.opacity(0.1), lineWidth: 1)
            )
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
