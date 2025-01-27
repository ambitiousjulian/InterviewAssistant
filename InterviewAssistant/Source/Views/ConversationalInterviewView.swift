//
//  ConversationalInterviewView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/23/25.
//


import SwiftUI
import AVFoundation
import Speech

struct ConversationalInterviewView: View {
    @StateObject private var viewModel = ConversationalInterviewViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
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
            
            if viewModel.isLoading {
                MockInterviewLoadingOverlay(message: loadingMessage)
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                switch viewModel.currentState {
                case .setup:
                    setupView
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .inProgress:
                    voiceInterviewView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                case .reviewing:
                    analysisView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle("Voice Interview")
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
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
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
            Text("Voice Interview Setup")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.text)
                .opacity(isAnimating ? 1 : 0)
            
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
            }
            .offset(y: isAnimating ? 0 : 20)
            .opacity(isAnimating ? 1 : 0)
            
            // Add this before the Start Interview button
            Toggle(isOn: $viewModel.shouldAutoStartSpeech) {
                HStack {
                    Image(systemName: "waveform.circle.fill")
                    Text("Auto AI Speaking")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.purple)
            }
            .padding(.horizontal)
            .tint(AppTheme.purple)

            
            Button(action: {
                withAnimation(.spring()) {
                    viewModel.startInterview()
                }
            }) {
                Text("Start Voice Interview")
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
    
    private var voiceInterviewView: some View {
        
        VStack(spacing: 20) {
            // Progress indicator
            ProgressView(value: Double(viewModel.interview?.currentQuestionIndex ?? 0),
                        total: Double(viewModel.interview?.questions.count ?? 1))
                .progressViewStyle(ModernProgressViewStyle())
                .padding()
            
            if let interview = viewModel.interview {
                // Question display
                QuestionCard(question: interview.questions[interview.currentQuestionIndex])
                    .padding(.horizontal)
                
                // AI Speaking indicator
                if viewModel.isAISpeaking {
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .foregroundColor(AppTheme.primary)
                            .font(.title)
                            .symbolEffect(.bounce, options: .repeating) // iOS 17+
                        Text("AI Speaking...")
                            .foregroundColor(AppTheme.primary)
                            .font(.headline)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: AppTheme.primary.opacity(0.2), radius: 5)
                    )
                }
                
                // Voice response section
                VStack(spacing: 15) {
                    if viewModel.isListening {
                        WaveformView(isAnimating: true)
                            .frame(height: 40)
                            .padding()
                    }
                    
                    // Updated recording controls
                    HStack {
                        // Only show start button if not recording or AI speaking
                        if !viewModel.isListening && !viewModel.isAISpeaking {
                            Button(action: {
                                viewModel.speakCurrentQuestion()
                            }) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                    Text("Start")
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [AppTheme.primary, AppTheme.secondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(25)
                                .shadow(color: AppTheme.primary.opacity(0.3), radius: 5)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer()
                        
                        // Enhanced recording button
                        Button(action: {
                            if viewModel.isListening {
                                // If there's text, clear it instead of submitting
                                if !viewModel.transcribedText.isEmpty {
                                    withAnimation {
                                        viewModel.clearRecording()
                                    }
                                } else {
                                    viewModel.stopRecording()
                                }
                            } else {
                                viewModel.startRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: viewModel.isListening ?
                                                [Color.red, Color.red.opacity(0.8)] :
                                                [AppTheme.primary, AppTheme.secondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 70, height: 70)
                                    .shadow(color: viewModel.isListening ?
                                        Color.red.opacity(0.3) :
                                        AppTheme.primary.opacity(0.3),
                                           radius: 8)
                                
                                Image(systemName: viewModel.isListening ?
                                    "stop.fill" : "mic.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(viewModel.isAISpeaking)
                    }
                    .padding()
                    
                    // Enhanced submit button
                    if !viewModel.transcribedText.isEmpty {
                        Text(viewModel.transcribedText)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                            )
                            .padding(.horizontal)
                        
                        Button(action: {
                            withAnimation {
                                viewModel.stopRecording()
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Submit Response")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: viewModel.isListening ?
                                        [AppTheme.successGreen, AppTheme.successGreen.opacity(0.8)] :
                                        [Color.gray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: viewModel.isListening ?
                                AppTheme.successGreen.opacity(0.3) : .clear,
                                   radius: 5)
                        }
                        .disabled(!viewModel.isListening)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAISpeaking)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isListening)
    }
    
    private var shouldShowRecordingControls: Bool {
        return !viewModel.isListening || viewModel.transcribedText.isEmpty
    }
    
    private var analysisView: some View {
        Group {
            if let analysis = viewModel.interview?.analysis {
                ScrollView {
                    VStack(spacing: 25) {
                        Text("Interview Analysis")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        Text("\(viewModel.jobTitle) - \(viewModel.experienceLevel.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        ScoreCard(score: analysis.overallScore)
                            .padding(.horizontal)
                        
                        FeedbackSection(
                            title: "Key Strengths",
                            items: analysis.strengths,
                            color: .green
                        )
                        .padding(.horizontal)
                        
                        FeedbackSection(
                            title: "Areas for Growth",
                            items: analysis.improvements,
                            color: .orange
                        )
                        .padding(.horizontal)
                        
                        DetailedFeedbackSection(feedback: analysis.detailedFeedback)
                            .padding(.horizontal)
                        
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
                        .padding()
                    }
                    .padding(.bottom, 30)
                }
                .background(Color.gray.opacity(0.05))
            } else {
                MockInterviewLoadingOverlay(message: loadingMessage)
            }
        }
    }
}

struct ModernButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                LinearGradient(
                    colors: isEnabled ?
                        [AppTheme.gradientStart, AppTheme.gradientEnd] :
                        [Color.gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: isEnabled ? AppTheme.gradientStart.opacity(0.3) : Color.clear,
                    radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6),
                      value: configuration.isPressed)
    }
}

struct PulsingRecordButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isRecording ?
                                [Color.red, Color.red.opacity(0.8)] :
                                [AppTheme.gradientStart, AppTheme.gradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: isRecording ?
                        Color.red.opacity(0.3) :
                        AppTheme.gradientStart.opacity(0.3),
                           radius: 10)
                
                if isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                        .frame(width: 90, height: 90)
                        .scaleEffect(isRecording ? 1.5 : 1)
                        .opacity(isRecording ? 0 : 1)
                        .animation(
                            .easeInOut(duration: 1)
                            .repeatForever(autoreverses: false),
                            value: isRecording
                        )
                }
                
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
