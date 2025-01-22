//
//  ConversationalInterviewViewModel.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/21/25.
//


import Foundation
import Speech
import AVFoundation

class ConversationalInterviewViewModel: ObservableObject {
    @Published var currentState: InterviewState = .setup
    @Published var jobTitle = ""
    @Published var experienceLevel: ExperienceLevel = .entry
    @Published var isVoiceEnabled = false
    
    @Published var currentQuestionIndex = 0
    @Published var isAISpeaking = false
    @Published var isListening = false
    @Published var transcribedText = ""
    
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    
    private var questions: [InterviewQuestion] = []
    private var responses: [String] = []
    
    enum InterviewState {
        case setup
        case interview
        case analysis
    }
    
    var canStartInterview: Bool {
        !jobTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var totalQuestions: Int {
        questions.count
    }
    
    var currentQuestion: String {
        guard currentQuestionIndex < questions.count else { return "" }
        return questions[currentQuestionIndex].text
    }
    
    init() {
        setupSpeech()
    }
    
    private func setupSpeech() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        Task {
            do {
                try await requestPermissions()
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "Failed to get speech recognition permissions"
                }
            }
        }
    }
    
    private func requestPermissions() async throws {
        // Request speech recognition authorization
        let granted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        
        guard granted else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized"])
        }
        
        // Request microphone permission
        let recordPermission = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        guard recordPermission else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Microphone access not granted"])
        }
    }
    
    func startInterview() {
        // Generate questions (you can use your existing question generation logic here)
        questions = generateQuestions()
        currentState = .interview
        speakCurrentQuestion()
    }
    
    private func generateQuestions() -> [InterviewQuestion] {
        // Your existing question generation logic
        // For now, returning sample questions
        return [
            InterviewQuestion(text: "Tell me about your background in software development", type: .behavioral),
            InterviewQuestion(text: "What's your experience with Swift and iOS development?", type: .technical)
            // Add more questions...
        ]
    }
    
    func speakCurrentQuestion() {
        isAISpeaking = true
        let utterance = AVSpeechUtterance(string: currentQuestion)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
        
        // When finished speaking, ready for user response
        synthesizer.delegate = self
    }
    
    func toggleRecording() {
        if isListening {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Implementation of speech recognition
        // (Similar to the previous SpeechManager implementation)
    }
    
    private func stopRecording() {
        // Stop recording implementation
    }
    
    func submitResponse() {
        responses.append(transcribedText)
        transcribedText = ""
        
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            speakCurrentQuestion()
        } else {
            currentState = .analysis
            generateAnalysis()
        }
    }
    
    private func generateAnalysis() {
        // Your existing analysis generation logic
    }
    
    func reset() {
        currentState = .setup
        jobTitle = ""
        experienceLevel = .entry
        isVoiceEnabled = false
        currentQuestionIndex = 0
        questions = []
        responses = []
        transcribedText = ""
    }
}

extension ConversationalInterviewViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isAISpeaking = false
        }
    }
}