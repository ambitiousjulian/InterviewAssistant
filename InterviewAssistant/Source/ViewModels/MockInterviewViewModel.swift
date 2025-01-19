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
    private var isResetting = false

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
        print("Start Interview button clicked")
            
        // Prevent starting new interview while resetting
        guard !isResetting else {
            print("Cannot start interview while resetting")
            return
        }
        
        guard canStartInterview else {
            print("Cannot start interview: jobTitle is empty or invalid")
            return
        }
        
        // Reset interview-specific state
        interview = nil
        currentResponse = ""
        currentGeneratedContent = ""
        
        print("Starting interview setup...")
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
        print("\n=== SUBMITTING RESPONSE ===")
        
        // Get trimmed response
        let trimmedResponse = currentResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard var interview = interview else {
            print("Error: No active interview found")
            return
        }
        
        print("Current question index: \(interview.currentQuestionIndex)")
        print("Total questions: \(interview.questions.count)")
        
        // Validate current index
        guard interview.currentQuestionIndex >= 0,
              interview.currentQuestionIndex < interview.questions.count else {
            print("Error: Invalid question index")
            return
        }
        
        // Update the response for the current question
        if interview.currentQuestionIndex < interview.responses.count {
            interview.responses[interview.currentQuestionIndex] = trimmedResponse
        } else {
            interview.responses.append(trimmedResponse)
        }
        print("Response saved successfully")
        
        // Clear current response BEFORE moving to next question
        self.currentResponse = ""
        
        // Move to next question or finish
        if interview.currentQuestionIndex < interview.questions.count - 1 {
            interview.currentQuestionIndex += 1
            print("Moving to question \(interview.currentQuestionIndex + 1)")
            self.interview = interview
        } else {
            print("All questions completed, moving to analysis")
            self.interview = interview
            DispatchQueue.main.async {
                self.currentState = .reviewing
                self.analyzeInterview()
            }
        }
        
        print("=== RESPONSE SUBMISSION COMPLETE ===\n")
    }

    private func generateFallbackAnalysis() -> InterviewAnalysis {
        return InterviewAnalysis(
            overallScore: 5,
            strengths: [
                "Shows basic understanding of the role",
                "Demonstrates willingness to learn",
                "Communicates clearly"
            ],
            improvements: [
                "Provide more specific examples",
                "Elaborate on technical knowledge",
                "Focus on quantifiable results"
            ],
            detailedFeedback: generateDefaultFeedback()
        )
    }
    private func generateDefaultFeedback() -> [QuestionFeedback] {
        return (0...5).map { index in
            QuestionFeedback(
                questionIndex: index,
                score: 5,
                feedback: "Standard response that meets basic requirements but needs more detail and specific examples."
            )
        }
    }
    private func analyzeInterview() {
        print("\n=== STARTING INTERVIEW ANALYSIS ===")
        
        guard let interview = interview else {
            print("Error: No interview to analyze")
            return
        }
        
        // Debug print all questions and responses
        print("\nDEBUG: All Questions and Responses:")
        for (index, question) in interview.questions.enumerated() {
            print("\nQuestion \(index + 1) [\(question.type.rawValue)]:")
            print(question.text)
            print("\nResponse:")
            if index < interview.responses.count {
                print(interview.responses[index])
            } else {
                print("NO RESPONSE")
            }
            print("-------------------")
        }
        
        let questionsAndResponses = interview.questions.enumerated().map { index, question in
            """
            Question \(index + 1) [\(question.type.rawValue)]:
            \(question.text)
            
            Candidate Response:
            \(interview.responses[index])
            """
        }.joined(separator: "\n\n")
        
        // Debug print the full prompt being sent
        print("\nDEBUG: Full Analysis Prompt:")
        print("----------------------------------------")
        print("""
        You are an expert interviewer and career coach analyzing responses for a \(interview.jobTitle) position at \(interview.experienceLevel.rawValue) level.
        
        Interview Questions and Responses:
        \(questionsAndResponses)
        """)
        print("----------------------------------------")
        
        let prompt = """
        You are an expert interviewer and career coach analyzing responses for a \(interview.jobTitle) position at \(interview.experienceLevel.rawValue) level. If a response is incoherent, irrelevant, or nonsensical, provide a lower score (1-3) and suggest improvements in clarity and relevance.

        
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
        Q1:[Score 1-10]|[Feedback for question 1]
        Q2:[Score 1-10]|[Feedback for question 2]
        Q3:[Score 1-10]|[Feedback for question 3]
        Q4:[Score 1-10]|[Feedback for question 4]
        Q5:[Score 1-10]|[Feedback for question 5]
        Q6:[Score 1-10]|[Feedback for question 6]
        
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
            } catch let error {
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
    
    func startNewInterview() {
        reset()
        // Add a slight delay to ensure clean state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentState = .setup
        }
    }
    
    func confirmEndInterview() {
        currentState = .reviewing
        analyzeInterview()
        showingEndInterviewAlert = false
    }

    func reset() {
        isResetting = true
        DispatchQueue.main.async {
            // Reset all state variables
            self.jobTitle = ""
            self.experienceLevel = .entry
            self.interview = nil
            self.currentResponse = ""
            self.currentState = .setup
            self.isLoading = false
            self.showingAnalysis = false
            self.currentGeneratedContent = ""
            self.showingEndInterviewAlert = false
            
            // Add a delay before allowing new interview to start
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isResetting = false
            }
        }
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
        print("Found \(sections.count) sections")
        
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
                .components(separatedBy: .newlines)
                .filter { $0.starts(with: "Q") }
            
            for line in feedbackLines {
                let components = line.components(separatedBy: "|")
                guard components.count == 2 else { continue }
                
                let scoreComponent = components[0].trimmingCharacters(in: .whitespaces)
                let feedback = components[1].trimmingCharacters(in: .whitespaces)
                
                if let questionNumber = Int(scoreComponent.dropFirst().prefix(1)),
                   let score = Int(scoreComponent.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)) {
                    detailedFeedback.append(QuestionFeedback(
                        questionIndex: questionNumber - 1,
                        score: score,
                        feedback: feedback
                    ))
                }
            }
        }
        
        // Create analysis object
        let analysis = InterviewAnalysis(
            overallScore: overallScore,
            strengths: strengths,
            improvements: improvements,
            detailedFeedback: detailedFeedback
        )
        
        // Directly assign the analysis to the interview
        interview.analysis = analysis
        
        // Update the published interview property
        DispatchQueue.main.async {
            self.interview = interview
            self.showingAnalysis = true
            self.isLoading = false
        }
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
