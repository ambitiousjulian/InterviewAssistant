struct SpeechControlButton: View {
    let isListening: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isListening ? Color.red : AppTheme.primary)
                    .frame(width: 60, height: 60)
                    .shadow(radius: 5)
                
                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 24))
            }
        }
    }
}

struct SpeechWaveformView: View {
    @State private var waveform: [CGFloat] = Array(repeating: 0.2, count: 5)
    let isAnimating: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(waveform.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.primary)
                    .frame(width: 3, height: 20 * waveform[index])
                    .animation(
                        Animation
                            .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            if isAnimating {
                animateWaveform()
            }
        }
    }
    
    private func animateWaveform() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            waveform = waveform.map { _ in CGFloat.random(in: 0.2...1.0) }
        }
    }
}