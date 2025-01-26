import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    @State var selectedTab: Int
    
    init(selectedTab: Int = 0) {
        _selectedTab = State(initialValue: selectedTab)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LiveHelperView()
                .tabItem {
                    Label("Live Help", systemImage: "waveform.circle.fill")
                }
                .tag(0)
            
            InterviewOptionsView()
                .tabItem {
                    Label("Practice", systemImage: "person.2.fill")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
        .tint(AppTheme.primary)
    }
}

// New view to choose interview type
struct InterviewOptionsView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: MockInterviewView()) {
                    InterviewOptionRow(
                        title: "Traditional Interview",
                        description: "Text-based mock interview with AI feedback",
                        icon: "text.bubble.fill"
                    )
                }
                
                NavigationLink(destination: ConversationalInterviewView()) {
                    InterviewOptionRow(
                        title: "Voice Interview",
                        description: "Interactive voice-based interview with AI",
                        icon: "waveform.circle.fill"
                    )
                }
            }
            .navigationTitle("Interview Practice")
        }
    }
}

struct InterviewOptionRow: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppTheme.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(AppTheme.primary.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}
