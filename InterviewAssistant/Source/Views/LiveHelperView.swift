import SwiftUI
import UIKit

struct LiveHelperView: View {
    @StateObject private var viewModel = LiveHelperViewModel()
    @State private var isAnimating = false
    @EnvironmentObject var authViewModel: AuthViewModel

    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced Background with gradient overlay
                LinearGradient(
                    colors: [
                        AppTheme.primary.opacity(0.1),
                        AppTheme.secondary.opacity(0.1),
                        AppTheme.accent.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        inputMethodsCard
                            .offset(y: isAnimating ? 0 : -30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)
                        
                        questionCard
                            .offset(y: isAnimating ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isAnimating)
                        
                        Spacer(minLength: 43)
                        
                        controlButtons
                            .offset(y: isAnimating ? 0 : 50)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isAnimating)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                // Enhanced Overlays
                if viewModel.isProcessing {
                    ProcessingOverlay()
                        .transition(.opacity)
                }
                
                if viewModel.showingAnswer {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    AnswerSheet(viewModel: viewModel) {
                        withAnimation(.spring()) {
                            viewModel.dismissAnswer()
                        }
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Live Interview Helper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    helpButton
                        .tint(AppTheme.purple)
                }
            }
            .sheet(isPresented: $viewModel.showingCamera) {
                ImageCaptureView { image in
                    viewModel.processImage(image)
                }
            }
            .sheet(isPresented: $viewModel.showSubscriptionView) {
                SubscriptionView()
                    .environmentObject(authViewModel)
                    .interactiveDismissDisabled()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {
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
            viewModel.loadResumeAnalysis()

        }
    }
    
    private var inputMethodsCard: some View {
        VStack(spacing: 16) {
            Text("Select Input Method")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.text)
            
            HStack(spacing: 16) {
                InputMethodButton(
                    icon: "waveform.circle.fill",
                    title: "Voice Input",
                    subtitle: "Speak your question",
                    isActive: viewModel.isRecording,
                    gradientColors: [AppTheme.primary, AppTheme.secondary]
                ) {
                    withAnimation {
                        viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
                    }
                }
                
                InputMethodButton(
                    icon: "camera.circle.fill",
                    title: "Camera Input",
                    subtitle: "Scan your question",
                    isActive: false,
                    gradientColors: [AppTheme.purple, AppTheme.secondary]
                ) {
                    viewModel.showingCamera = true
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: AppTheme.shadowLight, radius: 15, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppTheme.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Your Question", systemImage: "text.bubble.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.purple)
                
                Spacer()
                
                if !viewModel.capturedText.isEmpty {
                    Button(action: { viewModel.clearState() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Clear")
                        }
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppTheme.secondary.opacity(0.1))
                        )
                    }
                }
            }
            
            Text(viewModel.capturedText.isEmpty ? "Your question will appear here..." : viewModel.capturedText)
                .font(.body)
                .foregroundColor(viewModel.capturedText.isEmpty ? AppTheme.text.opacity(0.5) : AppTheme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 120)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.surface.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: AppTheme.shadowLight, radius: 15, x: 0, y: 5)
        )
    }
    
    private var controlButtons: some View {
        VStack(spacing: 16) {
            if viewModel.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 8, height: 8)
                        .opacity(isAnimating ? 1 : 0.3)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: isAnimating)
                    
                    Text("Recording in progress...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(AppTheme.primary.opacity(0.1))
                )
            }
            
            ModernCircleButton(
                icon: viewModel.isRecording ? "stop.fill" : "mic.fill",
                gradientColors: viewModel.isRecording ?
                    [AppTheme.primary, AppTheme.primary.opacity(0.8)] :
                    [AppTheme.purple, AppTheme.secondary],
                size: 75
            ) {
                withAnimation {
                    viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
                }
            }
        }
        .padding(.bottom, 30)
    }
    
    private var helpButton: some View {
        Button(action: showHelp) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.purple)
        }
    }
    
    private func showHelp() {
        let alert = UIAlertController(
            title: "Next Job AI",
            message: """
                • Tap the microphone to start recording a question
                • Use the camera to capture written questions
                • Get instant help with your responses
                • Clear button removes current question

                Note: AI responses are generated in real-time and may occasionally contain inaccuracies. Please verify any specific claims or technical details.
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

// Updated InputMethodButton
struct InputMethodButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isActive: Bool
    let gradientColors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isActive ? gradientColors : [Color.white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 65, height: 65)
                        .shadow(
                            color: isActive ? gradientColors[0].opacity(0.3) : AppTheme.shadowLight,
                            radius: isActive ? 15 : 10
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(isActive ? .white : gradientColors[0])
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.text.opacity(0.6))
                }
            }
            .frame(width: 140)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(
                        color: isActive ? gradientColors[0].opacity(0.2) : AppTheme.shadowLight,
                        radius: isActive ? 15 : 10
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Updated ModernCircleButton
struct ModernCircleButton: View {
    let icon: String
    let gradientColors: [Color]
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: gradientColors[0].opacity(0.4),
                           radius: 15, x: 0, y: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct AnswerSheet: View {
    @ObservedObject var viewModel: LiveHelperViewModel // Change to use ViewModel
    @State private var isCopied = false

    let dismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top)
            
            ScrollView {
                Text(viewModel.currentResponse) // Use currentResponse instead of answer
                    .font(.body)
                    .lineSpacing(5)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.easeOut(duration: 0.2), value: viewModel.currentResponse)
            }
            
            if viewModel.isStreaming {
                // Show typing indicator while streaming
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 6, height: 6)
                            .opacity(0.5)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: viewModel.isStreaming
                            )
                    }
                }
                .padding(.bottom)
            } else {
                HStack(spacing: 15) {
                    Button(isCopied ? "Copied!" : "Copy") {
                            UIPasteboard.general.string = viewModel.currentResponse
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isCopied = false
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .foregroundColor(isCopied ? .green : .primary)
                    
                    Button("Done") {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dismiss()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.bottom)
            }
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
