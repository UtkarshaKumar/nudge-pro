import Foundation

class LLMService {
    private var currentProvider: LLMProviderProtocol?
    private let preferences = UserPreferences.shared
    
    init() {
        updateProvider()
    }
    
    private func updateProvider() {
        let providerType = preferences.llmProvider
        
        switch providerType {
        case .ollama:
            currentProvider = OllamaProvider(model: preferences.ollamaModel)
        case .openai:
            currentProvider = OpenAIProvider(apiKey: preferences.openAIAPIKey, model: preferences.openAIModel)
        case .anthropic:
            currentProvider = AnthropicProvider(apiKey: preferences.anthropicAPIKey, model: preferences.anthropicModel)
        case .custom:
            currentProvider = CustomProvider(
                apiKey: preferences.customAPIKey,
                baseURL: preferences.customEndpoint,
                model: preferences.customModel
            )
        }
    }
    
    func checkAvailability() async -> Bool {
        updateProvider()
        guard let provider = currentProvider else {
            return false
        }
        return await provider.checkAvailability()
    }
    
    func extractActions(from transcript: String) async throws -> [ActionItem] {
        updateProvider()
        guard let provider = currentProvider else {
            throw LLMError.noProvider
        }
        return try await provider.extractActions(from: transcript)
    }
    
    func generateMeetingNotes(from transcript: String, actions: [ActionItem]) async throws -> String {
        updateProvider()
        guard let provider = currentProvider else {
            throw LLMError.noProvider
        }
        return try await provider.generateMeetingNotes(from: transcript, actions: actions)
    }
    
    func validateProvider(_ provider: LLMProvider, apiKey: String) async -> Bool {
        switch provider {
        case .ollama:
            return await OllamaProvider().checkAvailability()
        case .openai:
            return await OpenAIProvider(apiKey: apiKey).validateAPIKey(apiKey)
        case .anthropic:
            return await AnthropicProvider(apiKey: apiKey).validateAPIKey(apiKey)
        case .custom:
            return await CustomProvider(apiKey: apiKey).checkAvailability()
        }
    }
    
    func listOllamaModels() async -> [String] {
        return await OllamaProvider().listAvailableModels()
    }
}
