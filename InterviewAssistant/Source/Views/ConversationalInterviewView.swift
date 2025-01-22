//
//  ConversationalInterviewView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/21/25.
//


import SwiftUI
import AVFoundation
import Speech

struct ConversationalInterviewView: View {
    @StateObject private var viewModel = ConversationalInterviewViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    AppTheme.primary.opacity(0.1),
                    AppTheme.secondary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                switch viewModel.currentState {
                case .setup:
                    setupView
                case .interview:
                    interviewView
                case .analysis:
                    analysisView
                }
            }
        }
        .navigationTitle("AI Interview")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresenting: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var setupView: some View {
        VStack(spacing: 25) {
            Text("AI Interview Setup")
                .font(.title)
                .bold()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Job Title")
                    .font(.headline)
                TextField("e.g. iOS Developer", text: $viewModel.jobTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Experience Level")
                    .font(.headline)
                Picker("Experience Level", selection: $viewModel.experienceLevel) {
                    ForEach(ExperienceLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Toggle("Enable Voice Interview", isOn: $viewModel.isVoiceEnabled)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            
            Button(action: viewModel.startInterview) {
                Text("Start Interview")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .cornerRadius(10)
            }
            .disabled(!viewModel.canStartInterview)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }
    
    private var interviewView: some View {
        VStack(spacing: 20) {
            // Progress indicator
            ProgressView(value: Double(viewModel.currentQuestionIndex + 1),
                        total: Double(viewModel.totalQuestions))
                .padding()
            
            // AI Speaking indicator
            if viewModel.isAISpeaking {
                aiSpeakingView
            }
            
            // Current question display
            questionView
            
            // User response section
            responseView
            
            Spacer()
        }
        .padding()
    }
    
    private var aiSpeakingView: some View {
        HStack {
            Image(systemName: "waveform.circle.fill")
                .foregroundColor(AppTheme.primary)
                .font(.title)
            Text("AI Speaking...")
                .foregroundColor(AppTheme.primary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
    
    private var questionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.totalQuestions)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(viewModel.currentQuestion)
                .font(.title3)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
        }
    }
    
    private var responseView: some View {
        VStack(spacing: 15) {
            if viewModel.isListening {
                // Listening indicator
                VStack {
                    Text("Listening...")
                        .foregroundColor(.green)
                    WaveformView(isAnimating: true)
                }
            }
            
            // Transcribed text
            if !viewModel.transcribedText.isEmpty {
                Text(viewModel.transcribedText)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
            
            // Recording control button
            Button(action: viewModel.toggleRecording) {
                Image(systemName: viewModel.isListening ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(viewModel.isListening ? .red : .green)
            }
            
            // Submit button
            if !viewModel.transcribedText.isEmpty {
                Button(action: viewModel.submitResponse) {
                    Text("Submit Response")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primary)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private var analysisView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Interview Analysis")
                    .font(.title)
                    .bold()
                
                // Analysis content here (similar to your existing analysis view)
                
                Button("Start New Interview") {
                    viewModel.reset()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct WaveformView: View {
    let isAnimating: Bool
    @State private var waveform: [CGFloat] = Array(repeating: 0.2, count: 5)
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(waveform.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.primary)
                    .frame(width: 3, height: 20 * waveform[index])
                    .animation(
                        Animation
                            .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            if isAnimating {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    waveform = waveform.map { _ in CGFloat.random(in: 0.2...1.0) }
                }
            }
        }
    }
}