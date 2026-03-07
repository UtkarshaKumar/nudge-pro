import Foundation

// MARK: - Session Entity

struct Session: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var startedAt: Date
    var stoppedAt: Date?
    var status: SessionStatus
    var recordingMode: RecordingMode
    var monitorName: String?
    var monitor: Monitor?
    var audioPath: URL?
    var videoPath: URL?
    var transcriptPath: URL?
    var transcript: String?
    var notesPath: URL?
    var notes: String?
    var participants: [String]
    var templateID: String?
    var actionItems: [ActionItem]
    var storagePath: String

    /// Convenience alias — many views use `session.actions` instead of `session.actionItems`
    var actions: [ActionItem] {
        get { actionItems }
        set { actionItems = newValue }
    }

    var duration: TimeInterval {
        guard let stoppedAt = stoppedAt else {
            return Date().timeIntervalSince(startedAt)
        }
        return stoppedAt.timeIntervalSince(startedAt)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startedAt)
    }

    init(
        id: UUID = UUID(),
        title: String,
        startedAt: Date = Date(),
        recordingMode: RecordingMode,
        monitorName: String? = nil,
        monitor: Monitor? = nil,
        storagePath: String = "~/Documents/Meeting Notes"
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.stoppedAt = nil
        self.status = .recording
        self.recordingMode = recordingMode
        self.monitorName = monitorName ?? monitor?.name
        self.monitor = monitor
        self.participants = []
        self.actionItems = []
        self.storagePath = storagePath
    }
}

// MARK: - ActionItem Entity

struct ActionItem: Identifiable, Codable, Hashable {
    var id: UUID
    var task: String
    var assignee: String?
    var deadline: String?
    var context: String?
    var sourceQuote: String?
    var confidence: Double
    var status: ActionStatus
    var createdAt: Date
    var updatedAt: Date

    var checkboxSymbol: String {
        status == .completed ? "[x]" : "[ ]"
    }

    init(
        id: UUID = UUID(),
        task: String,
        assignee: String? = nil,
        deadline: String? = nil,
        context: String? = nil,
        sourceQuote: String? = nil,
        confidence: Double = 0.0,
        status: ActionStatus = .pending
    ) {
        self.id = id
        self.task = task
        self.assignee = assignee
        self.deadline = deadline
        self.context = context
        self.sourceQuote = sourceQuote
        self.confidence = confidence
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Monitor

struct Monitor: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let width: Int
    let height: Int
    let isPrimary: Bool
    var displayID: UInt32?

    var resolution: String {
        "\(width) \u{00D7} \(height)"
    }

    var displayName: String {
        isPrimary ? "\(name) (Primary)" : name
    }

    init(
        id: String,
        name: String,
        width: Int,
        height: Int,
        isPrimary: Bool,
        displayID: UInt32? = nil
    ) {
        self.id = id
        self.name = name
        self.width = width
        self.height = height
        self.isPrimary = isPrimary
        self.displayID = displayID
    }
}
