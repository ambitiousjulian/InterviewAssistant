//
//  AudioLevelMonitor.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/27/25.
//


// AudioLevelMonitor.swift
import Foundation
import AVFoundation

class AudioLevelMonitor: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    @Published var audioLevel: Float = 0.0
    
    func startMonitoring() {
        let audioSession = AVAudioSession.sharedInstance()
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentPath.appendingPathComponent("temp.wav")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.audioRecorder?.updateMeters()
                let level = self?.audioRecorder?.averagePower(forChannel: 0) ?? -160
                let normalizedLevel = max(0.0, (level + 160) / 160)
                self?.audioLevel = normalizedLevel
            }
        } catch {
            print("Audio monitoring failed to start: \(error)")
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        audioRecorder = nil
    }
}