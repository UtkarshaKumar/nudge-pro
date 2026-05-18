import Foundation
import SwiftUI

/// ViewModel for recording screen with integrated processing
@MainActor
final class RecordingViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var recordingState: RecordingState = .idle
    @Published private(set) var currentSession: Session?
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var processingProgress: Double = 0
    @Published private(set) var errorMessage: String?
    @Published var availableDisplays: [Monitor] = []
    @Published var selectedDisplay: Monitor?
    @Published var showDisplayPicker: Bool = false

    // MARK: - Dependencies

    private let recordingService: RecordingServiceProtocol
    private let permissionsManager = PermissionsManager()
    private var timer: Timer?

    // MARK: - Initialization

    init(
        recordingService: RecordingServiceProtocol? = nil
    ) {
        if #available(macOS 13.0, *), recordingService == nil {
            self.recordingService = NativeScreenCaptureService()
        } else if let service = recordingService {
            self.recordingService = service
        } else {
            fatalError("RecordingService required for macOS < 13.0")
        }

        Task {
            await loadDisplays()
        }
    }

    // MARK: - Public Methods

    /// Load available displays
    func loadDisplays() async {
        let displays = await recordingService.getAvailableMonitors()
        availableDisplays = displays

        // Select primary display by default
        if let primary = displays.first(where: { $0.isPrimary }) {
            selectedDisplay = primary
        } else if let first = displays.first {
            selectedDisplay = first
        }

        print("Loaded \(displays.count) displays")
    }

    /// Check if all permissions are granted
    func checkPermissions() async -> Bool {
        let permissions = await recordingService.checkPermissions()

        if !permissions.canRecord {
            let missingList = permissions.missingPermissions.joined(separator: ", ")
            errorMessage = Strings.Recording.permissionsRequired + "\n\n" + missingList
            return false
        }

        return true
    }

    /// Request all required permissions
    func requestPermissions() async -> Bool {
        let result = await permissionsManager.requestAllPermissions()
        let granted = result.screenRecording && result.microphone

        if !granted {
            let permissions = await permissionsManager.checkAllPermissions()
            var missing: [String] = []

            if !permissions.screenRecording {
                missing.append(Strings.Onboarding.screenRecording)
            }
            if !permissions.microphone {
                missing.append(Strings.Onboarding.microphone)
            }

            errorMessage = Strings.Recording.permissionsRequired + "\n\n" + missing.joined(separator: "\n")
        }

        return granted
    }

    /// Start recording
    func startRecording(mode: RecordingMode = .screenAndAudio, monitor: Monitor? = nil) {
        // Check permissions first synchronously
        let permissions = permissionsManager.checkPermissionsSync()
        print("📋 Permission check result - canRecord: \(permissions.canRecord)")
        
        guard permissions.canRecord else {
            let missingList = permissions.missingPermissions.joined(separator: "\n")
            let fullMessage = Strings.Recording.permissionsRequired + "\n\n" + missingList
            errorMessage = fullMessage
            recordingState = .error(fullMessage)
            return
        }
        
        // Start recording on background
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                // Clear any previous error
                self.errorMessage = nil

                // Start recording
                let session = try await self.recordingService.startRecording(
                    mode: mode,
                    monitor: monitor ?? self.selectedDisplay
                )

                self.currentSession = session
                self.recordingState = .recording
                self.startTimer()

                print("Recording started: \(session.title)")

            } catch let error as RecordingError {
                print("Recording error: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.recordingState = .error(error.localizedDescription)
            } catch {
                print("Unexpected error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                recordingState = .error(error.localizedDescription)
            }
        }
    }

    /// Stop recording - processes in background, returns to idle immediately
    func stopRecording() {
        Task {
            do {
                stopTimer()
                
                // Stop recording and save session immediately
                let session = try await recordingService.stopRecording()
                print("Recording stopped: \(session.title)")
                
                // Immediately reset to idle so user can start new recording
                recordingState = .idle
                currentSession = nil
                elapsedTime = 0
                
            } catch let error as RecordingError {
                print("Stop error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                recordingState = .error(error.localizedDescription)
            } catch {
                print("Processing error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                recordingState = .error(error.localizedDescription)
            }
        }
    }

    /// Reset to idle state
    func reset() {
        recordingState = .idle
        currentSession = nil
        elapsedTime = 0
        processingProgress = 0
        errorMessage = nil
        stopTimer()
    }

    /// Open display picker
    func showDisplaySelection() {
        showDisplayPicker = true
    }

    // MARK: - Private Methods

    private func startTimer() {
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedTime += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Recording State

enum RecordingState: Equatable {
    case idle
    case recording
    case processing
    case completed
    case error(String)

    var displayName: String {
        switch self {
        case .idle:
            return Strings.Recording.idle
        case .recording:
            return Strings.Recording.recording
        case .processing:
            return Strings.Recording.processing
        case .completed:
            return Strings.Recording.completed
        case .error:
            return Strings.Common.error
        }
    }

    var isRecording: Bool {
        if case .recording = self {
            return true
        }
        return false
    }

    var canStartRecording: Bool {
        switch self {
        case .idle, .completed, .error:
            return true
        case .recording, .processing:
            return false
        }
    }
}
