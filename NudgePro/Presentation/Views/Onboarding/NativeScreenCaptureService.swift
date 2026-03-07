import ScreenCaptureKit
import AVFoundation
import Combine
import CoreMedia

/// Native screen recording service using ScreenCaptureKit
@available(macOS 13.0, *)
@MainActor
final class NativeScreenCaptureService: NSObject, RecordingServiceProtocol {
    
    @Published private(set) var recordingState: RecordingState = .idle
    
    private var stream: SCStream?
    // Thread-safe AVAssetWriter components - accessed from background queue in delegate
    nonisolated(unsafe) private var videoWriter: AVAssetWriter?
    nonisolated(unsafe) private var videoInput: AVAssetWriterInput?
    nonisolated(unsafe) private var audioInput: AVAssetWriterInput?
    nonisolated(unsafe) private var microphoneInput: AVAssetWriterInput?
    
    private var outputURL: URL?
    private var currentSession: Session?
    private var recordingStartTime: Date?
    
    private let displayManager = DisplayManager()
    private let audioDeviceManager = AudioDeviceManager()
    
    // Microphone capture using AVAudioEngine
    private var audioEngine: AVAudioEngine?
    private var microphoneNode: AVAudioInputNode?
    private var audioMixerNode: AVAudioMixerNode?
    private var micFileMixerNode: AVAudioMixerNode?
    
    // MARK: - RecordingServiceProtocol
    
    func startRecording(mode: RecordingMode, monitor: Monitor?) async throws -> Session {
        // Allow starting if idle or completed (but not if recording or processing)
        guard recordingState == .idle || recordingState == .completed else {
            throw RecordingError.startFailed("Already recording")
        }
        
        // Reset state from completed to idle if needed
        if recordingState == .completed {
            recordingState = .idle
        }
        
        print("🎬 Starting native recording - Mode: \(mode.displayName)")
        
        // Create session
        let session = Session(
            title: "Meeting \(Date().formatted(.dateTime.month().day().hour().minute()))",
            recordingMode: mode,
            monitor: monitor
        )
        
        // Setup output file
        let storagePath = UserPreferences.shared.storagePath
        let expandedPath = NSString(string: storagePath).expandingTildeInPath
        let sessionFolder = URL(fileURLWithPath: expandedPath)
            .appendingPathComponent(session.id.uuidString)
        
        try FileManager.default.createDirectory(at: sessionFolder, withIntermediateDirectories: true)
        
        // For ALL recordings, we use ScreenCaptureKit to capture:
        // - System audio (other meeting participants)
        // - Microphone (your voice)
        
        // Get display to record
        let display: DisplayManager.Display
        if let monitor = monitor,
           let displayID = monitor.id.split(separator: "-").first,
           let foundDisplay = try await displayManager.getDisplay(byID: String(displayID)) {
            display = foundDisplay
        } else {
            guard let primaryDisplay = try await displayManager.getPrimaryDisplay() else {
                throw RecordingError.startFailed("No displays available")
            }
            display = primaryDisplay
        }
        
        // Update session with actual display
        let sessionWithDisplay = Session(
            title: session.title,
            recordingMode: mode,
            monitor: display.toMonitor()
        )
        
        let outputURL = sessionFolder.appendingPathComponent("recording.mp4")
        self.outputURL = outputURL
        self.currentSession = session
        self.recordingStartTime = Date()
        
        // Always use ScreenCaptureKit for audio + video
        // It captures system audio from other meeting participants
        try await setupScreenCapture(display: display, mode: mode, outputURL: outputURL)
        
        recordingState = .recording
        print("✅ Native recording started - Output: \(outputURL.path)")
        
        return session
    }
    
    func stopRecording() async throws -> Session {
        guard recordingState == .recording else {
            throw RecordingError.stopFailed("Not currently recording")
        }
        
        print("⏹️ Stopping native screen recording")
        
        // Stop the stream
        try? await stream?.stopCapture()
        stream = nil
        
        // Finalize video file
        await finalizeRecording()
        
        guard var session = currentSession else {
            throw RecordingError.stopFailed("No active session")
        }
        
        session.stoppedAt = Date()
        session.status = .processing
        
        // Get audio file path (microphone recording) - now using .wav format
        let audioURL = outputURL?.deletingPathExtension().appendingPathExtension("wav")
        
        if let outputURL = outputURL {
            session.videoPath = outputURL
            
            // Save audio path for playback
            if let audioPath = audioURL, FileManager.default.fileExists(atPath: audioPath.path) {
                session.audioPath = audioPath
            }
        }
        
        // Save session with status = processing
        SessionStore.shared.save(session)
        
        // Clear current session
        currentSession = nil
        recordingState = .completed
        
        // Process in background - don't await
        processSessionInBackground(session: session, audioURL: audioURL)
        
        print("Recording stopped, processing in background: \(session.title)")
        return session
    }
    
