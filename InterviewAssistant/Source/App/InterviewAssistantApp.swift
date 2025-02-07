import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct InterviewAssistantApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.showOnboarding && authViewModel.isAuthenticated {
                    OnboardingView()
                        .environmentObject(authViewModel)
                        .navigationViewStyle(StackNavigationViewStyle())
                } else {
                    MainTabView(selectedTab: authViewModel.isFirstTimeUser && authViewModel.isAuthenticated ? 2 : 0)
                        .environmentObject(authViewModel)
                        .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
