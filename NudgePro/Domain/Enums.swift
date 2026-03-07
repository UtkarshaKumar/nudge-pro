import Foundation
import SwiftUI

/// Available vision AI providers
enum VisionProvider: String, CaseIterable, Codable {
    case local = "local"
    case openAI = "openai"

    var displayName: String {
        switch self {
        case .local:
            return "Local (Ollama)"
        case .openAI:
            return "OpenAI GPT-4V"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .local: return false
        case .openAI: return true
        }
    }
}

/// Recording mode options
enum RecordingMode: String, CaseIterable, Codable {
    case audioOnly = "audio_only"
    case screenAndAudio = "screen_audio"

    var displayName: String {
        switch self {
        case .audioOnly:
            return "Audio Only"
        case .screenAndAudio:
            return "Screen + Audio"
        }
    }

    var description: String {
        switch self {
        case .audioOnly:
            return "Capture meeting audio only"
        case .screenAndAudio:
            return "Record screen with audio"
        }
    }

    var icon: String {
        switch self {
        case .audioOnly:
            return "mic.fill"
        case .screenAndAudio:
            return "rectangle.on.rectangle"
        }
    }
}

/// Session recording status
enum SessionStatus: String, Codable {
    case idle
    case recording
    case processing
    case completed
    case failed
    case cancelled

    var icon: String {
        switch self {
        case .idle: return "circle"
        case .recording: return "record.circle.fill"
        case .processing: return "gear"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .idle: return .textTertiary
        case .recording: return .recording
        case .processing: return .warning
        case .completed: return .success
        case .failed: return .error
        case .cancelled: return .textSecondary
        }
    }
}

/// Action item status
enum ActionStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case cancelled
    case deferred
    case skipped

    var icon: String {
        switch self {
        case .pending: return "circle"
        case .inProgress: return "arrow.clockwise.circle"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .deferred: return "clock"
        case .skipped: return "forward.fill"
        }
    }
}
