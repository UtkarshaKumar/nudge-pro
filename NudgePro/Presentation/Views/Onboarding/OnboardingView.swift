import SwiftUI

import SwiftUI
import AppKit

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentStep = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressDots(currentStep: currentStep, totalSteps: 5)
                .padding(.top, Spacing.xl)
            
            Spacer()
            
            // Content based on current step
            switch currentStep {
            case 0:
                WelcomeStepView(onContinue: { currentStep = 1 })
            case 1:
                RecordingModeStepView(onContinue: { currentStep = 2 }, onSkip: { currentStep = 2 })
            case 2:
                VisionProviderStepView(onContinue: { currentStep = 3 }, onSkip: { currentStep = 3 })
            case 3:
                StoragePathStepView(onContinue: { currentStep = 4 })
            case 4:
                PermissionsStepView(onComplete: {
                    UserPreferences.shared.hasCompletedOnboarding = true
                    onComplete()
                })
            default:
                EmptyView()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }
}

struct ProgressDots: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? Color.accentPrimary : Color.border)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct WelcomeStepView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // App Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.accentPrimary, .accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            // Title
            Text("nudge")
                .font(.appTitle)
                .foregroundColor(.textPrimary)
            
            // Tagline
            Text("Your intelligent meeting scribe")
                .font(.body)
                .foregroundColor(.textSecondary)
            
            Spacer().frame(height: Spacing.xl)
            
            LinearButton(title: "Get Started", icon: "arrow.right", style: .primary) {
                onContinue()
            }
        }
        .padding(Spacing.xl)
    }
}

struct RecordingModeStepView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    @State private var selectedMode: RecordingMode = .audioOnly
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("How do you want to record?")
                .font(.screenTitle)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: Spacing.md) {
                OptionCard(
                    title: "Audio-only",
                    icon: "mic.fill",
                    description: "Capture meeting audio only. Faster processing, uses less storage.",
                    isSelected: selectedMode == .audioOnly
                ) {
                    selectedMode = .audioOnly
                }
                
                // Hidden: Screen recording option (for now)
                if false {
                    OptionCard(
                        title: "Screen + Audio",
                        icon: "rectangle.on.rectangle",
                        description: "Record your screen with audio. Full meeting capture with visual content.",
                        isSelected: selectedMode == .screenAndAudio
                    ) {
                        selectedMode = .screenAndAudio
                    }
                }
            }
            .padding(.top, Spacing.md)
            
            Spacer()
            
            HStack {
                LinearButton(title: "Exit", style: .ghost) {
                    onSkip()
                }
                
                Spacer()
                
                LinearButton(title: "Continue", icon: "arrow.right", style: .primary) {
                    // Save the selected mode - always audio only for now
                    UserDefaults.standard.set(RecordingMode.audioOnly.rawValue, forKey: "recordingMode")
                    onContinue()
                }
            }
        }
        .padding(Spacing.xl)
    }
}

struct VisionProviderStepView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    @State private var selectedProvider: VisionProvider = .local
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("How should we process visual content?")
                .font(.screenTitle)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: Spacing.md) {
                OptionCard(
                    title: "Local (Ollama)",
                    icon: "desktopcomputer",
                    description: "Free, runs on your Mac. Requires ~8GB RAM. Slower processing.",
                    isSelected: selectedProvider == .local
                ) {
                    selectedProvider = .local
                }
                
                OptionCard(
                    title: "OpenAI API",
                    icon: "cloud.fill",
                    description: "Faster, better results. Provide your own API key (~10$/month).",
                    isSelected: selectedProvider == .openAI
                ) {
                    selectedProvider = .openAI
                }
            }
            .padding(.top, Spacing.md)
            
            Spacer()
            
            HStack {
                LinearButton(title: "Exit", style: .ghost) {
                    onSkip()
                }
                
                Spacer()
                
                LinearButton(title: "Continue", icon: "arrow.right", style: .primary) {
                    // Save the selected provider
                    UserDefaults.standard.set(selectedProvider.rawValue, forKey: "visionProvider")
                    onContinue()
                }
            }
        }
        .padding(Spacing.xl)
    }
}

struct StoragePathStepView: View {
    let onContinue: () -> Void
    
