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
            
            MockInterviewView()
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
