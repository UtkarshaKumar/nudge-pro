import Foundation

class OllamaProvider: LLMProviderProtocol {
    let provider: LLMProvider = .ollama
    private let baseURL: String
    private let model: String
    
    init(baseURL: String? = nil, model: String? = nil) {
        let prefs = UserPreferences.shared
        self.baseURL = baseURL ?? prefs.ollamaBaseURL
        self.model = model ?? prefs.ollamaModel
    }
    
    func checkAvailability() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
        do {
            let (_, response) = try await NetworkConfig.sharedSession.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    func validateAPIKey(_ apiKey: String) async -> Bool {
        return true
    }
    
    func listAvailableModels() async -> [String] {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return [] }
        
        do {
            let (data, _) = try await NetworkConfig.sharedSession.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                return models.compactMap { $0["name"] as? String }
            }
        } catch {
            print("OllamaProvider: Failed to list models: \(error)")
        }
        return []
    }
    
    func extractActions(from transcript: String) async throws -> [ActionItem] {
        guard await checkAvailability() else {
            throw LLMError.ollamaNotRunning
        }
        
        let prompt = """
        Extract action items from the following meeting transcript. 
        Return ONLY a JSON array of action items with this exact format:
        [{"title": "action description", "assignee": "person name or nil", "dueDate": "date or nil"}]
        
        Transcript:
        \(transcript)
        
        JSON:
        """
        
        let response = try await callOllama(prompt: prompt)
        
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
        guard await checkAvailability() else {
            throw LLMError.ollamaNotRunning
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
        
        let response = try await callOllama(prompt: prompt)
        return response
    }
    
    private func callOllama(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            print("OllamaProvider: Invalid URL")
            throw LLMError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": 0.3,
                "num_predict": 1000
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("OllamaProvider: Calling model '\(model)' with prompt length: \(prompt.count)")
        
        let (data, response) = try await NetworkConfig.sharedSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("OllamaProvider: No HTTP response")
            throw LLMError.invalidResponse
        }
        
        print("OllamaProvider: Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorStr = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("OllamaProvider: Error response: \(errorStr)")
            throw LLMError.invalidResponse
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let generatedResponse = json["response"] as? String {
            print("OllamaProvider: Success, response length: \(generatedResponse.count)")
            return generatedResponse
        }
        
        print("OllamaProvider: Failed to parse response")
        throw LLMError.invalidResponse
    }
}
