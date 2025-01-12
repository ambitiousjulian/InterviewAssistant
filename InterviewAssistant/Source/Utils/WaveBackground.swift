//
//  WaveBackground.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//
// WaveBackground.swift
// Source/Utils/WaveBackground.swift
// Source/Utils/WaveBackground.swift
import SwiftUI

struct WaveBackground: View {
    @State private var phase = 0.0
    @State private var animating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Wave(phase: phase + Double(index) * .pi/2,
                         strength: 50,
                         frequency: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.primary.opacity(0.3 - Double(index) * 0.1),
                                    AppTheme.secondary.opacity(0.2 - Double(index) * 0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: geometry.size.height * 0.7)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                phase += .pi * 2
            }
        }
    }
}

struct Wave: Shape {
    var phase: Double
    var strength: Double
    var frequency: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        let width = Double(rect.width)
        let height = Double(rect.height)
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: height))
        
        var x: Double = 0
        while x <= width {
            let relativeX = x / width
            let normalizedX = relativeX * frequency
            let y = sin(normalizedX + phase) * strength + midHeight
            path.addLine(to: CGPoint(x: x, y: y))
            x += 1
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.close()
        
        return Path(path.cgPath)
    }
}

// Preview
struct WaveBackground_Previews: PreviewProvider {
    static var previews: some View {
        WaveBackground()
    }
}
