//
//  MockInterviewViewModel.swift
//  InterviewAssistant
//
//  Created by j0c1epm on 1/15/25.
//
import SwiftUI
import AVFoundation
import Speech
import Foundation
import Vision
import VisionKit
import UIKit

class MockInterviewViewModel: ObservableObject, AnthropicServiceDelegate {
    // MARK: - Published Properties
    @Published var interview: MockInterview?
    @Published var currentState: InterviewState = .setup
    @Published var jobTitle: String = ""
    @Published var isLoading = false
    @Published var currentResponse: String = ""
    @Published var showingAnalysis = false
    @Published var currentGeneratedContent: String = ""
    @Published var experienceLevel: ExperienceLevel = .entry
    @Published var showingEndInterviewAlert = false
    
    // MARK: - Private Properties
    private let anthropicService: AnthropicService
    
    // MARK: - Computed Properties
    var canStartInterview: Bool {
        !jobTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Enums
    enum InterviewState {
        case setup
        case inProgress
        case responding
        case reviewing
        case complete
    }
    
    // MARK: - Initialization
    init() {
        self.anthropicService = try! AnthropicService()
        self.anthropicService.delegate = self
    }
    
    // MARK: - AnthropicServiceDelegate Methods
    func anthropicService(_ service: AnthropicService, didReceiveContent content: String) {
        DispatchQueue.main.async {
            self.currentGeneratedContent += content
        }
    }
    
    func anthropicServiceDidCompleteResponse(_ service: AnthropicService) {
        DispatchQueue.main.async {
            switch self.currentState {
            case .setup:
                let questions = self.parseQuestionsFromResponse(self.currentGeneratedContent)
                self.interview = MockInterview(
                    jobTitle: self.jobTitle,
                    experienceLevel: self.experienceLevel,
                    questions: questions
                )
                self.currentState = .inProgress
            case .reviewing:
                self.parseAnalysisFromResponse(self.currentGeneratedContent)
            default:
                break
            }
            self.isLoading = false
            self.currentGeneratedContent = ""
        }
    }
    
    func anthropicService(_ service: AnthropicService, didEncounterError error: Error) {
        DispatchQueue.main.async {
            print("Error: \(error.localizedDescription)")
            self.isLoading = false
        }
    }
    
    // MARK: - Interview Methods
    func startInterview() {
        isLoading = true
        currentState = .setup
        
        let prompt = """
        Generate 6 interview questions for a \(jobTitle) position at \(experienceLevel.rawValue) level.
        
        Consider the following:
        - For Entry Level: Focus on fundamental knowledge and potential
        - For Mid Level: Balance technical skills with practical experience
        - For Senior Level: Include system design and leadership scenarios
        - For Lead/Manager: Focus on team management and strategic thinking
        
        Include:
        - 2 behavioral questions appropriate for \(experienceLevel.rawValue)
        - 2 technical questions matching \(experienceLevel.rawValue) expectations
        - 2 situational questions relevant to \(experienceLevel.rawValue) responsibilities
        
        Format each question as:
        [Question Type]: [Question Text]
        
        Ensure questions are specifically tailored for a \(jobTitle) role at \(experienceLevel.rawValue) level.
        """
        
        Task {
            do {
                try await anthropicService.generateStreamingResponse(for: prompt)
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Error generating questions: \(error)")
                }
            }
        }
    }
    
    func submitResponse() {
        guard var interview = interview else { return }
        interview.responses.append(currentResponse)
        
        if interview.currentQuestionIndex < interview.questions.count - 1 {
            interview.currentQuestionIndex += 1
            self.interview = interview
            currentResponse = ""
        } else {
            currentState = .reviewing
            analyzeInterview()
        }
    }
    
    func endInterview() {
        if currentState == .inProgress {
            showingEndInterviewAlert = true
        } else {
            reset()
        }
    }
    
    func confirmEndInterview() {
        currentState = .reviewing
        analyzeInterview()
        showingEndInterviewAlert = false
    }
    
    func reset() {
        jobTitle = ""
        experienceLevel = .entry
        interview = nil
        currentResponse = ""
        currentState = .setup
        isLoading = false
        showingAnalysis = false
        currentGeneratedContent = ""
        showingEndInterviewAlert = false
    }
    