    /// Process session in background (transcription + AI)
    private func processSessionInBackground(session: Session, audioURL: URL?) {
        Task {
            var processedSession = session
            
            do {
                // TRANSCRIPTION
                if let outputURL = session.videoPath ?? session.audioPath {
                    print("Background: Starting transcription...")
                    
                    let transcriptionService = TranscriptionService()
                    
                    // Check permission
                    if !transcriptionService.checkPermission() {
                        let granted = await transcriptionService.requestPermission()
                        if !granted {
                            processedSession.transcript = "Speech recognition permission not granted."
                            processedSession.notes = generateBasicNotes(from: processedSession)
                            processedSession.status = .completed
                            SessionStore.shared.save(processedSession)
                            return
                        }
                    }
                    
                    // Use microphone file if available
                    var audioToTranscribe = outputURL
                    if let micURL = audioURL, FileManager.default.fileExists(atPath: micURL.path) {
                        audioToTranscribe = micURL
                    }
                    
                    let transcript = try await transcriptionService.transcribe(videoURL: audioToTranscribe)
                    processedSession.transcript = transcript
                    print("Background: Transcription complete")
                }
                
                // AI PROCESSING
                if let transcript = processedSession.transcript, !transcript.isEmpty {
                    print("Background: Starting AI processing...")
                    
                    let llmService = LLMService()
                    let isAvailable = await llmService.checkAvailability()
                    
                    if isAvailable {
                        // Extract action items
                        let actions = try await llmService.extractActions(from: transcript)
                        processedSession.actions = actions
                        
                        // Generate meeting notes
                        let notes = try await llmService.generateMeetingNotes(
                            from: transcript,
                            actions: actions
                        )
                        processedSession.notes = notes
                    } else {
                        processedSession.notes = generateBasicNotes(from: processedSession)
                    }
                } else {
                    processedSession.notes = generateBasicNotes(from: processedSession)
                }
                
                // COMPLETE
                processedSession.status = .completed
                print("Background: Processing complete")
                
            } catch {
                print("Background: Processing error - \(error.localizedDescription)")
                processedSession.notes = generateBasicNotes(from: processedSession)
                processedSession.status = .completed
            }
            
            // Save final session
            SessionStore.shared.save(processedSession)
            
            // Save meeting notes as Markdown file
            if let notes = processedSession.notes, !notes.isEmpty,
               let sessionFolder = processedSession.audioPath?.deletingLastPathComponent() {
                let notesFileURL = sessionFolder.appendingPathComponent("meeting-notes.md")
                do {
                    try notes.write(to: notesFileURL, atomically: true, encoding: .utf8)
                    processedSession.notesPath = notesFileURL
                    SessionStore.shared.save(processedSession)
                } catch {
                    print("Background: Failed to save notes - \(error)")
                }
            }
            
            // Delete video file - keep only audio
            if let videoPath = processedSession.videoPath {
                do {
                    try FileManager.default.removeItem(at: videoPath)
                    processedSession.videoPath = nil
                    SessionStore.shared.save(processedSession)
                } catch {
                    print("Background: Failed to delete video - \(error)")
                }
            }
            
            print("Background: All done for \(processedSession.title)")
        }
    }
    
    /// Generate basic meeting notes when Ollama is not available
    private func generateBasicNotes(from session: Session) -> String {
        var notes = "# Meeting Notes\n\n"
        notes += "**Date:** \(Date().formatted(date: .abbreviated, time: .shortened))\n\n"
        
        // Add note about AI insights
        notes += "⚠️ **AI-Powered Insights Unavailable**\n\n"
        notes += "To get AI-generated meeting summaries and action items:\n"
        notes += "1. Install [Ollama](https://ollama.ai) (free, runs locally)\n"
        notes += "2. Run: `ollama pull \(UserPreferences.shared.ollamaModel)`\n"
        notes += "3. Start Ollama and record again\n\n"
        notes += "---\n\n"
        
        if let transcript = session.transcript, !transcript.isEmpty {
            notes += "## Transcript\n\n\(transcript)\n\n"
        } else {
            notes += "## Summary\n\nMeeting recording completed. Transcript not available.\n\n"
        }
        
        if !session.actions.isEmpty {
            notes += "## Action Items\n\n"
            for action in session.actions {
                let checkbox = action.status == .completed ? "[x]" : "[ ]"
                notes += "\(checkbox) \(action.task)"
                if let assignee = action.assignee {
                    notes += " (@\(assignee))"
                }
                if let deadline = action.deadline {
                    notes += " - Due: \(deadline)"
                }
                notes += "\n"
            }
            notes += "\n"
        }
        
        return notes
    }
    
