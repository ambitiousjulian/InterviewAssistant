import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    var body: some View {
        TabView {
            LiveHelperView()
                .tabItem {
                    Label("Live Help", systemImage: "waveform.circle.fill")
                }
            
            MockInterviewView()
                .tabItem {
                    Label("Practice", systemImage: "person.2.fill")
                }
            
//            HistoryView()
//                .tabItem {
//                    Label("History", systemImage: "clock.fill")
//                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
        }
        .tint(AppTheme.primary)
        .onAppear {
            // Print resume analysis when the main tab view appears
            Task {
                if let userId = Auth.auth().currentUser?.uid {
                    do {
                        if let analysis = try await FirebaseManager.shared.getResumeAnalysis(userId: userId) {
                            print("Resume Analysis Found:")
                            print("Skills: \(analysis.skills.joined(separator: ", "))")
                            print("Summary: \(analysis.summary)")
                            print("Last Updated: \(analysis.lastUpdated)")
                        } else {
                            print("No resume analysis found")
                        }
                    } catch {
                        print("Error fetching resume analysis: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

struct InterviewListView: View {
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<5) { _ in
                    InterviewRowView()
                }
            }
            .navigationTitle("Interviews")
            .toolbar {
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}

struct InterviewRowView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mock Interview")
                .font(.headline)
            Text("Scheduled for tomorrow")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}
