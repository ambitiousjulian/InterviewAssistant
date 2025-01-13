import SwiftUI
import UIKit

struct LiveHelperView: View {
    @StateObject private var viewModel = LiveHelperViewModel()
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.gradient
                    .opacity(0.1)
                    .ignoresSafeArea()
                
                // Main Content
                VStack(spacing: 25) {
                    // Mode Selection Card
                    inputMethodsCard
                        .offset(y: isAnimating ? 0 : -30)
                    
                    // Question Display
                    questionCard
                        .offset(y: isAnimating ? 0 : 30)
                    
                    Spacer()
                    
                    // Control Buttons
                    controlButtons
                        .offset(y: isAnimating ? 0 : 50)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Overlays
                if viewModel.isProcessing {
                    ProcessingOverlay()
                }
                
                if viewModel.showingAnswer {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    AnswerSheet(answer: viewModel.answer) {
                        viewModel.dismissAnswer()  // Use new method
                    }
                }
            }
            .navigationTitle("Live Interview Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: showHelp) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCamera) {
                ImageCaptureView { image in
                    viewModel.processImage(image)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
        .onDisappear {
            viewModel.reset()  // Clean up when view disappears
        }
    }
    
    private var inputMethodsCard: some View {
        VStack(spacing: 15) {
            Text("Choose Input Method")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            HStack(spacing: 20) {
                InputMethodButton(
                    icon: "waveform.circle.fill",
                    title: "Voice",
                    subtitle: "Record question",
                    isActive: viewModel.isRecording
                ) {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }
                
                InputMethodButton(
                    icon: "camera.circle.fill",
                    title: "Photo",
                    subtitle: "Capture text",
                    isActive: false
                ) {
                    viewModel.showingCamera = true
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: AppTheme.shadowLight, radius: 10)
        )
    }
    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Question")
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                
                Spacer()
                
                if !viewModel.capturedText.isEmpty {
                    Button("Clear") {
                        viewModel.clearState()
                    }
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondary)
                }
            }
            
            Text(viewModel.capturedText.isEmpty ? "Your question will appear here..." : viewModel.capturedText)
                .font(.body)
                .foregroundColor(viewModel.capturedText.isEmpty ? .gray : AppTheme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 100)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(AppTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(AppTheme.primary.opacity(0.1), lineWidth: 1)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: AppTheme.shadowLight, radius: 10)
        )
    }
    
    private var controlButtons: some View {
        VStack(spacing: 20) {
            if viewModel.isRecording {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(isAnimating ? 1 : 0.3)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: isAnimating)
                    
                    Text("Recording...")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            ModernCircleButton(
                icon: viewModel.isRecording ? "stop.fill" : "mic.fill",
                color: viewModel.isRecording ? .red : AppTheme.primary,
                size: 70
            ) {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            }
        }
        .padding(.bottom, 30)
    }
    
    private func showHelp() {
        let alert = UIAlertController(
            title: "Live Interview Help",
            message: """
                • Tap the microphone to start recording a question
                • Use the camera to capture written questions
                • Get instant help with your responses
                • Clear button removes current question
                """,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

struct InputMethodButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? AppTheme.primary.opacity(0.1) : AppTheme.surface)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isActive ? AppTheme.primary : AppTheme.text)
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.callout)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 120)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: isActive ? AppTheme.primary.opacity(0.2) : AppTheme.shadowLight,
                           radius: isActive ? 8 : 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ModernCircleButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .shadow(color: color.opacity(0.3),
                           radius: 10, x: 0, y: 5)
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct AnswerSheet: View {
    let answer: String
    let dismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top)
            
            ScrollView {
                Text(answer)
                    .font(.body)
                    .lineSpacing(5)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: 15) {
                Button("Copy") {
                    UIPasteboard.general.string = answer
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Done") {
                    withAnimation(.easeOut(duration: 0.2)) {
                        dismiss()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.bottom)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(25, corners: [.topLeft, .topRight])
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.medium)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(AppTheme.primary)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.medium)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(AppTheme.surface)
            .foregroundColor(AppTheme.text)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
