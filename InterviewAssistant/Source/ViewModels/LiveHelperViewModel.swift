import SwiftUI
import AVFoundation
import Speech
import Foundation
import Vision
import VisionKit
import UIKit
import FirebaseAuth

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
    @Published var currentResponse = ""
    @Published var isStreaming = false
    @Published var showSubscriptionView = false

    
    // MARK: - Private Properties
    private let anthropicService: AnthropicService
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    public let subscriptionManager = SubscriptionManager.shared
    private var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - Initialization
    init() {
        do {
            // Debug check for .env file
            if let path = Bundle.main.path(forResource: ".env", ofType: nil) {
                print("✅ Found .env file")
                if let key = ConfigurationManager.getEnvironmentVar("ANTHROPIC_API_KEY") {
                    print("✅ Found API key: \(key.prefix(8))...")
                } else {
                    print("❌ No API key found in .env")
                }
            } else {
                print("❌ No .env file found")
            }
            
            self.anthropicService = try AnthropicService()
            self.anthropicService.delegate = self
            
            // Load resume analysis immediately
            loadResumeAnalysis()
            
            // Add observers
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(resumeAnalysisUpdated),
                name: NSNotification.Name("ResumeAnalysisUpdated"),
                object: nil
            )
            
            // Add observer for app becoming active
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appBecameActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            
        } catch {
            print("❌ Anthropic Service Error: \(error.localizedDescription)")
            fatalError("Failed to initialize Anthropic service: \(error.localizedDescription)")
        }
    }
    
    @objc private func appBecameActive() {
        loadResumeAnalysis()
    }
    
    @objc private func resumeAnalysisUpdated(_ notification: Notification) {
        if let analysis = notification.userInfo?["analysis"] as? User.ResumeAnalysis {
            anthropicService.updateResumeAnalysis(analysis)
            print("[DEBUG] Resume analysis updated in LiveHelperViewModel")
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
    
    func loadResumeAnalysis() {
        guard let userId = currentUserId else { return }
        
        Task {
            do {
                if let analysis = try await FirebaseManager.shared.getResumeAnalysis(userId: userId) {
                    await MainActor.run {
                        self.anthropicService.updateResumeAnalysis(analysis)
                        print("[DEBUG] Resume analysis loaded successfully")
                    }
                }
            } catch {
                print("[ERROR] Failed to load resume analysis: \(error)")
            }
        }
    }
    
    func processImage(_ image: UIImage) {
        Task { @MainActor in
            // Check subscription first
            guard await checkSubscriptionAndProceed() else {
                return
            }
            
            self.isProcessing = true
            
            guard let cgImage = image.cgImage else {
                self.isProcessing = false
                self.handleError("Failed to process image")
                return
            }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage)
            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.isProcessing = false
                        self.handleError("Text recognition failed: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        self.isProcessing = false
                        self.handleError("No text found in image")
                        return
                    }
                    
                    let recognizedText = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }.joined(separator: " ")
                    
                    self.capturedText = recognizedText
                    if !recognizedText.isEmpty {
                        self.processQuestion()
                    } else {
                        self.isProcessing = false
                        self.handleError("No text detected in image")
                    }
                }
            }
            
            request.recognitionLevel = .accurate
            
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.handleError("Failed to process image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func processQuestion() {
        Task { @MainActor in
            guard !capturedText.isEmpty else {
                handleError("No question detected")
                return
            }
            
            // Check subscription first
            guard await checkSubscriptionAndProceed() else {
                return
            }
            
            isProcessing = true
            currentResponse = ""
            isStreaming = true
            
            do {
                try await anthropicService.generateStreamingResponse(for: capturedText)
            } catch {
                self.handleError("Failed to generate response: \(error.localizedDescription)")
                self.isProcessing = false
                self.isStreaming = false
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
    
    private func checkSubscriptionAndProceed() async -> Bool {
        print("\n=== CHECKING LIVE HELPER AVAILABILITY ===")
        
        // Check subscription status
        let canProceed = await subscriptionManager.checkAndUpdateInterviewAvailability()
        if !canProceed {
            print("❌ Cannot use Live Helper - showing subscription view")
            await MainActor.run {
                showSubscriptionView = true
            }
            return false
        }

        print("✅ Can proceed with Live Helper")
        return true
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// Add AnthropicServiceDelegate conformance
extension LiveHelperViewModel: AnthropicServiceDelegate {
    func anthropicService(_ service: AnthropicService, didReceiveContent content: String) {
        currentResponse += content
    }
    
    func anthropicServiceDidCompleteResponse(_ service: AnthropicService) {
        isProcessing = false
        isStreaming = false
        answer = currentResponse
        showingAnswer = true
    }
    
    func anthropicService(_ service: AnthropicService, didEncounterError error: Error) {
        handleError(error.localizedDescription)
        isProcessing = false
        isStreaming = false
    }
}
