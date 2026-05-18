import Foundation
import Speech

class TranscriptionService {
    
    private let bundleScriptName = "whisper_transcribe"
    
    /// Checks if external Whisper transcription is available
    func isWhisperAvailable() -> Bool {
        guard let scriptPath = resolveScriptPath() else {
            print("🔍 Whisper script not found in bundle or development paths")
            return false
        }
        let exists = FileManager.default.fileExists(atPath: scriptPath)
        print("🔍 Whisper script path: \(scriptPath), exists: \(exists)")
        return exists
    }
    
    private func resolveScriptPath() -> String? {
        // Production: check app bundle first
        if let bundlePath = Bundle.main.path(forResource: bundleScriptName, ofType: "py") {
            return bundlePath
        }
        
        // Development: look relative to the executable's build directory
        if let executableURL = Bundle.main.executableURL {
            let buildProductsDir = executableURL
                .deletingLastPathComponent()  // MacOS/
                .deletingLastPathComponent()  // NudgePro.app/
                .deletingLastPathComponent()  // Debug or Release/
            let projectRoot = buildProductsDir
                .deletingLastPathComponent()  // Build/
                .deletingLastPathComponent()  // Products/
            let devScriptPath = projectRoot
                .appendingPathComponent("NudgePro/Resources/Scripts/whisper_transcribe.py")
                .path
            if FileManager.default.fileExists(atPath: devScriptPath) {
                return devScriptPath
            }
        }
        
        return nil
    }
    
    /// Checks if speech recognition is authorized
    func checkPermission() -> Bool {
        do {
            let status = SFSpeechRecognizer.authorizationStatus()
            return status == .authorized
        } catch {
            print("⚠️ Could not check speech recognition permission: \(error)")
            return false
        }
    }
    
    /// Requests speech recognition permission
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    /// Transcribes audio to text - tries Whisper first, then falls back to built-in Speech
    func transcribe(videoURL: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            throw TranscriptionError.fileNotFound(videoURL.path)
        }
        
        // Try Whisper first
        if isWhisperAvailable(), let scriptPath = resolveScriptPath() {
            do {
                print("🎙️ Trying Whisper transcription...")
                let transcript = try await transcribeWithWhisper(audioURL: videoURL, scriptPath: scriptPath)
                print("✅ Whisper transcription complete: \(transcript.count) characters")
                return transcript
            } catch {
                print("⚠️ Whisper transcription failed: \(error.localizedDescription)")
                print("🔄 Falling back to built-in Speech framework...")
            }
        } else {
            print("⚠️ Whisper script not found, using built-in Speech framework")
        }
        
        // Fall back to built-in Speech framework
        return try await transcribeWithSpeech(videoURL: videoURL)
    }
    
    /// Transcribes using external Whisper Python script
    private func transcribeWithWhisper(audioURL: URL, scriptPath: String) async throws -> String {
        let outputPath = audioURL.deletingPathExtension().path + "_transcript.json"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptPath, audioURL.path, "--output", outputPath]
        process.currentDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw TranscriptionError.transcriptionFailed("Whisper failed: \(errorMessage)")
        }
        
        // Read output from JSON file
        if FileManager.default.fileExists(atPath: outputPath) {
            let data = FileManager.default.contents(atPath: outputPath)
            if let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any],
               let transcript = json["transcript"] as? String {
                try? FileManager.default.removeItem(atPath: outputPath)
                return transcript
            }
        }
        
        // Fallback: read from stdout
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Transcribes using built-in Speech framework
    private func transcribeWithSpeech(videoURL: URL) async throws -> String {
        guard checkPermission() else {
            throw TranscriptionError.transcriptionFailed("Speech recognition not authorized")
        }
        
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            throw TranscriptionError.transcriptionFailed("Speech recognizer not available")
        }
        
        do {
            let request = SFSpeechURLRecognitionRequest(url: videoURL)
            request.shouldReportPartialResults = false
            
            return try await withCheckedThrowingContinuation { continuation in
                recognizer.recognitionTask(with: request) { result, error in
                    if let error = error {
                        continuation.resume(throwing: TranscriptionError.transcriptionFailed(error.localizedDescription))
                    } else if let result = result, result.isFinal {
                        continuation.resume(returning: result.bestTranscription.formattedString)
                    }
                }
            }
        } catch {
            throw TranscriptionError.transcriptionFailed("Transcription failed: \(error.localizedDescription)")
        }
    }
}
