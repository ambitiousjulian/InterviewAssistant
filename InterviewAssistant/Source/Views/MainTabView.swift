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
            FeedbackView()
                .tabItem {
                    Label("Feedback", systemImage: "message.fill")
                }
                .tag(3)
        }
        .tint(AppTheme.primary)
    }
}

struct InterviewOptionsView: View {
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                GeometryReader { geometry in
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [AppTheme.primary.opacity(0.3), AppTheme.secondary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: geometry.size.width * 1.5)
                            .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.2)
                            .blur(radius: 50)
                            .opacity(isAnimating ? 0.8 : 0.3)
                        
                        Circle()
                            .fill(LinearGradient(
                                colors: [AppTheme.accent.opacity(0.2), AppTheme.purple.opacity(0.3)],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            ))
                            .frame(width: geometry.size.width)
                            .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.8)
                            .blur(radius: 50)
                            .opacity(isAnimating ? 0.8 : 0.3)
                    }
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                VStack(spacing: 30) {
                    Text("Choose Your\nInterview Style")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(AppTheme.text)
                        .multilineTextAlignment(.center)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    VStack(spacing: 25) {
                        InterviewOptionButton(
                            destination: MockInterviewView(),
                            title: "Traditional Interview",
                            description: "Text-based mock interview with AI feedback",
                            icon: "text.bubble.fill",
                            gradient: [Color(hex: "#FF6B6B"), Color(hex: "#4ECDC4")],
                            offset: isAnimating ? 0 : 100
                        )
                        
                        InterviewOptionButton(
                            destination: ConversationalInterviewView(),
                            title: "Voice Interview",
                            description: "Interactive voice-based interview with AI",
                            icon: "waveform.circle.fill",
                            gradient: [Color(hex: "#A8E6CF"), Color(hex: "#3498DB")],
                            offset: isAnimating ? 0 : 100
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }
}

struct InterviewOptionButton<Destination: View>: View {
    let destination: Destination
    let title: String
    let description: String
    let icon: String
    let gradient: [Color]
    let offset: CGFloat
    
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                    .shadow(color: gradient[0].opacity(0.3), radius: isPressed ? 5 : 15)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LinearGradient(
                                colors: gradient.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1)
            .offset(x: offset)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents(onPress: { isPressed = true },
                    onRelease: { isPressed = false })
    }
}

// Helper extension for press events
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}
