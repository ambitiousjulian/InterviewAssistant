import Foundation
import NaturalLanguage
import UIKit
import FirebaseAuth

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
    let delta: Delta?
}

struct Delta: Codable {
    let text: String?
}

// MARK: - Anthropic Service
final class AnthropicService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    weak var delegate: AnthropicServiceDelegate?
    private var resumeAnalysis: User.ResumeAnalysis?
    
    private func createSystemPrompt() -> String {
        var prompt = """
        You are an expert interviewer and career coach for all fields and positions, including technical, creative, and business roles. When answering questions:
        - Adapt your response to the specific field and position context.
        - Use clear, concise, and impactful language relevant to the question.
        - Interpret ambiguous terms or incomplete questions in context, ensuring the most likely intended meaning is addressed.
        - Avoid unnecessary reasoning or apologies and directly provide the best possible answer.
        - Answer using the candidate's context for a more personal answer, when applicable.
        """
        
        if let analysis = resumeAnalysis {
            prompt += "\n\nCANDIDATE CONTEXT:"
            prompt += "\nSkills: \(analysis.skills.joined(separator: ", "))"
            prompt += "\nProfessional Summary: \(analysis.summary)"
            prompt += "\n\nPlease tailor responses to align with the candidate's background and expertise."
        }
        
        prompt += """
        \n\nQUESTION TYPE:
        [Behavioral, technical, situational, creative, leadership, etc.]

        SUGGESTED RESPONSE:
        [Provide a clear, concise, and professional response tailored to the specific field and position. Use STAR for behavioral questions. For technical fields, focus on accuracy and clarity. For creative roles, emphasize innovation and unique approaches. Keep responses under 512 tokens.]
        """
        
        return prompt
    }

    // MARK: - Initialization
    init() throws {
        guard let key = ConfigurationManager.getEnvironmentVar("ANTHROPIC_API_KEY"), !key.isEmpty else {
            throw AnthropicError.invalidAPIKey
        }
        self.apiKey = key
        
        // Fetch resume analysis during initialization
        Task {
            if let userId = Auth.auth().currentUser?.uid {
                do {
                    self.resumeAnalysis = try await FirebaseManager.shared.getResumeAnalysis(userId: userId)
                    print("Resume analysis loaded successfully")
                } catch {
                    print("Error loading resume analysis: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - API Methods
    func generateStreamingResponse(for question: String) async {
        let cleanedQuestion = cleanAndDisambiguateInput(question)
        
        guard let url = URL(string: baseURL) else {
            delegate?.anthropicService(self, didEncounterError: AnthropicError.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 20
        
        let payload: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 512,
            "temperature": 0.7,
            "stream": true,
            "system": createSystemPrompt(),
            "messages": [
                [
                    "role": "user",
                    "content": """
                    Provide a concise and tailored response for this interview question. Focus on the relevant field, position, and context, ensuring the answer is impactful and aligns with industry expectations, while keeping a casual tone. Speak in first person, like you are the one being interviewed: \(cleanedQuestion)
                    """
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (stream, response) = try await URLSession.shared.bytes(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw AnthropicError.invalidResponse
            }
            
            for try await line in stream.lines {
                if line.starts(with: "data: "), let data = line.dropFirst(6).data(using: .utf8) {
                    if let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data),
                       let content = chunk.delta?.text {
                        await MainActor.run { delegate?.anthropicService(self, didReceiveContent: content) }
                    }
                }
            }
            
            await MainActor.run { delegate?.anthropicServiceDidCompleteResponse(self) }
        } catch {
            await MainActor.run { delegate?.anthropicService(self, didEncounterError: error) }
        }
    }
    
    // MARK: - Input Cleaning
    private func cleanAndDisambiguateInput(_ input: String) -> String {
        let spellChecker = UITextChecker()
        let words = input.split(separator: " ")
        var correctedWords: [String] = []
        
        for word in words {
            let range = NSRange(location: 0, length: word.count)
            let misspelledRange = spellChecker.rangeOfMisspelledWord(
                in: String(word),
                range: range,
                startingAt: 0,
                wrap: false,
                language: "en"
            )
            
            if misspelledRange.location != NSNotFound {
                let guesses = spellChecker.guesses(forWordRange: misspelledRange, in: String(word), language: "en") ?? []
                correctedWords.append(guesses.first ?? String(word))
            } else {
                correctedWords.append(String(word))
            }
        }
        
        return correctedWords.joined(separator: " ")
    }
    
    func updateResumeAnalysis(_ analysis: User.ResumeAnalysis?) {
        self.resumeAnalysis = analysis
        print("[DEBUG] AnthropicService updated with resume analysis: \(analysis?.skills ?? [])")
    }
}
