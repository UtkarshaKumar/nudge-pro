import Foundation

class CustomProvider: LLMProviderProtocol {
    let provider: LLMProvider = .custom
    private var apiKey: String
    private var baseURL: String
    private var model: String
    
    init(apiKey: String? = nil, baseURL: String? = nil, model: String? = nil) {
        let prefs = UserPreferences.shared
        self.apiKey = apiKey ?? prefs.customAPIKey
        self.baseURL = baseURL ?? prefs.customEndpoint
        self.model = model ?? prefs.customModel
    }
    
    func checkAvailability() async -> Bool {
        guard !baseURL.isEmpty else { return false }
        
        guard let url = URL(string: "\(baseURL)/models") else { return false }
        
        var request = URLRequest(url: url)
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return status == 200 || status == 401
        } catch {
            return false
        }
    }
    
    func validateAPIKey(_ apiKey: String) async -> Bool {
        guard !baseURL.isEmpty else { return false }
        return true
    }
    
    func extractActions(from transcript: String) async throws -> [ActionItem] {
        guard !baseURL.isEmpty else {
            throw LLMError.networkError("No endpoint configured")
        }
        
        let prompt = """
        Extract action items from the following meeting transcript. 
        Return ONLY a JSON array of action items with this exact format:
        [{"title": "action description", "assignee": "person name or null", "dueDate": "date or null"}]
        
        Transcript:
        \(transcript)
        
        JSON:
        """
        
        let response = try await callCustomAPI(prompt: prompt)
        
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
                        confidence: 0.8,
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
        guard !baseURL.isEmpty else {
            throw LLMError.networkError("No endpoint configured")
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
        
        let response = try await callCustomAPI(prompt: prompt)
        return response
    }
    
    private func callCustomAPI(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw LLMError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that extracts meeting notes and action items."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 1000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError("No response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LLMError.apiError("Status code: \(httpResponse.statusCode)")
        }
        
        // Try OpenAI-compatible response format
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        // Try Ollama response format
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let responseText = json["response"] as? String {
            return responseText
        }
        
        throw LLMError.invalidResponse
    }
}
