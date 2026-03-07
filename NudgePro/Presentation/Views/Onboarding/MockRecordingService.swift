import Foundation
import Combine

final class MockRecordingService: RecordingServiceProtocol {
    @Published private(set) var recordingState: RecordingState = .idle
    
    private var currentSession: Session?
    private var recordingStartTime: Date?
    
    func startRecording(mode: RecordingMode, monitor: Monitor?) async throws -> Session {
        print("🎙️ Mock: Starting recording with mode: \(mode.displayName)")
        
        let session = Session(
            title: "Meeting \(Date().formatted(.dateTime.month().day().hour().minute()))",
            recordingMode: mode,
            monitor: monitor
        )
        
        self.currentSession = session
        self.recordingStartTime = Date()
        self.recordingState = .recording
        
        print("✅ Mock: Recording started - Session ID: \(session.id)")
        return session
    }
    
    func stopRecording() async throws -> Session {
        guard var session = currentSession else {
            throw RecordingError.stopFailed("No active recording session")
        }
        
        print("⏹️ Mock: Stopping recording")
        
        session.stoppedAt = Date()
        session.status = .processing
        
        self.recordingState = .processing
        
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Add mock action items
        session.actions = [
            ActionItem(
                task: "Follow up on Q4 budget discussion",
                assignee: "John",
                deadline: "Next Monday",
                context: "Budget Planning",
                sourceQuote: "We need to finalize the Q4 budget by Monday",
                confidence: 0.85,
                status: .pending
            ),
            ActionItem(
                task: "Send updated design mockups",
                assignee: "Sarah",
                deadline: "This Friday",
                context: "Design Review",
                sourceQuote: "Sarah will share the new mockups by end of week",
                confidence: 0.92,
                status: .pending
            )
        ]
        
        session.status = .completed
        self.recordingState = .completed
        self.currentSession = session
        
        print("✅ Mock: Recording completed with \(session.actions.count) action items")
        return session
    }
    
    func getAvailableMonitors() async -> [Monitor] {
        let monitors = [
            Monitor(
                id: "main",
                name: "Built-in Display",
                width: 1920,
                height: 1080,
                isPrimary: true,
                displayID: 1
            ),
            Monitor(
                id: "external",
                name: "External Display",
                width: 2560,
                height: 1440,
                isPrimary: false,
                displayID: 2
            )
        ]
        
        print("🖥️ Mock: Returning \(monitors.count) available monitors")
        return monitors
    }
    
    func checkPermissions() async -> PermissionStatus {
        let status = PermissionStatus(
            canRecordAudio: true,
            canRecordScreen: true,
            missingPermissions: []
        )
        
        print("🔐 Mock: Permissions check - Audio: \(status.canRecordAudio), Screen: \(status.canRecordScreen)")
        return status
    }
}