    @State private var storagePath: String = "~/Documents/Nudge Sessions"
    @State private var isVerifying = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Where should we save your recordings?")
                .font(.screenTitle)
                .foregroundColor(.textPrimary)
            
            Text("Nudge needs access to this folder to save your meeting recordings and notes.")
                .font(.body)
                .foregroundColor(.textSecondary)
            
            HStack {
                Text(storagePath)
                    .font(.mono)
                    .foregroundColor(.textSecondary)
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.input)
                            .fill(Color.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.input)
                            .stroke(Color.border, lineWidth: 1)
                    )
                
                Button("Choose...") {
                    selectStoragePath()
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentPrimary)
            }
            .padding(.top, Spacing.md)
            
            if isVerifying {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Verifying folder access...")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                LinearButton(title: "Continue", icon: "arrow.right", style: .primary) {
                    verifyAndSaveStoragePath()
                }
                .disabled(isVerifying)
            }
        }
        .padding(Spacing.xl)
        .onAppear {
            verifyDefaultFolderAccess()
        }
    }
    
    private func selectStoragePath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Select a folder to save meeting recordings"
        
        if panel.runModal() == .OK, let url = panel.url {
            storagePath = url.path
            
            // Try to access/create folder to trigger macOS permission prompt
            do {
                let fileManager = FileManager.default
                
                // Create directory if it doesn't exist
                if !fileManager.fileExists(atPath: url.path) {
                    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                }
                
                // Create a test file to trigger permission alert
                let testFile = url.appendingPathComponent(".nudge-access-test")
                let testData = "Nudge Pro needs access to this folder".data(using: .utf8)!
                try testData.write(to: testFile)
                
                // Clean up test file
                try? fileManager.removeItem(at: testFile)
                
                print("Storage folder access verified: \(url.path)")
            } catch {
                print("Failed to access storage folder: \(error)")
            }
        }
    }
    
    private func verifyAndSaveStoragePath() {
        isVerifying = true
        
        // Expand ~ to actual home directory
        let expandedPath = NSString(string: storagePath).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        do {
            let fileManager = FileManager.default
            
            // Create directory if it doesn't exist
            if !fileManager.fileExists(atPath: expandedPath) {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            }
            
            // Create a test file to trigger permission alert
            let testFile = url.appendingPathComponent(".nudge-access-test")
            let testData = "Nudge Pro needs access to this folder".data(using: .utf8)!
            try testData.write(to: testFile)
            
            // Clean up test file
            try? fileManager.removeItem(at: testFile)
            
            print("Storage folder access verified: \(expandedPath)")
            
            // Save to UserPreferences
            UserPreferences.shared.storagePath = storagePath
            
            isVerifying = false
            onContinue()
            
        } catch {
            print("Failed to access storage folder: \(error)")
            isVerifying = false
            
            // Even if verification fails, save the path - user may need to grant permission later
            UserPreferences.shared.storagePath = storagePath
            onContinue()
        }
    }
    
    private func verifyDefaultFolderAccess() {
        let expandedPath = NSString(string: storagePath).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        do {
            let fileManager = FileManager.default
            
            // Create directory if it doesn't exist - this triggers macOS permission
            if !fileManager.fileExists(atPath: expandedPath) {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            }
            
            // Create a test file - this also triggers permission
            let testFile = url.appendingPathComponent(".nudge-access-test")
            let testData = "Nudge Pro needs access".data(using: .utf8)!
            try testData.write(to: testFile)
            try? fileManager.removeItem(at: testFile)
            
            print("Default folder access verified on appear: \(expandedPath)")
        } catch {
            print("Could not verify default folder on appear: \(error)")
        }
    }
}

