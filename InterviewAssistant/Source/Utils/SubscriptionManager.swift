//
//  SubscriptionManager.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 2/11/25.
//


// SubscriptionManager.swift
import StoreKit
import FirebaseFirestore

// SubscriptionManager.swift
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isSubscribed = false
    @Published var freeInterviewsRemaining = 1
    
    private let defaults = UserDefaults.standard
    private let maxFreeInterviews = 1
    private let lastResetDateKey = "lastResetDate"
    private let freeInterviewsKey = "freeInterviews"
    
    init() {
        loadState()
        checkAndResetDaily()
    }
    
    private func loadState() {
        freeInterviewsRemaining = defaults.integer(forKey: freeInterviewsKey)
        if freeInterviewsRemaining == 0 {
            freeInterviewsRemaining = maxFreeInterviews
            defaults.set(maxFreeInterviews, forKey: freeInterviewsKey)
        }
    }
    
    private func checkAndResetDaily() {
        let lastReset = defaults.object(forKey: lastResetDateKey) as? Date ?? Date()
        if !Calendar.current.isDate(lastReset, inSameDayAs: Date()) {
            freeInterviewsRemaining = maxFreeInterviews
            defaults.set(maxFreeInterviews, forKey: freeInterviewsKey)
            defaults.set(Date(), forKey: lastResetDateKey)
        }
    }
    
    func useInterview() {
        guard !isSubscribed && freeInterviewsRemaining > 0 else { return }
        freeInterviewsRemaining -= 1
        defaults.set(freeInterviewsRemaining, forKey: freeInterviewsKey)
    }
    
    func canUseInterview() -> Bool {
        isSubscribed || freeInterviewsRemaining > 0
    }
}
