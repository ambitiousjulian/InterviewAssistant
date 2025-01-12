import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    @StateObject private var viewModel = InterviewViewModel()
    
    var body: some View {
        TabView {
            InterviewListView()
                .tabItem {
                    Label("Interviews", systemImage: "video.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(AppTheme.primary)
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

struct ProfileView: View {
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                try? Auth.auth().signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}
