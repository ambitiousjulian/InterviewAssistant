//
//  AnthropicService.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//

import Foundation

// MARK: - Error Definitions
enum AnthropicError: LocalizedError {
    case invalidAPIKey
    case rateLimitExceeded
    case serverError(statusCode: Int)
    case networkError(Error)
    case invalidResponse
    case quotaExceeded
    case parseError(String)
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .rateLimitExceeded:
            return "Too many requests. Please try again in a moment."
        case .serverError(let code):
            return "Server error occurred (Code: \(code)). Please try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received invalid response from server."
        case .quotaExceeded:
            return "API quota exceeded. Please try again later."
        case .parseError(let detail):
            return "Failed to process response: \(detail)"
        case .invalidURL:
            return "Invalid API URL configuration."
        }
    }
}

// MARK: - Response Models
struct AnthropicResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [MessageContent]
    let model: String
    let stopReason: String?
    let usage: Usage
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case usage
    }
}

struct MessageContent: Codable {
    let type: String
    let text: String
}

struct Usage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Anthropic Service
final class AnthropicService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    let systemPrompt = """
    You are an elite interview coach specializing in preparing candidates for technical and behavioral interviews. Your goal is to help craft highly effective, professional, and concise answers tailored to interview success. When given an interview question:

    1. Identify the question type (e.g., behavioral, technical, situational, etc.) and provide a brief analysis.
    2. Deliver a structured response, prioritizing clarity and alignment with industry expectations. Use the STAR method where appropriate for behavioral questions.
    3. Highlight 2-3 key points that enhance the response's impact and relevance.
    4. Keep responses concise yet detailed enough to showcase expertise and experience.

    **Response Format:**

    QUESTION TYPE:
    [Brief analysis of the question type]

    KEY POINTS:
    • [Key Point 1]
    • [Key Point 2]
    • [Optional Key Point 3]

    SUGGESTED RESPONSE:
    [Provide a structured and polished answer. Use the STAR method when applicable.]

    TIPS:
    • [A practical tip or insight to enhance delivery or content]
    • [A suggestion for tone or body language alignment]

    **Tone:**
    Ensure the tone is confident, professional, and engaging, reflecting expertise and preparation, and sound human and not like an ai bot.
    """
    
    // MARK: - Initialization
    init() throws {
        guard let key = ConfigurationManager.getEnvironmentVar("ANTHROPIC_API_KEY"),
              !key.isEmpty else {
            throw AnthropicError.invalidAPIKey
        }
        self.apiKey = key
    }
    
    // MARK: - API Methods
    func generateResponse(for question: String, maxTokens: Int = 1024) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw AnthropicError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("anthropic-version: 2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "x-api-key")
        
        let payload: [String: Any] = [
            "model": "claude-3-sonnet-20240229",
            "max_tokens": maxTokens,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": "Help me answer this interview question professionally: \(question)"
                ]
            ]
        ]
        
        return try await performRequest(request: request, payload: payload)
    }
    
    // MARK: - Private Methods
    private func performRequest(request: URLRequest, payload: [String: Any]) async throws -> String {
        var request = request
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            try validateResponse(response)
            
            let apiResponse = try parseResponse(data)
            return formatResponse(apiResponse)
            
        } catch let error as AnthropicError {
            logError(error)
            throw error
        } catch {
            logError(error)
            throw AnthropicError.networkError(error)
        }
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnthropicError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw AnthropicError.invalidAPIKey
        case 429:
            throw AnthropicError.rateLimitExceeded
        case 500...599:
            throw AnthropicError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw AnthropicError.serverError(statusCode: httpResponse.statusCode)
        }
    }
    
    private func parseResponse(_ data: Data) throws -> AnthropicResponse {
        do {
            return try JSONDecoder().decode(AnthropicResponse.self, from: data)
        } catch {
            throw AnthropicError.parseError(error.localizedDescription)
        }
    }
    
    private func formatResponse(_ response: AnthropicResponse) -> String {
        return response.content.map { $0.text }.joined(separator: "\n")
    }
    
    private func logError(_ error: Error) {
        #if DEBUG
        print("🔴 Anthropic API Error: \(error.localizedDescription)")
        if let anthropicError = error as? AnthropicError {
            print("Type: \(String(describing: anthropicError))")
        }
        #endif
    }
}
