import Foundation
import FirebaseCore

struct User: Codable, Identifiable, Equatable {
    let id: String
    var email: String
    var name: String
    var resumeAnalysis: ResumeAnalysis?
    
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
            
            // Handle Timestamp conversion
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case resumeAnalysis
    }
}

extension User.ResumeAnalysis {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(skills, forKey: .skills)
        try container.encode(summary, forKey: .summary)
        try container.encode(Timestamp(date: lastUpdated), forKey: .lastUpdated)
    }
}
