//
//  MockInterviewViewModel.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/15/25.
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
                print("Processing completed response: \(self.currentGeneratedContent)") // Debug logging
                let questions = self.parseQuestionsFromResponse(self.currentGeneratedContent)
                
                if questions.isEmpty {
                    print("No questions parsed, handling error")
                    self.isLoading = false
                    return
                }
                
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
        print("Start Interview button clicked") // Debug: Check if button press is registered
        guard canStartInterview else {
            print("Cannot start interview: jobTitle is empty or invalid") // Debug: Check if validation fails
            return
        }
        
        print("Starting interview setup...") // Debug: Confirm interview setup begins
        isLoading = true
        currentState = .setup
        
        let prompt = """
        Generate exactly 6 interview questions for a \(jobTitle) position at \(experienceLevel.rawValue) level.

        Each question must be formatted exactly as shown below, with square brackets and a colon:
        [Question Type]: Question text

        Generate in this order:
        1. [Behavioral]: First behavioral question
        2. [Behavioral]: Second behavioral question
        3. [Technical]: First technical question
        4. [Technical]: Second technical question
        5. [Situational]: First situational question
        6. [Situational]: Second situational question

        Consider the following for \(experienceLevel.rawValue):
        - Entry Level: Focus on fundamental knowledge and potential
        - Mid Level: Balance technical skills with practical experience
        - Senior Level: Include system design and leadership scenarios
        - Lead/Manager: Focus on team management and strategic thinking

        Ensure questions are specifically tailored for a \(jobTitle) role at \(experienceLevel.rawValue) level.
        Each question should be separated by a blank line.
        """
        
        print("Prompt sent to Anthropic Service: \(prompt)") // Debug: Check if prompt is correctly formed
        
        Task {
            do {
                print("Calling AnthropService to generate questions...") // Debug: Indicate async call starts
                try await anthropicService.generateStreamingResponse(for: prompt)
                print("Questions generated successfully") // Debug: Confirm success
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Error generating questions: \(error)") // Debug: Print any error
                }
            }
        }
    }

    
    func submitResponse() {
        print("\n=== SUBMITTING RESPONSE ===")
        
        guard var interview = interview else {
            print("Error: No active interview found")
            return
        }
        
        print("Current question index: \(interview.currentQuestionIndex)")
        print("Total questions: \(interview.questions.count)")
        print("Current response length: \(currentResponse.count)")
        
        // Validate current index and response
        guard interview.currentQuestionIndex >= 0,
              interview.currentQuestionIndex < interview.questions.count,
              !currentResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Error: Invalid question index or empty response")
            return
        }
        
        // Update the response for the current question
        if interview.currentQuestionIndex < interview.responses.count {
            interview.responses[interview.currentQuestionIndex] = currentResponse
        } else {
            interview.responses.append(currentResponse)
        }
        print("Response saved successfully")
        
        // Move to next question or finish
        if interview.currentQuestionIndex < interview.questions.count - 1 {
            interview.currentQuestionIndex += 1
            print("Moving to question \(interview.currentQuestionIndex + 1)")
            self.interview = interview
            currentResponse = ""
        } else {
            print("All questions completed, moving to analysis")
            currentState = .reviewing
            self.interview = interview
            analyzeInterview()
        }
        
        print("=== RESPONSE SUBMISSION COMPLETE ===\n")
    }

    private func analyzeInterview() {
        print("\n=== STARTING INTERVIEW ANALYSIS ===")
        
        guard let interview = interview else {
            print("Error: No interview to analyze")
            return
        }
        
        // Validate responses
        guard interview.responses.count == interview.questions.count else {
            print("Error: Mismatch between questions (\(interview.questions.count)) and responses (\(interview.responses.count))")
            return
        }
        
        // Validate all responses have content
        guard !interview.responses.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            print("Error: Empty responses found")
            return
        }
        
        isLoading = true
        print("Preparing analysis for \(interview.jobTitle) position at \(interview.experienceLevel.rawValue) level")
        
        let questionsAndResponses = interview.questions.enumerated().map { index, question in
            """
            Question \(index + 1) [\(question.type.rawValue)]:
            \(question.text)
            
            Candidate Response:
            \(interview.responses[index])
            """
        }.joined(separator: "\n\n")
        
        let prompt = """
        You are an expert interviewer and career coach analyzing responses for a \(interview.jobTitle) position at \(interview.experienceLevel.rawValue) level.
        
        Interview Questions and Responses:
        \(questionsAndResponses)
        
        Provide a comprehensive analysis in exactly this format:
        
        OVERALL_SCORE: [Score 1-10]
        
        STRENGTHS:
        - [Specific strength with example from responses]
        - [Specific strength with example from responses]
        - [Specific strength with example from responses]
        
        IMPROVEMENTS:
        - [Specific improvement area with actionable suggestion]
        - [Specific improvement area with actionable suggestion]
        - [Specific improvement area with actionable suggestion]
        
        DETAILED_FEEDBACK:
        Q1: [Score 1-10] | [Detailed feedback with specific examples and improvement suggestions]
        Q2: [Score 1-10] | [Detailed feedback with specific examples and improvement suggestions]
        Q3: [Score 1-10] | [Detailed feedback with specific examples and improvement suggestions]
        Q4: [Score 1-10] | [Detailed feedback with specific examples and improvement suggestions]
        Q5: [Score 1-10] | [Detailed feedback with specific examples and improvement suggestions]
        Q6: [Score 1-10] | [Detailed feedback with specific examples and improvement suggestions]
        
        Base your analysis on:
        1. Role-specific competencies for \(interview.jobTitle)
        2. Experience level expectations for \(interview.experienceLevel.rawValue)
        3. Communication clarity and structure
        4. Specific examples provided
        5. Problem-solving approach
        6. Leadership and initiative shown
        """
        
        print("Analysis prompt prepared, sending to Anthropic Service")
        currentGeneratedContent = "" // Reset content before analysis
        
        Task {
            do {
                try await anthropicService.generateStreamingResponse(for: prompt)
                print("Analysis request sent successfully")
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Error during analysis: \(error.localizedDescription)")
                }
            }
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
        print("\n=== QUESTION PARSING START ===")
        print("Raw response received:")
        print(response)
        
        var questions: [InterviewQuestion] = []
        
        let pattern = #"\[(Behavioral|Technical|Situational)]:\s*(.+?)(?=\n\[|\z)"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let nsRange = NSRange(response.startIndex..<response.endIndex, in: response)
            let matches = regex.matches(in: response, options: [], range: nsRange)
            
            print("\nFound \(matches.count) questions")
            
            for match in matches {
                print("Match: \(response[Range(match.range, in: response)!])")
                guard let typeRange = Range(match.range(at: 1), in: response),
                      let questionRange = Range(match.range(at: 2), in: response) else { continue }

                let typeString = String(response[typeRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let questionText = String(response[questionRange]).trimmingCharacters(in: .whitespacesAndNewlines)

                guard let type = InterviewQuestion.QuestionType(rawValue: typeString.lowercased()) else {
                    print("Unknown question type: \(typeString)")
                    continue
                }

                questions.append(InterviewQuestion(text: questionText, type: type))
            }
            
            print("\n=== PARSING RESULTS ===")
            print("Total questions parsed: \(questions.count)")
            
            // Validate question distribution
            let behavioralCount = questions.filter { $0.type == .behavioral }.count
            let technicalCount = questions.filter { $0.type == .technical }.count
            let situationalCount = questions.filter { $0.type == .situational }.count
            
            print("Question distribution:")
            print("Behavioral: \(behavioralCount)")
            print("Technical: \(technicalCount)")
            print("Situational: \(situationalCount)")
            
            if questions.count != 6 || behavioralCount != 2 || technicalCount != 2 || situationalCount != 2 {
                print("Invalid question distribution, using fallback questions")
                return generateFallbackQuestions()
            }
            
        } catch {
            print("Regex error: \(error)")
            return generateFallbackQuestions()
        }
        
        print("=== PARSING COMPLETE ===")
        return questions
    }


    private func generateFallbackQuestions() -> [InterviewQuestion] {
        let fallbackQuestions = [
            // Behavioral Questions
            InterviewQuestion(
                text: "Tell me about a challenging situation you've faced in your role as a \(jobTitle). How did you handle it?",
                type: .behavioral
            ),
            InterviewQuestion(
                text: "Describe a time when you had to adapt to a significant change in your work environment.",
                type: .behavioral
            ),
            
            // Technical Questions
            InterviewQuestion(
                text: "What are the key technical skills and knowledge required for a \(jobTitle) position?",
                type: .technical
            ),
            InterviewQuestion(
                text: "How do you stay current with industry trends and best practices in your field?",
                type: .technical
            ),
            
            // Situational Questions
            InterviewQuestion(
                text: "How would you handle a situation where you disagree with a colleague's approach to solving a problem?",
                type: .situational
            ),
            InterviewQuestion(
                text: "If you were assigned a project with unclear requirements, what steps would you take?",
                type: .situational
            )
        ]
        
        return fallbackQuestions
    }
    
    private func parseAnalysisFromResponse(_ response: String) {
        print("\n=== PARSING ANALYSIS RESPONSE ===")
        print("Raw response:")
        print(response)
        
        guard var interview = interview else {
            print("Error: No interview found")
            return
        }
        
        let sections = response.components(separatedBy: "\n\n")
        
        // Parse overall score
        var overallScore = 0
        if let scoreLine = sections.first(where: { $0.contains("OVERALL_SCORE:") }) {
            let scoreComponents = scoreLine.components(separatedBy: ":")
            if scoreComponents.count > 1 {
                let scoreString = scoreComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
                overallScore = Int(scoreString.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) ?? 0
            }
        }
        
        // Parse strengths
        var strengths: [String] = []
        if let strengthsSection = sections.first(where: { $0.contains("STRENGTHS:") }) {
            strengths = strengthsSection
                .components(separatedBy: .newlines)
                .filter { $0.hasPrefix("-") }
                .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "- ")) }
        }
        
        // Parse improvements
        var improvements: [String] = []
        if let improvementsSection = sections.first(where: { $0.contains("IMPROVEMENTS:") }) {
            improvements = improvementsSection
                .components(separatedBy: .newlines)
                .filter { $0.hasPrefix("-") }
                .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "- ")) }
        }
        
        // Parse detailed feedback
        var detailedFeedback: [QuestionFeedback] = []
        if let feedbackSection = sections.first(where: { $0.contains("DETAILED_FEEDBACK:") }) {
            let feedbackLines = feedbackSection
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { $0.starts(with: "Q") }
            
            for line in feedbackLines {
                let parts = line.split(separator: "|", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { continue }
                
                let questionScorePart = parts[0].trimmingCharacters(in: .whitespaces)
                let feedbackText = parts[1].trimmingCharacters(in: .whitespaces)
                
                if let questionNumber = extractQuestionNumber(from: questionScorePart),
                   let score = extractScore(from: questionScorePart) {
                    detailedFeedback.append(QuestionFeedback(
                        questionIndex: questionNumber - 1,
                        score: score,
                        feedback: feedbackText
                    ))
                }
            }
            
            detailedFeedback.sort { $0.questionIndex < $1.questionIndex }
        }
        
        // Create and assign analysis
        let analysis = InterviewAnalysis(
            overallScore: overallScore,
            strengths: strengths,
            improvements: improvements,
            detailedFeedback: detailedFeedback
        )
        
        interview.analysis = analysis
        self.interview = interview
        self.showingAnalysis = true
        self.isLoading = false
    }

    // Helper functions
    private func extractQuestionNumber(from text: String) -> Int? {
        guard let qIndex = text.firstIndex(of: ":") else { return nil }
        let questionNumberStr = text.prefix(upTo: qIndex)
            .dropFirst() // Remove 'Q'
            .trimmingCharacters(in: .whitespaces)
        return Int(questionNumberStr)
    }

    private func extractScore(from text: String) -> Int? {
        guard let qIndex = text.firstIndex(of: ":") else { return nil }
        let scoreStr = text.suffix(from: qIndex)
            .dropFirst() // Remove ':'
            .trimmingCharacters(in: .whitespaces)
        return Int(scoreStr)
    }
}