    func getAvailableMonitors() async -> [Monitor] {
        do {
            let displays = try await displayManager.getDisplays()
            return displays.map { $0.toMonitor() }
        } catch {
            print("❌ Failed to get displays: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Checks if the app has proper code signing (development or distribution)
    /// On macOS 26.3+, adhoc-signed apps will crash with TCC SIGKILL when accessing
    /// speech recognition. This check prevents that crash.
    private func checkProperCodeSigning() async -> Bool {
        guard let appBundle = Bundle.main.executableURL else {
            print("⚠️ Could not get app bundle path")
            return false
        }
        
        do {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
            task.arguments = ["-dvv", appBundle.path]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                print("⚠️ Could not read codesign output")
                return false
            }
            
            // Check if we have a proper team identifier (not adhoc)
            // Adhoc signing shows: "Signature=adhoc" and "TeamIdentifier=not set"
            // Proper signing shows a team ID like "TeamIdentifier=ABC123DEF4"
            let hasAdHoc = output.contains("Signature=adhoc")
            let hasNoTeam = output.contains("TeamIdentifier=not set")
            
            if hasAdHoc || hasNoTeam {
                print("⚠️ App is adhoc signed without a Team ID. Speech recognition will be disabled to prevent TCC crash.")
                print("   To enable transcription: Add your Apple Developer Team ID to project.yml")
                return false
            }
            
            print("✅ App has proper code signing with Team ID")
            return true
            
        } catch {
            print("⚠️ Could not check code signing: \(error.localizedDescription)")
            return false
        }
    }
    
    func checkPermissions() async -> PermissionStatus {
        let manager = PermissionsManager()
        
        // Step 1: Check and request Microphone permission first
        print("🎤 Step 1: Checking microphone permission...")
        let micStatus = await manager.checkMicrophonePermission()
        var finalMic = micStatus
        
        if !micStatus {
            print("🎤 Microphone not authorized, requesting permission...")
            finalMic = await manager.requestMicrophonePermission()
            if finalMic {
                print("✅ Microphone permission granted!")
            } else {
                print("❌ Microphone permission denied by user")
                // Return immediately if microphone is denied - don't check other permissions
                return PermissionStatus(
                    canRecordAudio: false,
                    canRecordScreen: false,
                    missingPermissions: ["Microphone"]
                )
            }
        } else {
            print("✅ Microphone permission already granted")
        }
        
        // Step 2: Only proceed to check Screen Recording if Microphone is granted
        print("🖥️ Step 2: Checking screen recording permission...")
        let screenStatus = await manager.checkScreenRecordingPermission()
        var finalScreen = screenStatus
        
        if !screenStatus {
            print("🖥️ Screen recording not authorized, requesting permission...")
            finalScreen = await manager.requestScreenRecordingPermission()
            if finalScreen {
                print("✅ Screen recording permission granted!")
            } else {
                print("⚠️ Screen recording permission denied or not granted yet")
                // Note: Screen recording might need manual enable in System Settings
            }
        } else {
            print("✅ Screen recording permission already granted")
        }
        
        var missing: [String] = []
        if !finalScreen {
            missing.append("Screen Recording")
        }
        if !finalMic {
            missing.append("Microphone")
        }
        
        let status = PermissionStatus(
            canRecordAudio: finalMic,
            canRecordScreen: finalScreen,
            missingPermissions: missing
        )
        
        print("📋 Final permission status: canRecordAudio=\(finalMic), canRecordScreen=\(finalScreen), missing=\(missing)")
        return status
    }
    
    // MARK: - Screen Capture Setup
    
    private func setupScreenCapture(display: DisplayManager.Display, mode: RecordingMode, outputURL: URL) async throws {
        // Get shareable content
        let content = try await SCShareableContent.current
        
        guard let scDisplay = content.displays.first(where: { $0.displayID == display.displayID }) else {
            throw RecordingError.startFailed("Display not found")
        }
        
        // Create filter (capture entire display, no window filtering)
        let filter = SCContentFilter(display: scDisplay, excludingWindows: [])
        
        // Configure stream
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(15)) // 15 FPS
        config.queueDepth = 5
        config.showsCursor = true
        
        // Audio configuration - ALWAYS capture audio for meetings
        // This captures system audio (other participants from Zoom/Teams/Meet)
        config.capturesAudio = true
        config.sampleRate = 44100
        config.channelCount = 2
        
        print("🎤 Audio capture enabled in config")
        
        // Setup video writer
        try setupVideoWriter(outputURL: outputURL, size: CGSize(width: display.width, height: display.height))
        
        // Create and start stream
        let stream = SCStream(filter: filter, configuration: config, delegate: self)
        
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: DispatchQueue(label: "com.nudge.screen"))
        
        // Always add audio output - captures system audio
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: DispatchQueue(label: "com.nudge.audio"))
        
