//
//  ProcessingOverlay.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//


import SwiftUI

struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack {
                ProgressView()
                    .tint(.white)
                Text("Processing...")
                    .foregroundColor(.white)
            }
        }
    }
}