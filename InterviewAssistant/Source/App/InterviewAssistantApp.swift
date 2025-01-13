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
            if authViewModel.isAuthenticated {
                MainTabView().preferredColorScheme(.light)
                // Additional force light mode at window level
                .onAppear {
                    UIWindow.appearance().overrideUserInterfaceStyle = .light
                }
            } else {
                LoginView().preferredColorScheme(.light)
                // Additional force light mode at window level
                .onAppear {
                    UIWindow.appearance().overrideUserInterfaceStyle = .light
                }
            }
        }
    }
}
