//
//  AudioWaveView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/27/25.
//
import SwiftUI

// AudioWaveView.swift (update the existing file)
struct AudioWaveView: View {
    let audioLevel: CGFloat
    @State private var waveOffset = 0.0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { _ in
            Canvas { context, size in
                // Draw multiple waves with different phases and amplitudes
                let waves = 3
                let baseAmplitude = size.height * 0.25 * audioLevel // Reduced amplitude for subtlety
                
                for wave in 0..<waves {
                    let opacity = 0.8 - Double(wave) * 0.2
                    let phase = waveOffset + Double(wave) * .pi / 4
                    let amplitude = baseAmplitude * (1.0 - Double(wave) * 0.2)
                    
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: size.height / 2))
                    
                    for x in 0...Int(size.width) {
                        let relativeX = Double(x) / 40.0 // Adjusted frequency
                        let y = sin(relativeX + phase) * amplitude
                        path.addLine(to: CGPoint(x: CGFloat(x), y: size.height / 2 + y))
                    }
                    
                    context.opacity = opacity
                    context.stroke(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.8)
                            ]),
                            startPoint: CGPoint(x: 0, y: size.height/2),
                            endPoint: CGPoint(x: size.width, y: size.height/2)
                        ),
                        lineWidth: 2
                    )
                }
            }
        }
        .onChange(of: audioLevel) { _ in
            withAnimation(.linear(duration: 0.05)) {
                waveOffset += 0.1
            }
        }
    }
}
