import SwiftUI
import AVFoundation
import Speech
import Foundation
import UIKit

class LiveHelperViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var capturedText = ""
    @Published var isProcessing = false
    @Published var answer = ""
    @Published var showingCamera = false
    @Published var showingAnswer = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    private let anthropicService: AnthropicService
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    // MARK: - Initialization
    init() {
        do {
            self.anthropicService = try AnthropicService()
        } catch {
            fatalError("Failed to initialize Anthropic service: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    func startRecording() {
        guard !isRecording else { return }
        
        checkPermissions { [weak self] granted in
            guard let self = self else { return }
            if granted {
                DispatchQueue.main.async {
                    self.setupAudioSession()
                    self.setupRecognition()
                    self.isRecording = true
                }
            } else {
                self.showPermissionError()
            }
        }
    }
    
    func dismissAnswer() {
        showingAnswer = false
        reset()
    }
    
    func reset() {
        // Clean up audio
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Reset audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        // Reset state
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.capturedText = ""
            self?.isProcessing = false
            self?.answer = ""
            self?.showingAnswer = false
            self?.errorMessage = nil
            self?.showError = false
        }
    }
    
    func clearState() {
        reset()
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        isRecording = false
        if !capturedText.isEmpty {
            processQuestion()
        } else {
            reset()
        }
    }
    
    func processImage(_ image: UIImage) {
        isProcessing = true
        // For MVP, process the question directly
        processQuestion()
    }
    
    // MARK: - Private Methods
    private func processQuestion() {
        guard !capturedText.isEmpty else {
            handleError("No question detected")
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                let response = try await anthropicService.generateResponse(for: capturedText)
                await MainActor.run {
                    self.answer = response
                    self.isProcessing = false
                    self.showingAnswer = true
                }
            } catch let error as AnthropicError {
                await MainActor.run {
                    self.handleError(error.errorDescription ?? "An error occurred")
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.handleError("Failed to generate response: \(error.localizedDescription)")
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            handleError("Failed to setup audio: \(error.localizedDescription)")
        }
    }
    
    private func setupRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            handleError("Speech recognition is not available")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            handleError("Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.capturedText = result.bestTranscription.formattedString
                }
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.handleError(error.localizedDescription)
                    self.stopRecording()
                }
            }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            handleError("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func checkPermissions(completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var microphoneGranted = false
        var speechGranted = false
        
        group.enter()
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            microphoneGranted = granted
            group.leave()
        }
        
        group.enter()
        SFSpeechRecognizer.requestAuthorization { status in
            speechGranted = (status == .authorized)
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(microphoneGranted && speechGranted)
        }
    }
    
    private func showPermissionError() {
        handleError("Please enable microphone and speech recognition in Settings")
    }
    
    private func handleError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
            self?.showError = true
            self?.isProcessing = false
            self?.isRecording = false
        }
    }
}
