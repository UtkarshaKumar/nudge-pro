import Foundation

/// Centralized string constants for the app
enum Strings {
    enum History {
        static let empty = "No Recordings"
        static let emptyMessage = "Start recording your first meeting"
    }

    enum Recording {
        static let start = "Start Recording"
        static let stop = "Stop Recording"
        static let idle = "Ready"
        static let recording = "Recording"
        static let processing = "Processing"
        static let completed = "Completed"
        static let permissionsRequired = "Permissions required to record"
    }

    enum Settings {
        static let title = "Settings"
        static let recordingSection = "Recording"
        static let outputSection = "Output"
        static let aiSection = "AI Processing"
        static let storageSection = "Storage"
        static let aboutSection = "About"
        static let monitorSelection = "Monitor Selection"
        static let outputTemplate = "Output Template"
        static let ollamaStatus = "Ollama Status"
        static let ollamaConnected = "Connected"
        static let ollamaDisconnected = "Not Running"
        static let deleteRecordingsAfter = "Delete recordings after"
        static let cleanupNote = "Automatically remove old recordings"
        static let twoDays = "2 Days"
        static let sevenDays = "7 Days"
        static let thirtyDays = "30 Days"
        static let never = "Never"
        static let version = "Version"
    }

    enum Search {
        static let placeholder = "Search recordings..."
        static let noResults = "No results found"
    }

    enum Onboarding {
        static let screenRecording = "Screen Recording"
        static let microphone = "Microphone"
    }

    enum Common {
        static let error = "Error"
    }
}
