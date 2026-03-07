import Foundation

enum RecordingError: LocalizedError {
    case startFailed(String)
    case stopFailed(String)
    case permissionDenied([String])

    var errorDescription: String? {
        switch self {
        case .startFailed(let reason): return "Failed to start recording: \(reason)"
        case .stopFailed(let reason): return "Failed to stop recording: \(reason)"
        case .permissionDenied(let missing): return "Permission denied: \(missing.joined(separator: ", "))"
        }
    }
}

enum TranscriptionError: LocalizedError {
    case permissionDenied
    case fileNotFound(String)
    case transcriptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Speech recognition permission denied"
        case .fileNotFound(let path): return "File not found: \(path)"
        case .transcriptionFailed(let reason): return "Transcription failed: \(reason)"
        }
    }
}

enum LLMError: LocalizedError {
    case ollamaNotRunning
    case extractionFailed(String)
    case invalidResponse
    case invalidAPIKey
    case apiError(String)
    case noProvider
    case networkError(String)
    case providerNotAvailable

    var errorDescription: String? {
        switch self {
        case .ollamaNotRunning: return "Ollama is not running"
        case .extractionFailed(let reason): return "Action extraction failed: \(reason)"
        case .invalidResponse: return "Invalid LLM response"
        case .invalidAPIKey: return "Invalid API key. Please check your settings."
        case .apiError(let msg): return "API Error: \(msg)"
        case .noProvider: return "No LLM provider configured. Please select a provider in Settings."
        case .networkError(let msg): return "Network error: \(msg)"
        case .providerNotAvailable: return "This provider is not available. Please check your settings."
        }
    }
}