    // MARK: - Private Methods
    private func parseQuestionsFromResponse(_ response: String) -> [InterviewQuestion] {
        var questions: [InterviewQuestion] = []
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            if line.isEmpty { continue }
            
            let components = line.components(separatedBy: ":")
            guard components.count >= 2 else { continue }
            
            let typeString = components[0].trimmingCharacters(in: .whitespaces).lowercased()
            let questionText = components[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
            
            let type: InterviewQuestion.QuestionType
            switch typeString {
            case _ where typeString.contains("behavioral"):
                type = .behavioral
            case _ where typeString.contains("technical"):
                type = .technical
            case _ where typeString.contains("situational"):
                type = .situational
            default:
                continue
            }
            
            questions.append(InterviewQuestion(text: questionText, type: type))
        }
        
        return questions
    }
    
    private func analyzeInterview() {
        guard let interview = interview else { return }
        isLoading = true
        
        let prompt = """
        Analyze these interview responses for a \(interview.jobTitle) position at \(interview.experienceLevel.rawValue) level:
        
        Questions and Responses:
        \(interview.questions.enumerated().map { index, question in
            """
            Q\(index + 1) [\(question.type.rawValue)]: \(question.text)
            Response: \(interview.responses[index])
            """
        }.joined(separator: "\n\n"))
        
        Provide a structured analysis in this format:
        
        OVERALL_SCORE: [1-10]
        
        STRENGTHS:
        - [Strength 1]
        - [Strength 2]
        - [Strength 3]
        
        IMPROVEMENTS:
        - [Improvement 1]
        - [Improvement 2]
        - [Improvement 3]
        
        DETAILED_FEEDBACK:
        [Question 1]: [Score 1-10] | [Specific feedback]
        [Question 2]: [Score 1-10] | [Specific feedback]
        ...
        
        Consider the \(interview.experienceLevel.rawValue) level expectations when analyzing.
        """
        
        Task {
            do {
                try await anthropicService.generateStreamingResponse(for: prompt)
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Error analyzing interview: \(error)")
                }
            }
        }
    }
    
    private func parseAnalysisFromResponse(_ response: String) {
        guard var interview = interview else { return }
        
        let sections = response.components(separatedBy: "\n\n")
        
        if let scoreLine = sections.first(where: { $0.contains("OVERALL_SCORE:") }) {
            let score = scoreLine.components(separatedBy: ":")[1]
                .trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .newlines)[0]
            
            let overallScore = Int(score) ?? 0
            
            var strengths: [String] = []
            if let strengthsSection = sections.first(where: { $0.contains("STRENGTHS:") }) {
                strengths = strengthsSection
                    .components(separatedBy: .newlines)
                    .filter { $0.hasPrefix("-") }
                    .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "- ")) }
            }
            
            var improvements: [String] = []
            if let improvementsSection = sections.first(where: { $0.contains("IMPROVEMENTS:") }) {
                improvements = improvementsSection
                    .components(separatedBy: .newlines)
                    .filter { $0.hasPrefix("-") }
                    .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "- ")) }
            }
            
            var detailedFeedback: [QuestionFeedback] = []
            if let feedbackSection = sections.first(where: { $0.contains("DETAILED_FEEDBACK:") }) {
                let feedbackLines = feedbackSection
                    .components(separatedBy: .newlines)
                    .filter { $0.contains("|") }
                
                for (index, line) in feedbackLines.enumerated() {
                    let parts = line.components(separatedBy: "|")
                    if parts.count >= 2 {
                        let scorePart = parts[0].components(separatedBy: ":")[1]
                        let score = Int(scorePart.trimmingCharacters(in: .whitespaces)) ?? 0
                        let feedback = parts[1].trimmingCharacters(in: .whitespaces)
                        
                        detailedFeedback.append(QuestionFeedback(
                            questionIndex: index,
                            score: score,
                            feedback: feedback
                        ))
                    }
                }
            }
            
            let analysis = InterviewAnalysis(
                overallScore: overallScore,
                strengths: strengths,
                improvements: improvements,
                detailedFeedback: detailedFeedback
            )
            
            interview.analysis = analysis
            self.interview = interview
            self.showingAnalysis = true
        }
    }
}
