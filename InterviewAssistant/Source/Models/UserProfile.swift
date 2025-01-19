//
//  UserProfile.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//


// Source/Models/UserProfile.swift
import Foundation

// Source/Models/User.swift
struct User: Codable, Identifiable, Equatable {
    let id: String
    var email: String
    var name: String
    var profileImageURL: String?
    var profile: Profile?
    var resumeAnalysis: ResumeAnalysis?
    
    struct Profile: Codable, Equatable {
        var jobPreferences: JobPreferences
        var experience: Experience
    }
    
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
    
    struct ResumeAnalysis: Codable, Equatable {
        var rawText: String
        var skills: [String]
        var education: [Education]
        var workExperience: [WorkExperience]
        var lastUpdated: Date
        
        struct Education: Codable, Equatable {
            var institution: String
            var degree: String
            var fieldOfStudy: String
            var graduationYear: Int?
        }
        
        struct WorkExperience: Codable, Equatable {
            var company: String
            var role: String
            var startDate: Date
            var endDate: Date?
            var responsibilities: [String]
        }
    }
}
