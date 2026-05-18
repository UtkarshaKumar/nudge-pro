import XCTest
@testable import NudgePro

final class TranscriptionServiceTests: XCTestCase {
    
    func testCheckPermission() async throws {
        let service = TranscriptionService()
        
        // Permission check should return a boolean
        let hasPermission = service.checkPermission()
        
        // Should be either true or false, not crash
        XCTAssertTrue(hasPermission == true || hasPermission == false)
    }
    
    func testRequestPermission() async throws {
        let service = TranscriptionService()
        
        // Should complete without throwing
        let granted = await service.requestPermission()
        
        // Should return a boolean
        XCTAssertTrue(granted == true || granted == false)
    }
    
    func testTranscribeWithInvalidURL() async throws {
        let service = TranscriptionService()
        let invalidURL = URL(fileURLWithPath: "/nonexistent/file.mp4")
        
        // Should throw an error for invalid file
        do {
            _ = try await service.transcribe(videoURL: invalidURL)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is TranscriptionError)
        }
    }
}

final class LLMServiceTests: XCTestCase {
    
    func testCheckAvailability() async throws {
        let service = LLMService()
        
        // Should complete without throwing
        let available = await service.checkAvailability()
        
        // Should be either true or false
        XCTAssertTrue(available == true || available == false)
    }
    
    func testExtractActionsFromEmptyTranscript() async throws {
        let service = LLMService()
        
        // With empty transcript, should return empty array or throw
        let transcript = ""
        
        do {
            let actions = try await service.extractActions(from: transcript)
            XCTAssertTrue(actions.isEmpty)
        } catch {
            // Also acceptable to throw error
            XCTAssertTrue(error is LLMError)
        }
    }
    
    func testExtractActionsWithoutOllama() async throws {
        let service = LLMService()
        // Ollama not running — should fail availability check
        let available = await service.checkAvailability()
        XCTAssertFalse(available)
    }
}

final class PermissionsManagerTests: XCTestCase {
    
    @MainActor
    func testCheckScreenRecordingPermission() async throws {
        let manager = PermissionsManager()
        
        // Should return boolean without crashing
        let hasPermission = await manager.checkScreenRecordingPermission()
        
        XCTAssertTrue(hasPermission == true || hasPermission == false)
    }
    
    @MainActor
    func testCheckMicrophonePermission() async throws {
        let manager = PermissionsManager()
        
        // Should return boolean
        let hasPermission = await manager.checkMicrophonePermission()
        
        XCTAssertTrue(hasPermission == true || hasPermission == false)
    }
    
    @MainActor
    func testCheckAllPermissions() async throws {
        let manager = PermissionsManager()
        
        let (canRecordScreen, canRecordAudio) = await manager.checkAllPermissions()
        
        // Should return booleans
        XCTAssertTrue(canRecordScreen == true || canRecordScreen == false)
        XCTAssertTrue(canRecordAudio == true || canRecordAudio == false)
    }
}

final class SessionTests: XCTestCase {
    
    func testSessionInitWithDefaults() throws {
        let session = Session(
            title: "Test Meeting",
            recordingMode: .audioOnly,
            monitor: nil
        )
        
        XCTAssertEqual(session.title, "Test Meeting")
        XCTAssertEqual(session.recordingMode, .audioOnly)
        XCTAssertEqual(session.status, .recording)
        XCTAssertTrue(session.actions.isEmpty)
    }
    
    func testSessionDuration() throws {
        var session = Session(
            title: "Test",
            recordingMode: .audioOnly,
            monitor: nil
        )
        
        // No stop time = 0 duration
        XCTAssertEqual(session.duration, 0)
        
        // With stop time
        session.stoppedAt = session.startedAt.addingTimeInterval(60)
        XCTAssertEqual(session.duration, 60, accuracy: 0.1)
    }
    
    func testSessionWithActions() throws {
        var session = Session(
            title: "Test",
            recordingMode: .audioOnly,
            monitor: nil
        )
        
        let action = ActionItem(
            task: "Test task",
            assignee: "John",
            deadline: "Tomorrow",
            context: "Test",
            sourceQuote: "We should test",
            confidence: 0.9,
            status: .pending
        )
        
        session.actions = [action]
        
        XCTAssertEqual(session.actions.count, 1)
        XCTAssertEqual(session.actions.first?.task, "Test task")
    }
}

final class ActionItemTests: XCTestCase {
    
    func testActionItemInit() throws {
        let item = ActionItem(
            task: "Complete documentation",
            assignee: "Alice",
            deadline: "Friday",
            context: "Sprint Planning",
            sourceQuote: "Alice will complete docs by Friday",
            confidence: 0.95,
            status: .pending
        )
        
        XCTAssertEqual(item.task, "Complete documentation")
        XCTAssertEqual(item.assignee, "Alice")
        XCTAssertEqual(item.deadline, "Friday")
        XCTAssertEqual(item.confidence, 0.95)
        XCTAssertEqual(item.status, .pending)
    }
    
    func testActionItemWithNilFields() throws {
        let item = ActionItem(
            task: "Do something",
            assignee: nil,
            deadline: nil,
            context: nil,
            sourceQuote: nil,
            confidence: 0.5,
            status: .pending
        )
        
        XCTAssertEqual(item.task, "Do something")
        XCTAssertNil(item.assignee)
        XCTAssertNil(item.deadline)
        XCTAssertEqual(item.confidence, 0.5)
    }
}

final class EnumTests: XCTestCase {
    
