import SwiftUI

@MainActor
class InterviewViewModel: ObservableObject {
    @Published var interviews: [Interview] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func fetchInterviews() async {
        isLoading = true
        defer { isLoading = false }
        
        // Implementation will go here
    }
}