        try await stream.startCapture()
        
        self.stream = stream
        print("✅ ScreenCaptureKit stream started - capturing system audio")
        
        // Start microphone capture to separate file
        do {
            try setupMicrophoneToSeparateFile()
        } catch {
            print("⚠️ Microphone capture failed: \(error)")
        }
    }
    
    /// Record microphone to a separate file using AVAudioEngine
    /// Use native format to avoid conversion issues
    private var micAudioFile: AVAudioFile?
    private var micFileURL: URL?

    private func setupMicrophoneToSeparateFile() throws {
        guard let outputURL = self.outputURL else { return }

        // Use .wav extension since we're using Linear PCM
        micFileURL = outputURL.deletingPathExtension().appendingPathExtension("wav")
        guard let micURL = micFileURL else { return }

        // Remove existing file
        try? FileManager.default.removeItem(at: micURL)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)

        print("Mic native format: \(inputFormat.sampleRate) Hz, \(inputFormat.channelCount) ch, format: \(inputFormat.formatDescription)")

        // Get sample rate and channels from native format
        let sampleRate = inputFormat.sampleRate > 0 ? inputFormat.sampleRate : 44100
        let channels = inputFormat.channelCount > 0 ? inputFormat.channelCount : 1
        
        // Use standard WAV settings matching the native format
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        print("Writing with settings: sampleRate=\(sampleRate), channels=\(channels)")
        
        do {
            let audioFile = try AVAudioFile(
                forWriting: micURL,
                settings: audioSettings
            )
            self.micAudioFile = audioFile

            // Install tap on input node - use native format
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, time in
                guard let file = self.micAudioFile else { return }
                
                do {
                    try file.write(from: buffer)
                } catch {
                    print("Error writing mic audio: \(error)")
                }
            }

            try engine.start()
            self.audioEngine = engine

            print("Microphone recording started: \(micURL.path)")
        } catch {
            print("❌ Failed to create audio file: \(error)")
        }
    }
    
    /// Setup microphone capture using AVAudioEngine
    /// This captures YOUR voice while ScreenCaptureKit captures system audio (meeting participants)
    private func setupMicrophoneCapture() throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let mixerNode = AVAudioMixerNode()
        
        engine.attach(mixerNode)
        
        // Get the input format
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // Connect input node to mixer
        engine.connect(inputNode, to: mixerNode, format: inputFormat)
        
        // Create audio settings for microphone input
        let micSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1, // Mono for microphone
            AVEncoderBitRateKey: 64000
        ]
        
        let micInput = AVAssetWriterInput(mediaType: .audio, outputSettings: micSettings)
        micInput.expectsMediaDataInRealTime = true
        
        videoWriter?.add(micInput)
        self.microphoneInput = micInput
        
        // Install tap to capture audio
        mixerNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
            guard let self = self,
                  let micInput = self.microphoneInput,
                  micInput.isReadyForMoreMediaData else { return }
            
            // Convert audio buffer to sample buffer
            if let sampleBuffer = self.createSampleBuffer(from: buffer, presentationTime: time) {
                micInput.append(sampleBuffer)
            }
        }
        
        // Start the audio engine
        try engine.start()
        
        self.audioEngine = engine
        self.microphoneNode = inputNode
        self.audioMixerNode = mixerNode
        
        print("✅ Microphone capture started (your voice)")
    }
    
    /// Helper to convert AVAudioPCMBuffer to CMSampleBuffer
    private func createSampleBuffer(from buffer: AVAudioPCMBuffer, presentationTime: AVAudioTime) -> CMSampleBuffer? {
        let formatDescription = buffer.format.formatDescription
        
        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: CMTimeScale(buffer.format.sampleRate)),
            presentationTimeStamp: CMTime(value: presentationTime.sampleTime, timescale: CMTimeScale(buffer.format.sampleRate)),
            decodeTimeStamp: .invalid
        )
        
        let status = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: nil,
            dataReady: false,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleCount: CMItemCount(buffer.frameLength),
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        
        guard status == noErr, let sampleBuffer = sampleBuffer else {
            return nil
        }
        
        return sampleBuffer
    }
    
    // MARK: - Audio-Only Recording
    
    private func setupMicrophoneRecording(outputURL: URL) throws {
        // Remove existing file if any
        try? FileManager.default.removeItem(at: outputURL)
        
        // Create audio engine
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        
        // Get input format
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // Create audio file for recording
        let audioFile = try AVAudioFile(
            forWriting: outputURL,
            settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 128000
            ]
        )
        
        // Install tap on input node to capture audio
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
            do {
                try audioFile.write(from: buffer)
            } catch {
                print("Error writing audio: \(error)")
            }
        }
        
        // Start the engine
        try engine.start()
        
        self.audioEngine = engine
        print("✅ Microphone recording started - File: \(outputURL.path)")
    }
    
    private func setupVideoWriter(outputURL: URL, size: CGSize) throws {
        // Remove existing file if any
        try? FileManager.default.removeItem(at: outputURL)
        
        // Create asset writer
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        // Video input settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6_000_000, // 6 Mbps
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            ]
        ]
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true
        
        // Audio input settings
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128000
        ]
        
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput.expectsMediaDataInRealTime = true
        
        writer.add(videoInput)
        writer.add(audioInput)
        
        self.videoWriter = writer
        self.videoInput = videoInput
        self.audioInput = audioInput
        
        print("✅ AVAssetWriter configured")
    }
    
    private func finalizeRecording() async {
        // Stop microphone capture if running
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            audioEngine = nil
            print("Microphone engine stopped")
        }
        
        // Close microphone audio file
        if micAudioFile != nil {
            micAudioFile = nil
            print("✅ Microphone file finalized")
        }
        
        guard let writer = videoWriter else { return }
        
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        microphoneInput?.markAsFinished()
        
        await writer.finishWriting()
        
        if writer.status == .completed {
            print("✅ Video file finalized successfully")
        } else if let error = writer.error {
            print("❌ Video finalization error: \(error.localizedDescription)")
        }
        
        videoWriter = nil
        videoInput = nil
        audioInput = nil
        microphoneInput = nil
    }
}

