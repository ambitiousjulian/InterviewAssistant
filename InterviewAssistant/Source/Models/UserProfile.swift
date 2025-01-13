//
//  UserProfile.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//

//
//  User.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//


//
//  UserProfile.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//


// Source/Models/UserProfile.swift
import Foundation

struct UserProfile: Codable, Equatable {
    var id: String
    var name: String
    var email: String
    var jobPreferences: JobPreferences
    var experience: Experience
    
    struct JobPreferences: Codable, Equatable {
        var targetRole: String
        var targetIndustry: String
        var experienceLevel: ExperienceLevel
        
        enum ExperienceLevel: String, Codable, CaseIterable {
            case entry = "Entry Level"
            case midLevel = "Mid Level"
            case senior = "Senior Level"
            case executive = "Executive"
        }
    }
    
    struct Experience: Codable, Equatable {
        var yearsOfExperience: Int
        var currentRole: String
        var currentIndustry: String
    }
    
    // Custom Equatable implementation if needed
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.email == rhs.email &&
               lhs.jobPreferences == rhs.jobPreferences &&
               lhs.experience == rhs.experience
    }
}