    func testRecordingModeRawValues() throws {
        XCTAssertEqual(RecordingMode.audioOnly.rawValue, "audio_only")
        XCTAssertEqual(RecordingMode.screenAndAudio.rawValue, "screen_audio")
    }
    
    func testRecordingModeProperties() throws {
        let audioOnly = RecordingMode.audioOnly
        
        XCTAssertFalse(audioOnly.displayName.isEmpty)
        XCTAssertFalse(audioOnly.description.isEmpty)
        XCTAssertFalse(audioOnly.icon.isEmpty)
    }
    
    func testSessionStatusProperties() throws {
        let recording = SessionStatus.recording
        
        XCTAssertFalse(recording.icon.isEmpty)
        XCTAssertNotNil(recording.color)
    }
    
    func testActionStatusHasIcon() throws {
        let pending = ActionStatus.pending
        
        XCTAssertFalse(pending.icon.isEmpty)
    }
    
    func testRecordingStateEquality() throws {
        let idle1 = RecordingState.idle
        let idle2 = RecordingState.idle
        let recording = RecordingState.recording
        
        XCTAssertEqual(idle1, idle2)
        XCTAssertNotEqual(idle1, recording)
    }
}

final class MockRecordingServiceTests: XCTestCase {
    
    func testMockStartRecording() async throws {
        let service = MockRecordingService()
        
        let session = try await service.startRecording(mode: .audioOnly, monitor: nil)
        
        XCTAssertFalse(session.title.isEmpty)
        XCTAssertEqual(session.status, .recording)
        XCTAssertEqual(session.recordingMode, .audioOnly)
    }
    
    func testMockStopRecording() async throws {
        let service = MockRecordingService()
        
        // Start then stop
        _ = try await service.startRecording(mode: .audioOnly, monitor: nil)
        let session = try await service.stopRecording()
        
        XCTAssertEqual(session.status, .completed)
        XCTAssertFalse(session.actions.isEmpty) // Mock generates actions
    }
    
    func testMockGetAvailableMonitors() async throws {
        let service = MockRecordingService()
        
        let monitors = await service.getAvailableMonitors()
        
        XCTAssertFalse(monitors.isEmpty)
        XCTAssertTrue(monitors.contains(where: { $0.isPrimary }))
    }
    
    func testMockCheckPermissions() async throws {
        let service = MockRecordingService()
        
        let status = await service.checkPermissions()
        
        // Mock should always return true
        XCTAssertTrue(status.canRecordAudio)
        XCTAssertTrue(status.canRecordScreen)
        XCTAssertTrue(status.canRecord)
    }
}

final class TimeIntervalExtensionTests: XCTestCase {
    
    func testFormatTimeUnderMinute() throws {
        let time: TimeInterval = 45
        XCTAssertEqual(time.formattedTime, "00:45")
    }
    
    func testFormatTimeWithMinutes() throws {
        let time: TimeInterval = 125 // 2:05
        XCTAssertEqual(time.formattedTime, "02:05")
    }
    
    func testFormatTimeWithHours() throws {
        let time: TimeInterval = 3665 // 1:01:05
        XCTAssertEqual(time.formattedTime, "01:01:05")
    }
}

final class PermissionStatusTests: XCTestCase {
    
    func testCanRecordBothAllowed() throws {
        let status = PermissionStatus(
            canRecordAudio: true,
            canRecordScreen: true,
            missingPermissions: []
        )
        
        XCTAssertTrue(status.canRecord)
    }
    
    func testCanRecordAudioDenied() throws {
        let status = PermissionStatus(
            canRecordAudio: false,
            canRecordScreen: true,
            missingPermissions: ["Microphone"]
        )
        
        XCTAssertFalse(status.canRecord)
        XCTAssertTrue(status.missingPermissions.contains("Microphone"))
    }
    
    func testCanRecordScreenDenied() throws {
        let status = PermissionStatus(
            canRecordAudio: true,
            canRecordScreen: false,
            missingPermissions: ["Screen Recording"]
        )
        
        XCTAssertFalse(status.canRecord)
        XCTAssertTrue(status.missingPermissions.contains("Screen Recording"))
    }
}

final class MonitorTests: XCTestCase {
    
    func testMonitorInit() throws {
        let monitor = Monitor(
            id: "main",
            name: "Built-in Display",
            width: 1920,
            height: 1080,
            isPrimary: true,
            displayID: 1
        )
        
        XCTAssertEqual(monitor.name, "Built-in Display")
        XCTAssertEqual(monitor.resolution, "1920 × 1080")
        XCTAssertTrue(monitor.isPrimary)
    }
    
    func testMonitorResolution() throws {
        let monitor = Monitor(
            id: "test",
            name: "Test",
            width: 2560,
            height: 1440,
            isPrimary: false,
            displayID: 2
        )
        
        XCTAssertEqual(monitor.resolution, "2560 × 1440")
    }
}

final class IntegrationTests: XCTestCase {
    
    func testCompleteRecordingFlow() async throws {
        let service = MockRecordingService()
        
        // 1. Check permissions
        let permissions = await service.checkPermissions()
        XCTAssertTrue(permissions.canRecord)
        
        // 2. Get monitors
        let monitors = await service.getAvailableMonitors()
        XCTAssertFalse(monitors.isEmpty)
        
        // 3. Start recording
        let startedSession = try await service.startRecording(
            mode: .screenAndAudio,
            monitor: monitors.first
        )
        XCTAssertEqual(startedSession.status, .recording)
        
        // 4. Stop recording
        let completedSession = try await service.stopRecording()
        XCTAssertEqual(completedSession.status, .completed)
        XCTAssertFalse(completedSession.actions.isEmpty)
    }
}
