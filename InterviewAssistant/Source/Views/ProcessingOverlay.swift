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