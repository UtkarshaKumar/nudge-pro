import Foundation

enum LLMProvider: String, CaseIterable, Codable {
    case openai = "OpenAI"
    case ollama = "Ollama (Local)"
    case anthropic = "Anthropic Claude"
    case custom = "Custom (API Compatible)"
    
    var supportsAudio: Bool {
        switch self {
        case .openai: return true
        case .ollama, .anthropic, .custom: return false
        }
    }
    
    var requiresAPIKey: Bool {
        switch self {
        case .ollama: return false
        case .openai, .anthropic, .custom: return true
        }
    }
    
    var defaultModel: String {
        switch self {
        case .openai: return "gpt-4o-mini"
        case .ollama: return "llama3.2:3b"
        case .anthropic: return "claude-3-haiku-20240307"
        case .custom: return "llama3.2"
        }
    }
    
    var description: String {
        switch self {
        case .openai:
            return "Uses OpenAI Whisper for transcription + GPT for notes. Requires API key."
        case .ollama:
            return "Runs locally on your Mac. No internet required. Free."
        case .anthropic:
            return "Uses Claude for generating notes. Does not process audio directly."
        case .custom:
            return "Connect to any OpenAI API-compatible endpoint (LM Studio, Ollama, etc.)"
        }
    }
}

protocol LLMProviderProtocol {
    var provider: LLMProvider { get }
    func checkAvailability() async -> Bool
    func extractActions(from transcript: String) async throws -> [ActionItem]
    func generateMeetingNotes(from transcript: String, actions: [ActionItem]) async throws -> String
    func validateAPIKey(_ apiKey: String) async -> Bool
}
