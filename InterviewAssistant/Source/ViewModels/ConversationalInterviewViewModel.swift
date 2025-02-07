//
//  ConversationalInterviewViewModel.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/23/25.
//
import Foundation
import Speech
import AVFoundation

class ConversationalInterviewViewModel: MockInterviewViewModel {
    // MARK: - Enums
    private enum InterviewState {
        case ready
        case aiSpeaking
        case waitingForUserInput
        case recording
        case processing
    }
    
    // MARK: - Published Properties
    @Published var isVoiceEnabled = true
    @Published var isAISpeaking = false
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var showError = false
    @Published var errorMessage = ""
    @Published private var interviewState: InterviewState = .ready
    @Published var shouldAutoStartSpeech = true
    @Published var isInAnalysisMode = false
    
    
    // MARK: - Private Properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer: AVSpeechSynthesizer
    private var isAutoFlowEnabled = true
    private var isLastQuestion: Bool {
        guard let interview = interview else { return false }
        return interview.currentQuestionIndex >= interview.questions.count - 1
    }
    
    // MARK: - Initialization
    override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        self.synthesizer = AVSpeechSynthesizer()
        super.init()
        self.synthesizer.delegate = self
        setupSpeech()
    }
    
    override func startInterview() {
        super.startInterview() // This calls the parent class's implementation
        if shouldAutoStartSpeech {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.speakCurrentQuestion()
            }
        }
    }
    
    // MARK: - Setup Methods
    private func setupSpeech() {
        Task {
            do {
                try await requestPermissions()
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "Failed to get speech permissions: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func requestPermissions() async throws {
        let granted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        
        guard granted else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized"])
        }
        
        let recordPermission = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        guard recordPermission else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Microphone access not granted"])
        }
    }
    
    // MARK: - Audio Session Management
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord,
                                      mode: .spokenAudio,
                                      options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Set preferred buffer duration and sample rate
        try audioSession.setPreferredIOBufferDuration(0.005)
        try audioSession.setPreferredSampleRate(44100.0)
        
        // Check and set input gain if supported
        if audioSession.isInputGainSettable {
            try audioSession.setInputGain(1.0) // Maximum gain
        } else {
            print("Input gain adjustment is not supported on this device.")
        }
    }
    
    private func cleanupAudioSession() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - Interview Flow Methods
    override func anthropicServiceDidCompleteResponse(_ service: AnthropicService) {
        DispatchQueue.main.async {
            switch self.currentState {
            case .setup:
                super.anthropicServiceDidCompleteResponse(service)
                if self.interview != nil {
                    self.speakCurrentQuestion()
                }
            case .reviewing:
                super.anthropicServiceDidCompleteResponse(service)
            default:
                break
            }
        }
    }
    
    func moveToNextQuestion() {
        print("\n=== MOVING TO NEXT QUESTION ===")
        
        guard var interview = interview else {
            print("No interview object available")
            return
        }
        
        guard !isInAnalysisMode else {
            print("In analysis mode, cannot move to next question")
            return
        }
        
        print("Current state:")
        print("- Current index: \(interview.currentQuestionIndex)")
        print("- Total questions: \(interview.questions.count)")
        
        cleanupAudioSession()
        
        if interview.currentQuestionIndex < interview.questions.count - 1 {
            interview.currentQuestionIndex += 1
            print("Advanced to next question:")
            print("- New index: \(interview.currentQuestionIndex)")
            
            self.interview = interview
            interviewState = .ready
            
            if shouldAutoStartSpeech {
                print("Scheduling speech with 0.5s delay")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else {
                        print("Self not available in async block")
                        return
                    }
                    
                    guard !self.isInAnalysisMode else {
                        print("Entered analysis mode during delay")
                        return
                    }
                    
                    print("Starting speech for question \(interview.currentQuestionIndex + 1)")
                    self.speakCurrentQuestion()
                }
            } else {
                print("Auto-speech disabled")
            }
        } else {
            print("Reached last question, ending interview")
            endInterview()
        }
        print("=== MOVE TO NEXT QUESTION COMPLETE ===\n")
    }


    // MARK: - Speech Methods
    // MARK: - Speech Methods
    func speakCurrentQuestion() {
        guard let interview = interview,
              interview.currentQuestionIndex < interview.questions.count else {
            print("ERROR: Invalid question index")
            return
        }
        
        cleanup()
        isAISpeaking = true
        
        do {
            try setupAudioSession()
            let questionText = interview.questions[interview.currentQuestionIndex].text
            let utterance = AVSpeechUtterance(string: questionText)
            
            utterance.voice = findMaleVoice()
            
            utterance.rate = 0.54
            utterance.pitchMultiplier = 0.95
            utterance.volume = 1.0
            
            synthesizer.speak(utterance)
        } catch {
            print("Failed to setup audio session: \(error)")
            isAISpeaking = false
        }
    }

    private func findMaleVoice() -> AVSpeechSynthesisVoice? {
        let maleVoiceIdentifiers = [
            "com.apple.ttsbundle.Alex-compact",
            "com.apple.ttsbundle.Daniel-compact",
            "com.apple.voice.compact.en-US.Alex"
        ]
        
        for identifier in maleVoiceIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                return voice
            }
        }
        
        return AVSpeechSynthesisVoice.speechVoices()
            .first { $0.language.hasPrefix("en-") }
    }
    
    // MARK: - Recording Methods
    func toggleRecording() {
        if isListening {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
                showError = true
                errorMessage = "Speech recognition is not available"
                return
            }
            
            do {
                cleanupAudioSession()
                
                // Configure audio session specifically for recording
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord,
                                           mode: .measurement,
                                           options: [.defaultToSpeaker, .allowBluetooth])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let recognitionRequest = recognitionRequest else { return }
                
                recognitionRequest.shouldReportPartialResults = true
                
                let inputNode = audioEngine.inputNode
            
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    DispatchQueue.main.async {
                        self.transcribedText = result.bestTranscription.formattedString
                    }
                }
                if error != nil {
                    self.stopRecording()
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            interviewState = .recording
            isListening = true
            
        } catch {
            showError = true
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func clearRecording() {
        cleanupAudioSession()
        isListening = false
        transcribedText = ""
        interviewState = .waitingForUserInput
    }
    
    // Add this cleanup method
    func cleanup() {
        cleanupAudioSession()
        synthesizer.stopSpeaking(at: .immediate)
        isListening = false
        isAISpeaking = false
        transcribedText = ""
        audioEngine.stop()
    }
    
    override func endInterview() {
        // First cleanup all audio-related activities
        cleanup()
        
        // Reset all states
        isListening = false
        isAISpeaking = false
        transcribedText = ""
        isInAnalysisMode = false
        
        // Call super to handle any parent class cleanup
        super.endInterview()
    }

    
    func stopRecording() {
        cleanupAudioSession()
        isListening = false
        interviewState = .processing
        
        if !transcribedText.isEmpty && isAutoFlowEnabled {
            submitResponse()
        } else {
            interviewState = .waitingForUserInput
        }
    }
    
    // Update startNewInterview to reset the analysis mode
    override func startNewInterview() {
        isInAnalysisMode = false
        cleanup()
        super.startNewInterview()
    }
    
    // Update submitResponse to check if we're in analysis mode
    override func submitResponse() {
        print("\n=== SUBMITTING RESPONSE ===")
        
        if isInAnalysisMode {
            print("In analysis mode, skipping response submission")
            return
        }
        
        guard var interview = self.interview else {
            print("No interview object available")
            return
        }
        
        let trimmedResponse = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedResponse.isEmpty {
            print("Empty response, skipping submission")
            return
        }
        
        // Save response
        if interview.currentQuestionIndex < interview.responses.count {
            interview.responses[interview.currentQuestionIndex] = trimmedResponse
        } else {
            interview.responses.append(trimmedResponse)
        }
        
        self.interview = interview
        transcribedText = "" // Clear transcribed text
        
        print("Current question index: \(interview.currentQuestionIndex)")
        print("Total questions: \(interview.questions.count)")
        
        if interview.currentQuestionIndex >= interview.questions.count - 1 {
            print("Final question completed, proceeding to analysis")
            cleanup()
            
            // Important: Update the state before starting analysis
            DispatchQueue.main.async {
                self.currentState = .reviewing // Set the state to reviewing
                self.isInAnalysisMode = true
                
                // Start analysis after a short delay to ensure state updates are processed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    super.analyzeInterview() // Call the parent class's analysis method
                }
            }
        } else {
            interview.currentQuestionIndex += 1
            self.interview = interview
            
            if shouldAutoStartSpeech {
                cleanup() // Ensure clean state before next question
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.speakCurrentQuestion()
                }
            }
        }
    }
}

extension ConversationalInterviewViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let interview = self.interview else { return }
            
            self.isAISpeaking = false
            
            // Always start recording after speech, even for the last question
            if self.shouldAutoStartSpeech && !self.isInAnalysisMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startRecording()
                }
            }
        }
    }
}
