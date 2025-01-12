import SwiftUI
import AVFoundation
import Speech
import Foundation
import UIKit

class LiveHelperViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var capturedText = ""
    @Published var isProcessing = false
    @Published var answer = ""
    @Published var showingCamera = false
    @Published var showingAnswer = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
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
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        if !capturedText.isEmpty {
            processQuestion()
        }
    }
    
    func clearState() {
        capturedText = ""
        answer = ""
        isProcessing = false
        showingAnswer = false
        errorMessage = nil
        showError = false
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
    
    func processImage(_ image: UIImage) {
        isProcessing = true
        // For MVP, simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.processQuestion()
        }
    }
    
    private func processQuestion() {
        guard !capturedText.isEmpty else {
            handleError("No question detected")
            return
        }
        
        isProcessing = true
        // For MVP, simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            self.answer = """
                Here's how you might answer this question:
                
                Key Points:
                • Structure your response using the STAR method
                • Focus on specific, relevant examples
                • Keep your answer concise and professional
                
                Sample Response:
                [Your generated response would go here...]
                """
            self.isProcessing = false
            self.showingAnswer = true
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
