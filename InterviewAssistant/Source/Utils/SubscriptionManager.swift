//
//  SubscriptionManager.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 2/11/25.
//
import StoreKit
import FirebaseFirestore
import FirebaseAuth

class SubscriptionManager: ObservableObject {
    // MARK: - Singleton
    static let shared = SubscriptionManager()
    
    // MARK: - Constants
    private let maxFreeInterviews = 8
    private let defaults = UserDefaults.standard
    private let freeInterviewsKey = "freeInterviews"
    private let lastResetDateKey = "lastResetDate"
    
    // MARK: - Published Properties
    @Published private(set) var isSubscribed = false
    @Published private(set) var freeInterviewsRemaining: Int
    
    // MARK: - Initialization
    init() {
        self.freeInterviewsRemaining = maxFreeInterviews
        loadLocalState()
        
        Task {
            await loadSubscriptionStatus()
        }
    }
    
    // MARK: - Private Methods
    private func loadLocalState() {
        freeInterviewsRemaining = defaults.integer(forKey: freeInterviewsKey)
        if freeInterviewsRemaining == 0 {
            resetFreeInterviews()
        }
    }
    
    private func resetFreeInterviews() {
        freeInterviewsRemaining = maxFreeInterviews
        defaults.set(maxFreeInterviews, forKey: freeInterviewsKey)
        defaults.set(Date(), forKey: lastResetDateKey)
    }
    
    // MARK: - Public Methods
    func reset() {
        isSubscribed = false
        resetFreeInterviews()
    }
    
    @MainActor
    func loadSubscriptionStatus() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let status = try await FirebaseManager.shared.fetchSubscriptionStatus(userId: userId)
            isSubscribed = status.isSubscribed
            freeInterviewsRemaining = status.freeInterviewsRemaining
            defaults.set(freeInterviewsRemaining, forKey: freeInterviewsKey)
            
            print("📱 Loaded status - Subscribed: \(isSubscribed), Remaining: \(freeInterviewsRemaining)")
        } catch {
            print("❌ Failed to load subscription status: \(error)")
        }
    }
    
    @MainActor
    func useInterview() async {
        guard !isSubscribed && freeInterviewsRemaining > 0 else { return }
        
        print("📝 Using interview: \(freeInterviewsRemaining) remaining")
        
        // Update local state
        freeInterviewsRemaining -= 1
        defaults.set(freeInterviewsRemaining, forKey: freeInterviewsKey)
        
        // Update Firebase if authenticated
        if let userId = Auth.auth().currentUser?.uid {
            do {
                try await FirebaseManager.shared.decrementFreeInterviews(userId: userId)
                print("✅ Firebase updated successfully")
            } catch {
                print("❌ Failed to update Firebase: \(error)")
            }
        }
    }
    
    @MainActor
    func checkAndUpdateInterviewAvailability() async -> Bool {
        print("\n=== CHECKING AVAILABILITY ===")
        
        // Update from Firebase if logged in
        if let user = Auth.auth().currentUser {
            print("👤 User: \(user.email ?? "unknown")")
            await loadSubscriptionStatus()
        } else {
            print("ℹ️ Using local status")
        }
        
        print("📊 Status: subscribed=\(isSubscribed), remaining=\(freeInterviewsRemaining)")
        
        // Check if can proceed
        if !canUseInterview() {
            print("❌ Cannot proceed - no interviews available")
            return false
        }
        
        // Use interview if not subscribed
        if !isSubscribed {
            print("🎯 Using free interview")
            await useInterview()
            
            if !canUseInterview() {
                print("❌ No interviews remaining after use")
                return false
            }
            print("✅ Free interview used successfully")
        } else {
            print("✅ Proceeding with subscribed access")
        }
        
        print("=== AVAILABILITY CHECK COMPLETE ===\n")
        return true
    }
    
    @MainActor
    func updateSubscriptionStatus(isSubscribed: Bool, productId: String?) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user ID available for subscription update")
            return
        }
        
        print("📝 Updating subscription: isSubscribed=\(isSubscribed), productId=\(productId ?? "nil")")
        
        let newStatus = User.SubscriptionStatus(
            isSubscribed: isSubscribed,
            subscriptionId: UUID().uuidString,
            expirationDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            productId: productId,
            freeInterviewsRemaining: isSubscribed ? 0 : freeInterviewsRemaining
        )
        
        do {
            try await FirebaseManager.shared.updateSubscriptionStatus(userId: userId, status: newStatus)
            self.isSubscribed = isSubscribed
            print("✅ Subscription status updated successfully")
        } catch {
            print("❌ Failed to update subscription: \(error)")
        }
    }
    
    func canUseInterview() -> Bool {
        if isSubscribed {
            print("✅ User is subscribed")
            return true
        }
        
        let canUse = freeInterviewsRemaining > 0
        print(canUse ? "✅ Free interviews available: \(freeInterviewsRemaining)" : "❌ No free interviews remaining")
        return canUse
    }
}
