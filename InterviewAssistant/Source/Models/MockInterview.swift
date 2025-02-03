//
//  MockInterview.swift
//  InterviewAssistant
//
//  Created by j0c1epm on 1/15/25.
//
import Foundation


// Interview Models
// In MockInterview.swift
enum ExperienceLevel: String, CaseIterable {
    case entry = "Entry"
    case mid = "Mid"
    case senior = "Senior"
    case lead = "Lead"
}

struct MockInterview: Identifiable {
    let id = UUID()
    let jobTitle: String
    let experienceLevel: ExperienceLevel
    let questions: [InterviewQuestion]
    var currentQuestionIndex: Int = 0
    var responses: [String] = []
    var analysis: InterviewAnalysis?
}

struct InterviewQuestion: Identifiable {
    let id = UUID()
    let text: String
    let type: QuestionType
    var response: String?
    
    enum QuestionType: String {
        case behavioral
        case technical
        case situational
    }
}

struct InterviewAnalysis {
    let overallScore: Int
    let strengths: [String]
    let improvements: [String]
    let detailedFeedback: [QuestionFeedback]
}

struct QuestionFeedback {
    let questionIndex: Int
    let score: Int
    let feedback: String
}
