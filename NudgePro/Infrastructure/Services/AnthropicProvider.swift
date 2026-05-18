import Foundation

class AnthropicProvider: LLMProviderProtocol {
    let provider: LLMProvider = .anthropic
    private var apiKey: String
    private var model: String
    private var baseURL: String
    
    init(apiKey: String? = nil, model: String? = nil, baseURL: String? = nil) {
        let prefs = UserPreferences.shared
        self.apiKey = apiKey ?? prefs.anthropicAPIKey
        self.model = model ?? prefs.anthropicModel
        self.baseURL = baseURL ?? prefs.anthropicBaseURL
    }
    
    func checkAvailability() async -> Bool {
        guard !apiKey.isEmpty else { return false }
        return true
    }
    
    func validateAPIKey(_ apiKey: String) async -> Bool {
        guard !apiKey.isEmpty else { return false }
        
        guard let url = URL(string: "\(baseURL)/v1/messages") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1,
            "messages": [["role": "user", "content": "hi"]]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await NetworkConfig.sharedSession.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            return statusCode == 200 || statusCode == 400
        } catch {
            return false
        }
    }
    
    func extractActions(from transcript: String) async throws -> [ActionItem] {
        guard !apiKey.isEmpty else {
            throw LLMError.invalidAPIKey
        }
        
        let prompt = """
        Extract action items from the following meeting transcript. 
        Return ONLY a JSON array of action items with this exact format:
        [{"title": "action description", "assignee": "person name or null", "dueDate": "date or null"}]
        
        Transcript:
        \(transcript)
        
        JSON:
        """
        
        let response = try await callAnthropic(prompt: prompt)
        
        if let data = response.data(using: .utf8),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            var extractedActions: [ActionItem] = []
            for dict in jsonArray {
                if let task = dict["title"] as? String {
                    let action = ActionItem(
                        id: UUID(),
                        task: task,
                        assignee: dict["assignee"] as? String,
                        deadline: dict["dueDate"] as? String,
                        context: nil,
                        sourceQuote: nil,
                        confidence: 0.9,
                        status: .pending
                    )
                    extractedActions.append(action)
                }
            }
            return extractedActions
        }
        
        return []
    }
    
    func generateMeetingNotes(from transcript: String, actions: [ActionItem]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMError.invalidAPIKey
        }
        
        let actionsText = actions.isEmpty ? "No action items identified." : 
            actions.map { "- \($0.task)" }.joined(separator: "\n")
        
        let prompt = """
        Generate professional meeting notes from the following transcript.
        
        Include:
        1. Meeting Summary (2-3 sentences)
        2. Key Discussion Points (bullet list)
        3. Action Items
        4. Next Steps
        
        Transcript:
        \(transcript)
        
        Action Items:
        \(actionsText)
        
        Meeting Notes:
        """
        
        let response = try await callAnthropic(prompt: prompt)
        return response
    }
    
    private func callAnthropic(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/v1/messages") else {
            throw LLMError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = "You are a helpful assistant that extracts meeting notes and action items. Respond only with the requested format."
        
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": [["role": "user", "content": prompt]]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await NetworkConfig.sharedSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError("No response")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw LLMError.apiError(message)
            }
            throw LLMError.apiError("Status code: \(httpResponse.statusCode)")
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let content = json["content"] as? [[String: Any]],
           let firstBlock = content.first,
           let text = firstBlock["text"] as? String {
            return text
        }
        
        throw LLMError.invalidResponse
    }
}
