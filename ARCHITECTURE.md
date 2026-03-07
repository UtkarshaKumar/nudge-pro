# Nudge Pro - Architecture Document

## Table of Contents
1. [Overview](#overview)
2. [Architecture Principles](#architecture-principles)
3. [Layer Structure](#layer-structure)
4. [Domain Layer](#domain-layer)
5. [Application Layer](#application-layer)
6. [Infrastructure Layer](#infrastructure-layer)
7. [Presentation Layer](#presentation-layer)
8. [Python Core Architecture](#python-core-architecture)
9. [Distribution Architecture](#distribution-architecture)
10. [Security & Privacy](#security--privacy)

---

## Overview

Nudge Pro follows **Clean Architecture** principles with strict layer separation. The application consists of two main parts:

1. **SwiftUI Frontend**: Native macOS UI layer
2. **Python Core**: Backend processing logic

Communication between layers happens through **protocols** (interfaces), enabling:
- Dependency injection
- Testability
- Flexibility for future changes

---

## Architecture Principles

### SOLID Principles Applied

| Principle | Application |
|-----------|-------------|
| **S**ingle Responsibility | Each module has one clear purpose |
| **O**pen/Closed | Open for extension, closed for modification |
| **L**iskov Substitution | Protocols enable substitution |
| **I**nterface Segregation | Small, focused protocols |
| **D**ependency Inversion | Depend on abstractions, not concretions |

### Layer Dependencies

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│    (Views, ViewModels, Components)      │
├─────────────────────────────────────────┤
│           Application Layer             │
│        (Use Cases, DTOs, Mappers)       │
├─────────────────────────────────────────┤
│             Domain Layer                │
│     (Entities, Protocols, Enums)        │
├─────────────────────────────────────────┤
│          Infrastructure Layer            │
│  (Services, Repositories, External I/O) │
├─────────────────────────────────────────┤
│             Python Core                  │
│   (Audio, Screen, Vision, Extraction)   │
└─────────────────────────────────────────┘
```

**Rule**: Dependencies only point inward. Inner layers know nothing about outer layers.

---

## Domain Layer

Contains business logic that is independent of any framework or UI.

### Entities

```swift
// Domain/Entities/Session.swift
/// Represents a recording session
struct Session: Identifiable, Codable {
    let id: UUID
    var title: String
    var startedAt: Date
    var stoppedAt: Date?
    var status: SessionStatus
    var recordingMode: RecordingMode
    var monitor: Monitor?
    var audioPath: URL?
    var videoPath: URL?
    var transcriptPath: URL?
    var notesPath: URL?
    var actions: [ActionItem]
    var duration: TimeInterval { ... }
}

// Domain/Entities/ActionItem.swift
/// Represents an extracted action item
struct ActionItem: Identifiable, Codable {
    let id: UUID
    var task: String
    var assignee: String?
    var deadline: String?
    var context: String?
    var sourceQuote: String?
    var confidence: Double
    var status: ActionStatus
}

// Domain/Entities/Monitor.swift
/// Represents a display/monitor
struct Monitor: Identifiable, Codable {
    let id: String
    let name: String
    let width: Int
    let height: Int
    let isPrimary: Bool
    let displayID: CGDirectDisplayID
}
```

### Enums

```swift
// Domain/Enums/RecordingMode.swift
enum RecordingMode: String, Codable, CaseIterable {
    case audioOnly = "audio_only"
    case screenAndAudio = "screen_audio"
    
    var displayName: String { ... }
    var description: String { ... }
}

// Domain/Enums/VisionProvider.swift
enum VisionProvider: String, Codable, CaseIterable {
    case local = "local"
    case openAI = "openai"
    
    var displayName: String { ... }
    var requiresAPIKey: Bool { ... }
}

// Domain/Enums/SessionStatus.swift
enum SessionStatus: String, Codable {
    case idle
    case recording
    case processing
    case completed
    case failed
}
```

### Protocols

```swift
// Domain/Protocols/RecordingServiceProtocol.swift
/// Defines the contract for recording operations
protocol RecordingServiceProtocol {
    /// Current state of recording
    var recordingState: RecordingState { get }
    
    /// Start a new recording session
    func startRecording(mode: RecordingMode, monitor: Monitor?) async throws
    
    /// Stop the current recording
    func stopRecording() async throws -> Session
    
    /// Get available monitors for screen recording
    func getAvailableMonitors() async -> [Monitor]
    
    /// Check if required permissions are granted
    func checkPermissions() async -> PermissionStatus
}

// Domain/Protocols/LLMServiceProtocol.swift
/// Defines the contract for LLM operations
protocol LLMServiceProtocol {
    /// Extract action items from transcript
    func extractActions(from transcript: String) async throws -> [ActionItem]
    
    /// Analyze meeting and generate summary
    func analyzeMeeting(transcript: String) async throws -> MeetingAnalysis
    
    /// Generate weekly digest
    func generateDigest(from sessions: [Session]) async throws -> Digest
}

// Domain/Protocols/StorageServiceProtocol.swift
/// Defines the contract for storage operations
protocol StorageServiceProtocol {
    /// Save a session
    func saveSession(_ session: Session) async throws
    
    /// Load a session by ID
    func loadSession(id: UUID) async throws -> Session?
    
    /// List all sessions
    func listSessions(limit: Int, offset: Int) async throws -> [Session]
    
    /// Delete a session
    func deleteSession(id: UUID) async throws
}
```

---

## Application Layer

Contains application-specific business rules. Orchestrates domain entities through use cases.

### Use Cases

```swift
// Application/Recording/StartRecordingUseCase.swift
/// Use case for starting a new recording
final class StartRecordingUseCase {
    private let recordingService: RecordingServiceProtocol
    private let configService: ConfigServiceProtocol
    
    /// Execute the use case
    /// - Parameters:
    ///   - mode: Recording mode (audio-only or screen+audio)
    ///   - monitor: Optional specific monitor to record
    /// - Returns: The started session
    /// - Throws: RecordingError if unable to start
    func execute(mode: RecordingMode, monitor: Monitor? = nil) async throws -> Session {
        // 1. Validate permissions
        let permissions = await recordingService.checkPermissions()
        guard permissions.canRecord else {
            throw RecordingError.permissionDenied(permissions.missingPermissions)
        }
        
        // 2. Get monitor if needed
        let selectedMonitor = monitor ?? await getDefaultMonitor(mode: mode)
        
        // 3. Start recording
        try await recordingService.startRecording(mode: mode, monitor: selectedMonitor)
        
        // 4. Return created session
        return try await recordingService.getCurrentSession()
    }
    
    private func getDefaultMonitor(mode: RecordingMode) async -> Monitor? {
        // Get default from config or primary monitor
    }
}
```

### DTOs (Data Transfer Objects)

```swift
// Application/Recording/DTOs.swift
struct RecordingStartRequest {
    let mode: RecordingMode
    let monitorID: String?
    let title: String?
}

struct RecordingStartResponse {
    let session: Session
    let audioDevice: String
    let monitor: Monitor?
}

struct ProcessingProgress {
    let currentStep: ProcessingStep
    let progress: Double
    let message: String
    
    enum ProcessingStep: String {
        case transcribing
        case extractingActions
        case analyzingMeeting
        case generatingNotes
        case complete
    }
}
```

---

## Infrastructure Layer

Implements interfaces defined in the Domain layer. Contains concrete implementations.

### Services

```swift
// Infrastructure/Services/PythonBridgeService.swift
/// Bridge between Swift and Python core
final class PythonBridgeService: RecordingServiceProtocol {
    private let processManager: ProcessManager
    private let configService: ConfigServiceProtocol
    
    func startRecording(mode: RecordingMode, monitor: Monitor?) async throws {
        let arguments = [
            "start",
            "--mode", mode.rawValue,
            "--monitor-id", monitor?.id ?? ""
        ]
        
        let result = try await processManager.execute(
            command: "python",
            arguments: ["nudge.py"] + arguments,
            workingDirectory: configService.pythonCorePath
        )
        
        guard result.exitCode == 0 else {
            throw RecordingError.startFailed(result.errorMessage)
        }
    }
    
    func stopRecording() async throws -> Session {
        // Execute stop command and parse JSON response
    }
    
    func getAvailableMonitors() async -> [Monitor] {
        // Query Python for monitors
    }
}

// Infrastructure/Services/ConfigService.swift
/// Manages application configuration
final class ConfigService: ConfigServiceProtocol {
    private let userDefaults: UserDefaults
    private let keychainService: KeychainServiceProtocol
    
    func get<T: Codable>(_ key: ConfigKey) -> T? {
        // Load from UserDefaults or Keychain
    }
    
    func set<T: Codable>(_ key: ConfigKey, value: T) {
        // Save to UserDefaults or Keychain
    }
}
```

### Repositories

```swift
// Infrastructure/Repositories/SessionRepository.swift
/// Repository for session data persistence
final class SessionRepository: StorageServiceProtocol {
    private let database: SQLiteDatabase
    private let fileManager: FileManager
    
    func saveSession(_ session: Session) async throws {
        // Save to SQLite and file system
    }
    
    func loadSession(id: UUID) async throws -> Session? {
        // Load from database
    }
}
```

---

## Presentation Layer

SwiftUI views and ViewModels. Follows MVVM pattern.

### ViewModels

```swift
// Presentation/ViewModels/RecordingViewModel.swift
/// ViewModel for the recording screen
@MainActor
final class RecordingViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var recordingState: RecordingState = .idle
    @Published private(set) var currentSession: Session?
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var processingProgress: ProcessingProgress?
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let startRecordingUseCase: StartRecordingUseCase
    private let stopRecordingUseCase: StopRecordingUseCase
    
    // MARK: - Public Methods
    func startRecording(mode: RecordingMode, monitor: Monitor? = nil) {
        Task {
            do {
                let session = try await startRecordingUseCase.execute(
                    mode: mode,
                    monitor: monitor
                )
                self.currentSession = session
                self.recordingState = .recording
                self.startTimer()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func stopRecording() {
        Task {
            do {
                self.recordingState = .processing
                let session = try await stopRecordingUseCase.execute()
                self.currentSession = session
                self.recordingState = .completed
                self.stopTimer()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
```

### SwiftUI Views

```swift
// Presentation/Views/Recording/RecordingView.swift
/// Main recording screen
struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            // Recording indicator
            RecordingIndicatorView(
                state: viewModel.recordingState,
                isAnimating: viewModel.recordingState == .recording
            )
            
            // Session title
            if let session = viewModel.currentSession {
                Text(session.title)
                    .font(.title2)
                    .foregroundColor(.textPrimary)
            }
            
            // Timer
            Text(viewModel.elapsedTime.formatted)
                .font(.system(.title, design: .monospaced))
                .foregroundColor(.textSecondary)
            
            // Controls
            RecordingControlsView(
                state: viewModel.recordingState,
                onStart: { viewModel.startRecording(mode: .audioOnly) },
                onStop: { viewModel.stopRecording() }
            )
            
            // Status bar
            RecordingStatusBar(session: viewModel.currentSession)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }
}
```

### Components

```swift
// Presentation/Views/Components/LinearButton.swift
/// Linear-style button with gradient
struct LinearButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary   // Gradient background
        case secondary // Border only
        case ghost     // Text only
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.button)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(background)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var background: some View {
        Group {
            if style == .primary {
                LinearGradient(
                    colors: [.accentPrimary, .accentSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if style == .secondary {
                Color.surface
            } else {
                Color.clear
            }
        }
    }
}
```

---

## Python Core Architecture

The Python backend follows modular architecture with clear separation of concerns.

### Module Structure

```
Core/src/
├── __init__.py           # Package initialization
├── config.py             # Configuration management
│
├── audio/                # Audio capture module
│   ├── __init__.py
│   ├── capture.py        # AudioCapture class
│   └── devices.py        # Device enumeration
│
├── screen/               # Screen recording module
│   ├── __init__.py
│   ├── capture.py        # ScreenCapture class
│   ├── selector.py       # Monitor selection
│   └── encoder.py        # Video encoding
│
├── transcription/        # Speech-to-text module
│   ├── __init__.py
│   ├── engine.py         # Whisper integration
│   └── vad.py            # Voice activity detection
│
├── vision/               # Vision AI module
│   ├── __init__.py
│   ├── frame_extractor.py
│   ├── slide_detector.py
│   └── providers/
│       ├── __init__.py
│       ├── base.py       # Abstract base class
│       ├── ollama.py     # Ollama vision
│       └── openai.py     # OpenAI GPT-4V
│
├── extraction/           # LLM processing module
│   ├── __init__.py
│   ├── action_extractor.py
│   ├── meeting_analyzer.py
│   └── prompts.py
│
├── storage/              # Data persistence module
│   ├── __init__.py
│   ├── database.py
│   └── models.py
│
└── integrations/         # External integrations
    ├── __init__.py
    ├── reminders.py
    └── word_notes.py
```

### Class Design Example

```python
# screen/capture.py
"""
Screen capture module using ffmpeg.

Example:
    >>> monitor = Monitor(id="1", name="Built-in Retina Display", ...)
    >>> encoder = H264Encoder(preset="fast", crf=23)
    >>> capture = ScreenCapture(monitor=monitor, encoder=encoder)
    >>> capture.start(output_path=Path("output.mp4"))
    >>> # ... recording ...
    >>> result = capture.stop()
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from .encoder import VideoEncoder, H264Encoder
from .selector import MonitorSelector


@dataclass
class RecordingResult:
    """Result of a screen recording session."""
    output_path: Path
    duration: float
    frame_count: int
    file_size: int


class ScreenCapture(ABC):
    """
    Abstract screen capture handler.
    
    Responsibilities:
    - Manage ffmpeg process for screen recording
    - Handle start/stop operations
    - Report recording status
    
    Uses:
    - VideoEncoder: For encoding video frames
    - Monitor: For display information
    """
    
    def __init__(
        self,
        monitor: "Monitor",
        encoder: Optional[VideoEncoder] = None
    ) -> None:
        self._monitor = monitor
        self._encoder = encoder or H264Encoder()
        self._is_recording = False
        self._process: Optional["subprocess.Popen"] = None
    
    @property
    def is_recording(self) -> bool:
        """Check if currently recording."""
        return self._is_recording
    
    def start(self, output_path: Path) -> None:
        """
        Start recording to the specified path.
        
        Args:
            output_path: Path where the video will be saved.
            
        Raises:
            PermissionError: If screen recording permission is denied.
            RuntimeError: If ffmpeg fails to start.
        """
        if self._is_recording:
            raise RuntimeError("Already recording")
        
        self._validate_permissions()
        self._encoder.validate()
        
        command = self._build_ffmpeg_command(output_path)
        self._process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        self._is_recording = True
    
    def stop(self) -> RecordingResult:
        """
        Stop the current recording.
        
        Returns:
            RecordingResult with metadata about the recorded video.
            
        Raises:
            RuntimeError: If not currently recording.
        """
        if not self._is_recording:
            raise RuntimeError("Not currently recording")
        
        self._process.terminate()
        self._process.wait()
        self._is_recording = False
        
        return RecordingResult(
            output_path=self._output_path,
            duration=self._elapsed_time,
            frame_count=self._frame_count,
            file_size=self._output_path.stat().st_size
        )
    
    def _build_ffmpeg_command(self, output_path: Path) -> list[str]:
        """Build ffmpeg command for screen capture."""
        # Implementation details
        pass
```

---

## Distribution Architecture

### Build Targets

| Target | Purpose | Entitlements |
|--------|---------|--------------|
| `NudgePro-AppStore` | Mac App Store distribution | Sandbox enabled |
| `NudgePro-Direct` | Direct download (website, etc.) | Full access |

### Conditional Compilation

```swift
#if AppStore
    // App Store specific configuration
    let apiEndpoint = "https://api.nudge.pro/v1"
    let enableScreenCaptureKit = true
    let enableAutoLaunch = false
#else
    // Direct download configuration
    let apiEndpoint = "https://api.nudge.pro/v1"
    let enableFFmpegCapture = true
    let enableAutoLaunch = true
#endif
```

### Entitlements

```xml
<!-- NudgePro.entitlements (App Store) -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.device.screen-capture</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

```xml
<!-- NudgePro-Direct.entitlements (Direct Download) -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- No sandbox for direct download -->
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
</dict>
</plist>
```

---

## Security & Privacy

### Keychain Usage

```swift
// Store sensitive data
keychainService.set("openai_api_key", value: apiKey, service: "com.nudge.pro")

// Retrieve securely
if let apiKey = keychainService.get("openai_api_key", service: "com.nudge.pro") {
    // Use API key
}
```

### Privacy Principles

1. **Local Processing First**: All audio/video processed locally
2. **Minimal Network Calls**: Only for OpenAI API (when configured)
3. **No Telemetry**: No analytics without explicit consent
4. **Data Retention**: User-controlled cleanup policies

---

## Testing Strategy

| Layer | Test Type | Framework |
|-------|-----------|-----------|
| Domain | Unit Tests | XCTest |
| Application | Use Case Tests | XCTest |
| Infrastructure | Integration Tests | XCTest + Python unittest |
| Presentation | View Tests | Swift Testing |

---

## Future Extensibility

### Adding New Vision Providers

```swift
// 1. Add enum case
enum VisionProvider {
    case local
    case openAI
    case anthropic  // NEW
}

// 2. Create protocol implementation
class AnthropicVisionProvider: VisionProviderProtocol {
    func analyzeFrames(_ frames: [Data]) async throws -> [Slide] {
        // Anthropic Claude Vision implementation
    }
}

// 3. Register in factory
class VisionProviderFactory {
    static func create(for provider: VisionProvider) -> VisionProviderProtocol {
        switch provider {
        case .local: return OllamaVisionProvider()
        case .openAI: return OpenAIVisionProvider()
        case .anthropic: return AnthropicVisionProvider()
        }
    }
}
```

---

*Document Version: 1.0*  
*Last Updated: March 2026*