// MARK: - SCStreamDelegate

@available(macOS 13.0, *)
extension NativeScreenCaptureService: SCStreamDelegate {
    
    /// Called on a background queue when stream stops with error
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("❌ Stream stopped with error: \(error.localizedDescription)")
        Task { @MainActor in
            self.recordingState = .error(error.localizedDescription)
        }
    }
}

// MARK: - SCStreamOutput

@available(macOS 13.0, *)
extension NativeScreenCaptureService: SCStreamOutput {
    
    /// This method is called on a background queue and should not be MainActor-isolated
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard sampleBuffer.isValid else { 
            print("⚠️ Invalid sample buffer")
            return 
        }
        
        // Start writing session if needed
        if let writer = self.videoWriter, writer.status == .unknown {
            writer.startWriting()
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        }
        
        switch type {
        case .screen:
            // Write video frame
            if let videoInput = self.videoInput, videoInput.isReadyForMoreMediaData {
                videoInput.append(sampleBuffer)
            }
            
        case .audio:
            // Debug: Check audio buffer details
            if let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) {
                if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) {
                    print("🎵 Audio sample rate: \(asbd.pointee.mSampleRate), channels: \(asbd.pointee.mChannelsPerFrame), bytesPerFrame: \(asbd.pointee.mBytesPerFrame)")
                }
            }
            
            // Write audio sample only if ready
            guard let audioInput = self.audioInput else {
                print("⚠️ No audio input available")
                return
            }
            
            guard audioInput.isReadyForMoreMediaData else {
                print("⚠️ Audio input not ready for more media data")
                return
            }
            
            audioInput.append(sampleBuffer)
            
        case .microphone:
            break
            
        @unknown default:
            break
        }
    }
}
