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
    
    
    // MARK: - Private Properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer: AVSpeechSynthesizer
    private var isAutoFlowEnabled = true
    
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
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
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
        guard var interview = interview else { return }
        
        cleanupAudioSession()
        
        if interview.currentQuestionIndex < interview.questions.count - 1 {
            interview.currentQuestionIndex += 1
            interviewState = .ready
            speakCurrentQuestion()
        } else {
            endInterview()
        }
    }

    // MARK: - Speech Methods
    func speakCurrentQuestion() {
        guard let interview = interview else { return }
        
        cleanupAudioSession()
        interviewState = .aiSpeaking
        isAISpeaking = true
        
        let utterance = AVSpeechUtterance(string: interview.questions[interview.currentQuestionIndex].text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
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
            try setupAudioSession()
            
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
    
    // MARK: - Response Handling
    override func submitResponse() {
        currentResponse = transcribedText
        transcribedText = ""
        
        super.submitResponse()
        
        if shouldAutoStartSpeech,
           let interview = interview,
           interview.currentQuestionIndex < interview.questions.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.speakCurrentQuestion()
            }
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension ConversationalInterviewViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isAISpeaking = false
            self.interviewState = .waitingForUserInput
            if self.isAutoFlowEnabled {
                self.startRecording()
            }
        }
    }
}
