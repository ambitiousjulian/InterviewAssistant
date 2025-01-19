//
//  ResumeAnalyzer.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/19/25.
//


// Source/Services/ResumeAnalyzer.swift
import Foundation

class ResumeAnalyzer {
    static let shared = ResumeAnalyzer()
    
    private init() {}
    
    func analyzeResume(_ text: String) async throws -> User.ResumeAnalysis {
        // TODO: Implement AI analysis here
        // For now, returning mock data
        return User.ResumeAnalysis(
            rawText: text,
            skills: ["Swift", "iOS Development", "UIKit", "SwiftUI"],
            education: [
                .init(institution: "Sample University",
                      degree: "Bachelor's",
                      fieldOfStudy: "Computer Science",
                      graduationYear: 2020)
            ],
            workExperience: [
                .init(company: "Tech Corp",
                      role: "iOS Developer",
                      startDate: Date(),
                      endDate: nil,
                      responsibilities: ["Developed iOS applications"])
            ],
            lastUpdated: Date()
        )
    }
}