struct OptionCard: View {
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .accentPrimary : .textSecondary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.sectionHeader)
                        .foregroundColor(.textPrimary)
                    
                    Text(description)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentPrimary)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .fill(Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(
                        isSelected ? Color.accentPrimary : Color.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct PermissionsStepView: View {
    let onComplete: () -> Void
    
    @State private var microphoneStatus: PermissionState = .notDetermined
    @State private var screenRecordingStatus: PermissionState = .notDetermined
    @State private var speechRecognitionStatus: PermissionState = .notDetermined
    @State private var isRequesting = false
    @State private var errorMessage: String?
    
    enum PermissionState {
        case notDetermined
        case checking
        case granted
        case denied
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Permissions Required")
                .font(.screenTitle)
                .foregroundColor(.textPrimary)
            
            Text("Nudge uses macOS Screen Recording permission to capture system audio from meeting apps (Zoom, Teams, Google Meet). Your microphone captures your voice. Speech Recognition converts audio to text.")
                .font(.body)
                .foregroundColor(.textSecondary)
            
            VStack(spacing: Spacing.md) {
                permissionRow(
                    title: "Microphone",
                    description: "Required to record meeting audio",
                    icon: "mic.fill",
                    status: microphoneStatus
                )
                
                Divider()
                    .padding(.horizontal, Spacing.md)
                
                permissionRow(
                    title: "Screen Recording",
                    description: "Required to capture system audio (meeting apps like Zoom, Teams)",
                    icon: "rectangle.on.rectangle",
                    status: screenRecordingStatus
                )
                
                Divider()
                    .padding(.horizontal, Spacing.md)
                
                permissionRow(
                    title: "Speech Recognition",
                    description: "Required to transcribe audio to text",
                    icon: "waveform",
                    status: speechRecognitionStatus
                )
            }
            .padding(.top, Spacing.md)
            
            if let error = errorMessage {
                Text(error)
                    .font(.bodySmall)
                    .foregroundColor(.red)
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .fill(Color.red.opacity(0.1))
                    )
            }
            
            Spacer()
            
            HStack {
                Button("Exit") {
                    UserPreferences.shared.hasCompletedOnboarding = true
                    onComplete()
                }
                .buttonStyle(.plain)
                .foregroundColor(.textSecondary)
                
                Spacer()
                
                if isRequesting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if microphoneStatus == .granted && screenRecordingStatus == .granted && speechRecognitionStatus == .granted {
                    LinearButton(title: "Continue", icon: "arrow.right", style: .primary) {
                        onComplete()
                    }
                } else {
                    LinearButton(title: "Grant Access", icon: "lock.open", style: .primary) {
                        requestPermissions()
                    }
                }
            }
        }
        .padding(Spacing.xl)
        .onAppear {
            checkPermissions()
        }
    }
    
    private func permissionRow(title: String, description: String, icon: String, status: PermissionState) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentPrimary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.sectionHeader)
                    .foregroundColor(.textPrimary)
                
                Text(description)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            statusBadge(status)
        }
        .padding(Spacing.md)
    }
    
    private func statusBadge(_ status: PermissionState) -> some View {
        HStack(spacing: Spacing.xs) {
            switch status {
            case .notDetermined, .checking:
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                Text("Not Granted")
                    .font(.caption)
                    .foregroundColor(.orange)
            case .granted:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Granted")
                    .font(.caption)
                    .foregroundColor(.green)
            case .denied:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("Denied")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func checkPermissions() {
        Task {
            let manager = PermissionsManager()
            
            let micGranted = await manager.checkMicrophonePermission()
            let screenGranted = await manager.checkScreenRecordingPermission()
            let speechService = TranscriptionService()
            let speechGranted = speechService.checkPermission()
            
            await MainActor.run {
                microphoneStatus = micGranted ? .granted : .denied
                screenRecordingStatus = screenGranted ? .granted : .denied
                speechRecognitionStatus = speechGranted ? .granted : .denied
            }
        }
    }
    
    private func requestPermissions() {
        isRequesting = true
        errorMessage = nil
        
        Task { @MainActor in
            let manager = PermissionsManager()
            
            let micResult = await manager.requestMicrophonePermission()
            let screenResult = await manager.requestScreenRecordingPermission()
            
            let speechService = TranscriptionService()
            let speechResult = await speechService.requestPermission()
            
            microphoneStatus = micResult ? .granted : .denied
            screenRecordingStatus = screenResult ? .granted : .denied
            speechRecognitionStatus = speechResult ? .granted : .denied
            
            isRequesting = false
            
            if micResult && screenResult {
                onComplete()
            } else {
                var missing: [String] = []
                if !micResult { missing.append("Microphone") }
                if !screenResult { missing.append("Screen Recording") }
                errorMessage = "Please grant \(missing.joined(separator: " and ")) permissions in System Settings, then try again."
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
