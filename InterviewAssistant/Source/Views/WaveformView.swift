//
//  WaveformView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/23/25.
//
import SwiftUI

struct WaveformView: View {
    let isAnimating: Bool
    @State private var waveform: [CGFloat] = Array(repeating: 0.2, count: 5)
    
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
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    waveform = waveform.map { _ in CGFloat.random(in: 0.2...1.0) }
                }
            }
        }
    }
}
