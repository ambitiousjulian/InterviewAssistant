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
    static let shared = SubscriptionManager()
        
    @Published var isSubscribed = false
    @Published var freeInterviewsRemaining = 1
    
    private let defaults = UserDefaults.standard
    private let freeInterviewsKey = "freeInterviews"
    
    init() {
        // Load from UserDefaults first
        freeInterviewsRemaining = defaults.integer(forKey: freeInterviewsKey)
        if freeInterviewsRemaining == 0 {
            freeInterviewsRemaining = 1
            defaults.set(1, forKey: freeInterviewsKey)
        }
        
        // Then try to load from Firebase if user is authenticated
        Task {
            await loadSubscriptionStatus()
        }
    }
    
    @MainActor
    func loadSubscriptionStatus() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let status = try await FirebaseManager.shared.fetchSubscriptionStatus(userId: userId)
            isSubscribed = status.isSubscribed
            freeInterviewsRemaining = status.freeInterviewsRemaining
        } catch {
            print("Failed to load subscription status: \(error)")
        }
    }
    
    @MainActor
   func useInterview() async {
       guard !isSubscribed && freeInterviewsRemaining > 0 else { return }
       
       // Decrement locally first
       freeInterviewsRemaining -= 1
       defaults.set(freeInterviewsRemaining, forKey: freeInterviewsKey)
       
       // Try to update Firebase if user is authenticated
       if let userId = Auth.auth().currentUser?.uid {
           do {
               try await FirebaseManager.shared.decrementFreeInterviews(userId: userId)
           } catch {
               print("Failed to update Firebase: \(error)")
           }
       }
   }
    
    @MainActor
    func updateSubscriptionStatus(isSubscribed: Bool, productId: String?) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
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
        } catch {
            print("Failed to update subscription status: \(error)")
        }
    }
    
    func canUseInterview() -> Bool {
        print("🔍 Checking interview availability:")
        print("Is subscribed: \(isSubscribed)")
        print("Free interviews remaining: \(freeInterviewsRemaining)")
        
        if isSubscribed { return true }
        if freeInterviewsRemaining <= 0 {
            print("❌ No free interviews remaining")
            return false
        }
        return true
    }
}
