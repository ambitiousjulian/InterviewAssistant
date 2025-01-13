////
////  ViewModifiers.swift
////  InterviewAssistant
////
////  Created by Julian Cajuste on 1/12/25.
////
//
//import SwiftUI
//
//struct GlassomorphicBackground: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .background(
//                ZStack {
//                    Color.white.opacity(0.7)
//                        .blur(radius: 0.5)
//                    
//                    Color.clear
//                        .background(.ultraThinMaterial)
//                }
//            )
//            .cornerRadius(20)
//            .shadow(color: Color.black.opacity(0.1), radius: 10)
//    }
//}
//
//extension View {
//    func glassomorphic() -> some View {
//        modifier(GlassomorphicBackground())
//    }
//}
