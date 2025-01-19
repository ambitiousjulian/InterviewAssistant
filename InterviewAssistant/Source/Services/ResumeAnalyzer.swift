import Foundation

// MARK: - Response Models
private struct AnthropicResponse: Codable {
    let content: [ContentItem]
    
    struct ContentItem: Codable {
        let text: String
        let type: String
    }
}

private struct AnalysisResult: Codable {
    let skills: [String]
    let summary: String
}

// MARK: - ResumeAnalyzer
class ResumeAnalyzer {
    static let shared: ResumeAnalyzer = {
        do {
            return try ResumeAnalyzer()
        } catch {
            fatalError("Failed to initialize ResumeAnalyzer: \(error.localizedDescription)")
        }
    }()
    
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    private init() throws {
        guard let key = ConfigurationManager.getEnvironmentVar("ANTHROPIC_API_KEY"), !key.isEmpty else {
            throw ResumeAnalyzerError.invalidAPIKey
        }
        self.apiKey = key
    }
    
    func analyzeResume(_ text: String) async throws -> User.ResumeAnalysis {
        print("\n=== Resume Analysis Started ===")
        print("Timestamp: \(Date())")
        
        let prompt = """
        Analyze this resume and provide only a JSON response in this exact format:
        {
            "skills": ["skill1", "skill2", ...],
            "summary": "A concise summary of the candidate's experience, education, and qualifications."
        }
        
        Resume text:
        \(text)
        """
        
        print("\nConstructing API Request...")
        
        let payload: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 1000
        ]
        
        guard let url = URL(string: baseURL) else {
            print("❌ Error: Invalid URL - \(baseURL)")
            throw ResumeAnalyzerError.invalidURL
        }
        
        print("📡 API Endpoint: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        do {
            let requestData = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = requestData
            
            print("\n🚀 Sending API Request...")
            print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            print("Request Payload: \(String(data: requestData, encoding: .utf8) ?? "Unable to read payload")")
            
            let requestStartTime = Date()
            let (data, response) = try await URLSession.shared.data(for: request)
            let requestDuration = Date().timeIntervalSince(requestStartTime)
            
            print("\n⏱ Request Duration: \(String(format: "%.2f", requestDuration))s")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Error: Invalid HTTP Response")
                throw ResumeAnalyzerError.invalidResponse
            }
            
            print("\n📥 Response Status Code: \(httpResponse.statusCode)")
            print("Response Headers: \(httpResponse.allHeaderFields)")
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ API Error Response: \(errorMessage)")
                throw ResumeAnalyzerError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            print("\n🔍 Decoding Response...")
            
            // Log raw response
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponse)")
            }
            
            // Decode the Anthropic response
            let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            print("\n✅ Successfully decoded Anthropic response")
            
            guard let contentText = anthropicResponse.content.first?.text else {
                print("❌ Error: No content text found in response")
                throw ResumeAnalyzerError.parseError("No content text found in response")
            }
            
            print("\n📝 Content Text: \(contentText)")
            
            guard let jsonStartIndex = contentText.firstIndex(of: "{"),
                  let jsonEndIndex = contentText.lastIndex(of: "}") else {
                print("❌ Error: Could not find JSON boundaries in content")
                throw ResumeAnalyzerError.parseError("Invalid response format")
            }
            
            // Extract the JSON portion
            let jsonString = String(contentText[jsonStartIndex...jsonEndIndex])
            print("\n🔍 Extracted JSON: \(jsonString)")
            
            // Parse the analysis result
            guard let jsonData = jsonString.data(using: .utf8),
                  let analysisResult = try? JSONDecoder().decode(AnalysisResult.self, from: jsonData) else {
                print("❌ Error: Failed to parse analysis result from JSON")
                throw ResumeAnalyzerError.parseError("Failed to parse analysis result")
            }
            
            print("\n✅ Successfully parsed analysis result")
            print("Skills found: \(analysisResult.skills.count)")
            print("Summary length: \(analysisResult.summary.count) characters")
            
            // Create ResumeAnalysis with current date
            let finalAnalysis = User.ResumeAnalysis(
                skills: analysisResult.skills,
                summary: analysisResult.summary,
                lastUpdated: Date()
            )
            
            print("\n=== Resume Analysis Completed Successfully ===")
            print("Total Skills: \(finalAnalysis.skills.count)")
            print("Summary Preview: \(String(finalAnalysis.summary.prefix(100)))...")
            print("Timestamp: \(finalAnalysis.lastUpdated)")
            
            return finalAnalysis
            
        } catch {
            print("\n❌ Error During Analysis:")
            print("Error Type: \(type(of: error))")
            print("Error Description: \(error.localizedDescription)")
            
            if let resumeError = error as? ResumeAnalyzerError {
                print("Resume Analyzer Error: \(resumeError)")
                throw resumeError
            }
            
            print("Network Error: \(error)")
            throw ResumeAnalyzerError.networkError(error)
        }
    }
}

// MARK: - Error Definitions
enum ResumeAnalyzerError: LocalizedError {
    case invalidAPIKey
    case invalidURL
    case networkError(Error)
    case serverError(statusCode: Int, message: String)
    case invalidResponse
    case parseError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .invalidURL:
            return "The API URL is invalid."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .invalidResponse:
            return "Invalid response from server."
        case .parseError(let message):
            return "Failed to parse response: \(message)"
        case .unknownError(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
}
