import Foundation
import FirebaseCore

struct User: Codable, Identifiable, Equatable {
    let id: String
    var email: String
    var name: String
    var resumeAnalysis: ResumeAnalysis?
    var subscriptionStatus: SubscriptionStatus
    
    // MARK: - ResumeAnalysis
    struct ResumeAnalysis: Codable, Equatable {
        var skills: [String]
        var summary: String
        var lastUpdated: Date
        
        enum CodingKeys: String, CodingKey {
            case skills
            case summary
            case lastUpdated
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            skills = try container.decode([String].self, forKey: .skills)
            summary = try container.decode(String.self, forKey: .summary)
            
            if let timestamp = try? container.decode(Timestamp.self, forKey: .lastUpdated) {
                lastUpdated = timestamp.dateValue()
            } else {
                lastUpdated = Date()
            }
        }
        
        init(skills: [String], summary: String, lastUpdated: Date) {
            self.skills = skills
            self.summary = summary
            self.lastUpdated = lastUpdated
        }
    }
    
    // MARK: - SubscriptionStatus
    struct SubscriptionStatus: Codable, Equatable {
        var isSubscribed: Bool
        var subscriptionId: String?
        var expirationDate: Date?
        var productId: String?
        var freeInterviewsRemaining: Int
        
        static var defaultStatus: SubscriptionStatus {
            print("Creating default subscription status")
            return SubscriptionStatus(
                isSubscribed: false,
                subscriptionId: nil,
                expirationDate: nil,
                productId: nil,
                freeInterviewsRemaining: 8
            )
        }
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case resumeAnalysis
        case subscriptionStatus
    }
    
    // MARK: - Initializers
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        
        // Optional fields with error handling
        do {
            resumeAnalysis = try container.decodeIfPresent(ResumeAnalysis.self, forKey: .resumeAnalysis)
        } catch {
            print("Error decoding resumeAnalysis: \(error)")
            resumeAnalysis = nil
        }
        
        // Handle subscription status with fallback
        do {
            subscriptionStatus = try container.decode(SubscriptionStatus.self, forKey: .subscriptionStatus)
        } catch {
            print("Error decoding subscriptionStatus: \(error), using default")
            subscriptionStatus = SubscriptionStatus.defaultStatus
        }
    }
    
    init(id: String, email: String, name: String, resumeAnalysis: ResumeAnalysis?, subscriptionStatus: SubscriptionStatus) {
        self.id = id
        self.email = email
        self.name = name
        self.resumeAnalysis = resumeAnalysis
        self.subscriptionStatus = subscriptionStatus
    }
}

// MARK: - ResumeAnalysis Extensions
extension User.ResumeAnalysis {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(skills, forKey: .skills)
        try container.encode(summary, forKey: .summary)
        try container.encode(Timestamp(date: lastUpdated), forKey: .lastUpdated)
    }
}

// MARK: - User Extensions
extension User {
    static func createDefault(withId id: String, email: String) -> User {
        return User(
            id: id,
            email: email,
            name: email.components(separatedBy: "@").first ?? "",
            resumeAnalysis: nil,
            subscriptionStatus: SubscriptionStatus.defaultStatus
        )
    }
}
