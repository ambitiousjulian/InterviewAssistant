//
//  AnthropicService.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//

import Foundation

// MARK: - Protocols
protocol AnthropicServiceDelegate: AnyObject {
    func anthropicService(_ service: AnthropicService, didReceiveContent content: String)
    func anthropicServiceDidCompleteResponse(_ service: AnthropicService)
    func anthropicService(_ service: AnthropicService, didEncounterError error: Error)
}

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
struct StreamChunk: Codable {
    let type: String?
    let message: Message?
    let delta: Delta?
}

struct Message: Codable {
    let content: [Content]?
}

struct Content: Codable {
    let text: String?
    let type: String?
}

struct Delta: Codable {
    let text: String?
}

// MARK: - Anthropic Service
final class AnthropicService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    weak var delegate: AnthropicServiceDelegate?
    
    private let systemPrompt = """
    You are an elite interview coach. Craft concise, professional, and impactful answers for technical and behavioral questions. Focus on clarity and relevance. Keep total response with 512 max tokens.

    RESPONSE FORMAT:

    QUESTION TYPE:
    [Behavioral, technical, situational, etc.]

    SUGGESTED RESPONSE:
    [Deliver a concise, polished answer. Use STAR for behavioral questions. If it may be a coding question provide clean concise code with a brief explanation if there is room, prioritze a code response.]
    """
    //
    //    KEY POINTS:
    //    - [Key Point 1]
    //    - [Key Point 2]
    //
    //    TIPS:
    //    - [Practical improvement tip]
    //    - [Advice on tone or delivery]
    //
    //    TONE:
    //    Confident, professional, and human-like—never robotic.
    
    // MARK: - Initialization
    init() throws {
        guard let key = ConfigurationManager.getEnvironmentVar("ANTHROPIC_API_KEY"),
              !key.isEmpty else {
            throw AnthropicError.invalidAPIKey
        }
        self.apiKey = key
        print("✅ Initialized with API key starting with: \(key.prefix(15))...")
    }
    
    // MARK: - API Methods
    func generateStreamingResponse(for question: String) async {
        guard let url = URL(string: baseURL) else {
            delegate?.anthropicService(self, didEncounterError: AnthropicError.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("true", forHTTPHeaderField: "stream")
        request.timeoutInterval = 30
        
        let payload: [String: Any] = [
            "model": "claude-3-sonnet-20240229",
            "max_tokens": 512,
            "temperature": 0.7,
            "stream": true,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": "Help me answer this interview question sounding human and not like an ai bot, keep it very clear, and ensure to keep total response under 512 max tokens: \(question)"
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (stream, response) = try await URLSession.shared.bytes(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AnthropicError.invalidResponse
            }
            
            for try await line in stream.lines {
                guard !line.isEmpty else { continue }
                if line.hasPrefix("data: "),
                   let data = line.dropFirst(6).data(using: .utf8) {
                    do {
                        let chunk = try JSONDecoder().decode(StreamChunk.self, from: data)
                        if let content = chunk.delta?.text {
                            await MainActor.run {
                                delegate?.anthropicService(self, didReceiveContent: content)
                            }
                        }
                    } catch {
                        print("Failed to decode chunk: \(error)")
                    }
                }
            }
            
            await MainActor.run {
                delegate?.anthropicServiceDidCompleteResponse(self)
            }
            
        } catch {
            await MainActor.run {
                delegate?.anthropicService(self, didEncounterError: error)
            }
        }
    }
    
    // MARK: - Error Handling
    private func logError(_ error: Error) {
        print("🔴 Anthropic API Error: \(error.localizedDescription)")
        if let anthropicError = error as? AnthropicError {
            print("Type: \(String(describing: anthropicError))")
        }
    }
}
