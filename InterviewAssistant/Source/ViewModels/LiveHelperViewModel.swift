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
    
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func startRecording() {
        guard !isRecording else { return }
        setupAudioSession()
        setupRecognition()
        isRecording = true
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
        processQuestion()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupRecognition() {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio engine input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.capturedText = result.bestTranscription.formattedString
            }
            
            if error != nil {
                self.stopRecording()
            }
        }
        
        // Prepare and start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }
    }
    
    func processImage(_ image: UIImage) {
        isProcessing = true
        // Simulate processing for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.processQuestion()
        }
    }
    
    private func processQuestion() {
        isProcessing = true
        // Simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.answer = "Sample answer to demonstrate the interview response format..."
            self.isProcessing = false
            self.showingAnswer = true
        }
    }
    
    // Add permission checking
    func checkPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                let isAuthorized = status == .authorized
                completion(isAuthorized)
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}
