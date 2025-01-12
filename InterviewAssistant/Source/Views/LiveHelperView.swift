//
//  LiveHelperView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//
import SwiftUI
import UIKit

struct LiveHelperView: View {
    @StateObject private var viewModel = LiveHelperViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    // Input Methods
                    inputMethodsCard
                    
                    // Question Display
                    questionCard
                    
                    Spacer()
                    
                    // Control Buttons
                    controlButtons
                }
                .padding()
                
                // Processing Overlay
                if viewModel.isProcessing {
                    ProcessingOverlay()
                }
                
                // Answer Sheet
                if viewModel.showingAnswer {
                    AnswerSheet(answer: viewModel.answer) {
                        viewModel.showingAnswer = false
                    }
                }
            }
            .navigationTitle("Live Interview Help")
            .sheet(isPresented: $viewModel.showingCamera) {
                ImageCaptureView { image in
                    viewModel.processImage(image)
                }
            }
        }
    }
    
    private var inputMethodsCard: some View {
        HStack(spacing: 20) {
            // Voice Input Button
            InputMethodButton(
                icon: "waveform.circle.fill",
                title: "Voice",
                isActive: viewModel.isRecording,
                action: {
                    viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
                }
            )
            
            // Camera Input Button
            InputMethodButton(
                icon: "camera.circle.fill",
                title: "Photo",
                isActive: false,
                action: {
                    viewModel.showingCamera = true
                }
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(radius: 5)
        )
    }
    
    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Question")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(viewModel.capturedText.isEmpty ? "Question will appear here..." : viewModel.capturedText)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 100)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                )
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 30) {
            if viewModel.isRecording {
                // Stop Button
                CircleButton(
                    icon: "stop.fill",
                    color: .red,
                    action: { viewModel.stopRecording() }
                )
            } else {
                // Record Button
                CircleButton(
                    icon: "mic.fill",
                    color: AppTheme.primary,
                    action: { viewModel.startRecording() }
                )
            }
        }
    }
}

struct InputMethodButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                Text(title)
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .foregroundColor(isActive ? .red : AppTheme.primary)
        }
    }
}

struct CircleButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 70, height: 70)
                    .shadow(radius: 5)
                
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
    }
}

struct AnswerSheet: View {
    let answer: String
    let dismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top)
            
            ScrollView {
                Text(answer)
                    .padding()
            }
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .ignoresSafeArea()
        )
        .transition(.move(edge: .bottom))
    }
}

struct ImageCaptureView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        
        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }
    }
}
