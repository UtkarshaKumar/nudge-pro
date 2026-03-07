import SwiftUI
import AVFoundation
import Speech

struct SettingsView: View {
    @StateObject private var preferences = UserPreferences.shared
    @State private var showingResetAlert = false
    @State private var ollamaStatus: OllamaStatus = .checking
    @State private var availableOllamaModels: [String] = []
    @State private var isLoadingModels = false
    
    // API Key editing state
    @State private var editingOpenAIKey = false
    @State private var editingAnthropicKey = false
    @State private var editingCustomKey = false
    @State private var tempAPIKey = ""
    
    // Permission states
    @State private var screenRecordingStatus: PermissionStatus = .unknown
    @State private var microphoneStatus: PermissionStatus = .unknown
    @State private var speechRecognitionStatus: PermissionStatus = .unknown
    
    enum PermissionStatus {
        case granted
        case denied
        case unknown
        
        var color: Color {
            switch self {
            case .granted: return .green
            case .denied: return .red
            case .unknown: return .orange
            }
        }
        
        var displayName: String {
            switch self {
            case .granted: return "Granted"
            case .denied: return "Denied"
            case .unknown: return "Not Determined"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(Strings.Settings.title)
                        .font(DesignTokens.Typography.title)
                        .foregroundColor(DesignTokens.Colors.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Permissions Settings
                settingsSection(
                    title: "Permissions",
                    icon: "lock.shield"
                ) {
                    VStack(spacing: 0) {
                        permissionRow(
                            title: "Microphone",
                            description: "Required to record meetings",
                            permissionType: .microphone
                        )
                        
                        Divider()
                            .padding(.horizontal, DesignTokens.Spacing.md)
                        
                        permissionRow(
                            title: "Speech Recognition",
                            description: "Required for transcription",
                            permissionType: .speechRecognition
                        )
                    }
                }
                
                // AI Settings
                settingsSection(
                    title: Strings.Settings.aiSection,
                    icon: DesignTokens.Icons.ai
                ) {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        // Provider Selection
                        HStack {
                            Text("AI Provider")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.text)
                            
                            Spacer()
                            
                            Picker("", selection: $preferences.llmProvider) {
                                ForEach(LLMProvider.allCases, id: \.self) { provider in
                                    Text(provider.rawValue).tag(provider)
                                }
                            }
                            .frame(width: 180)
                        }
                        .padding(DesignTokens.Spacing.md)
                        
                        Divider()
                        
                        // Provider-specific settings
                        switch preferences.llmProvider {
                        case .ollama:
                            ollamaSettings
                            
                        case .openai:
                            openAISettings
                            
                        case .anthropic:
                            anthropicSettings
                            
                        case .custom:
                            customSettings
                        }
                    }
                }
                
                // Storage Settings
                settingsSection(
                    title: Strings.Settings.storageSection,
                    icon: "internaldrive"
                ) {
                    VStack(spacing: 0) {
                        // Storage Location
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("Storage Location")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.text)
                            
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(DesignTokens.Colors.accent)
                                
                                Text(preferences.storagePath)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Spacer()
                                
                                Button("Change...") {
                                    selectStoragePath()
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                            
                            Text("Meeting recordings and notes will be saved here")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textTertiary)
                        }
                        .padding(DesignTokens.Spacing.md)
                        
                        Divider()
                        
                        // Cleanup retention
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-cleanup")
                                    .font(DesignTokens.Typography.body)
                                    .foregroundColor(DesignTokens.Colors.text)
                                Text("Delete recordings older than")
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.textTertiary)
                            }
                            
                            Spacer()
                            
                            Picker("", selection: $preferences.cleanupRetentionDays) {
                                Text("2 days").tag(2)
                                Text("7 days").tag(7)
                                Text("30 days").tag(30)
                                Text("90 days").tag(90)
                                Text("Never").tag(0)
                            }
                            .frame(width: 100)
                        }
                        .padding(DesignTokens.Spacing.md)
                        
                        // Show in Finder button
                        HStack {
                            Spacer()
                            Button(action: { openStorageFolder() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "folder")
                                    Text("Open Folder")
                                }
                            }
                            .buttonStyle(GhostButtonStyle())
                        }
                        .padding(DesignTokens.Spacing.md)
                    }
                }
                
                // About Section
                settingsSection(
                    title: Strings.Settings.aboutSection,
                    icon: DesignTokens.Icons.info
                ) {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        HStack {
                            Text(Strings.Settings.version)
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.text)
                            Spacer()
                            Text("1.0.0")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .padding(DesignTokens.Spacing.md)
                        
                        Button("Reset All Settings") {
                            showingResetAlert = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .background(DesignTokens.Colors.background)
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            checkOllama()
            checkAllPermissions()
        }
        .alert("Reset Settings?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                preferences.reset()
            }
        } message: {
            Text("This will reset all settings to their default values.")
        }
    }
    
    // MARK: - Provider Settings Views
    
    @ViewBuilder
    private var ollamaSettings: some View {
        connectionStatusRow(
            status: ollamaStatus,
            action: { checkOllama() }
        )
        
        settingRow(
            title: "Model",
            description: "AI model to use"
        ) {
            if isLoadingModels {
                ProgressView()
                    .scaleEffect(0.8)
            } else if availableOllamaModels.isEmpty {
                TextField("llama3.2:latest", text: $preferences.ollamaModel)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            } else {
                Picker("", selection: $preferences.ollamaModel) {
                    ForEach(availableOllamaModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .frame(width: 200)
            }
        }
        
        HStack {
            Button(action: { loadOllamaModels() }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Models")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(ollamaStatus != .running)
            
            Spacer()
        }
        
        settingRow(
            title: "Server URL",
            description: "Ollama server address"
        ) {
            TextField("http://localhost:11434", text: $preferences.ollamaBaseURL)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
        }
        
        if ollamaStatus == .notRunning {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignTokens.Colors.warning)
                    Text("Ollama Not Running")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.Colors.warning)
                }
                
                Text("To enable AI-powered meeting notes:")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Text("1. Download Ollama from ollama.ai\n2. Run: ollama pull \(preferences.ollamaModel)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Button("Open ollama.ai") {
                    if let url = URL(string: "https://ollama.ai") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(GhostButtonStyle())
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.warning.opacity(0.1))
            .cornerRadius(DesignTokens.CornerRadius.card)
        }
    }
    
    @ViewBuilder
    private var openAISettings: some View {
        apiKeySection(
            providerName: "OpenAI",
            apiKey: $preferences.openAIAPIKey,
            isEditing: $editingOpenAIKey,
            tempKey: $tempAPIKey,
            keyPlaceholder: "sk-...",
            helpURL: "https://platform.openai.com/api-keys",
            helpText: "Get your API key from"
        )
        
        settingRow(
            title: "Model",
            description: "OpenAI model to use"
        ) {
            Picker("", selection: $preferences.openAIModel) {
                Text("GPT-4o Mini").tag("gpt-4o-mini")
                Text("GPT-4o").tag("gpt-4o")
                Text("GPT-4 Turbo").tag("gpt-4-turbo")
                Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
            }
            .frame(width: 180)
        }
        
        settingRow(
            title: "API Endpoint",
            description: "Override if using proxy"
        ) {
            TextField("https://api.openai.com", text: $preferences.openAIBaseURL)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
        }
        
        HStack {
            Spacer()
            Button("Validate") {
                validateOpenAIKey()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    @ViewBuilder
    private var anthropicSettings: some View {
        apiKeySection(
            providerName: "Anthropic",
            apiKey: $preferences.anthropicAPIKey,
            isEditing: $editingAnthropicKey,
            tempKey: $tempAPIKey,
            keyPlaceholder: "sk-ant-...",
            helpURL: "https://console.anthropic.com/settings/keys",
            helpText: "Get your API key from"
        )
        
        settingRow(
            title: "Model",
            description: "Claude model to use"
        ) {
            Picker("", selection: $preferences.anthropicModel) {
                Text("Claude 3 Haiku").tag("claude-3-haiku-20240307")
                Text("Claude 3.5 Sonnet").tag("claude-3-5-sonnet-20241022")
                Text("Claude 3 Opus").tag("claude-3-opus-20240229")
            }
            .frame(width: 180)
        }
        
        settingRow(
            title: "API Endpoint",
            description: "Override if using proxy"
        ) {
            TextField("https://api.anthropic.com", text: $preferences.anthropicBaseURL)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
        }
        
        HStack {
            Spacer()
            Button("Validate") {
                validateAnthropicKey()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    @ViewBuilder
    private var customSettings: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Server Endpoint")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.text)
            
            TextField("http://localhost:1234/v1", text: $preferences.customEndpoint)
                .textFieldStyle(.roundedBorder)
            
            Text("LM Studio, Ollama with OpenAI compatibility, or any OpenAI-compatible API")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        
        Divider()
        
        apiKeySection(
            providerName: "Custom",
            apiKey: $preferences.customAPIKey,
            isEditing: $editingCustomKey,
            tempKey: $tempAPIKey,
            keyPlaceholder: "Optional",
            helpURL: nil,
            helpText: nil
        )
        
        settingRow(
            title: "Model",
            description: "Model identifier"
        ) {
            TextField("llama3.2", text: $preferences.customModel)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
        }
        
        HStack {
            Spacer()
            Button("Validate Connection") {
                validateCustomProvider()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    @ViewBuilder
    private func connectionStatusRow(status: OllamaStatus, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Connection Status")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.text)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 8, height: 8)
                    Text(status.displayName)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(status.color)
                }
            }
            
            Spacer()
            
            Button("Check") {
                action()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.secondaryBackground)
        .cornerRadius(DesignTokens.CornerRadius.card)
    }
    
    @ViewBuilder
    private func apiKeySection(
        providerName: String,
        apiKey: Binding<String>,
        isEditing: Binding<Bool>,
        tempKey: Binding<String>,
        keyPlaceholder: String,
        helpURL: String?,
        helpText: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("\(providerName) API Key")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.text)
            
            if apiKey.wrappedValue.isEmpty || isEditing.wrappedValue {
                SecureField(keyPlaceholder, text: tempKey)
                    .textFieldStyle(.roundedBorder)
                
                if isEditing.wrappedValue {
                    HStack(spacing: 12) {
                        Button("Save") {
                            apiKey.wrappedValue = tempKey.wrappedValue
                            tempKey.wrappedValue = ""
                            isEditing.wrappedValue = false
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Cancel") {
                            tempKey.wrappedValue = ""
                            isEditing.wrappedValue = false
                        }
                    }
                }
            } else {
                HStack {
                    Text("••••••••••••••••")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                    
                    Button("Replace") {
                        tempKey.wrappedValue = ""
                        isEditing.wrappedValue = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            
            if let helpURL = helpURL, let helpText = helpText {
                HStack {
                    Text(helpText)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Button(helpURL.replacingOccurrences(of: "https://", with: "")) {
                        if let url = URL(string: helpURL) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .buttonStyle(GhostButtonStyle())
                }
            }
        }
    }
    
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(DesignTokens.Colors.accent)
                Text(title)
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.text)
            }
            
            VStack(spacing: 0) {
                content()
            }
            .background(DesignTokens.Colors.surface)
            .cornerRadius(DesignTokens.CornerRadius.card)
        }
    }
    
    private func settingRow<Content: View>(
        title: String,
        description: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.text)
                Text(description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
            }
            
            Spacer()
            
            control()
        }
        .padding(DesignTokens.Spacing.md)
    }
    
    private func statusBadge(_ status: OllamaStatus) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            Text(status.displayName)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(status.color)
        }
    }
    
    private func permissionStatusBadge(_ status: PermissionStatus) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            Text(status.displayName)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(status.color)
        }
    }
    
    private func permissionRow(title: String, description: String, permissionType: PermissionType) -> some View {
        let currentStatus = statusForType(permissionType)
        
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.text)
                Text(description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
            }
            
            Spacer()
            
            HStack(spacing: DesignTokens.Spacing.md) {
                permissionStatusBadge(currentStatus)
                
                if currentStatus == .granted {
                    EmptyView()
                } else if currentStatus == .denied {
                    Button("Open Settings") {
                        openSystemSettings(for: permissionType)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    Button("Request") {
                        requestPermissionWithReset(permissionType)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
    }
    
    private func openSystemSettings(for type: PermissionType) {
        let urlString: String
        switch type {
        case .screenRecording:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        case .microphone:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        case .speechRecognition:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition"
        }
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    enum PermissionType {
        case screenRecording
        case microphone
        case speechRecognition
    }
    
    private func statusForType(_ type: PermissionType) -> PermissionStatus {
        switch type {
        case .screenRecording: return screenRecordingStatus
        case .microphone: return microphoneStatus
        case .speechRecognition: return speechRecognitionStatus
        }
    }
    
    // MARK: - Actions
    
    private func checkOllama() {
        ollamaStatus = .checking
        
        Task {
            let service = LLMService()
            let available = await service.checkAvailability()
            await MainActor.run {
                ollamaStatus = available ? .running : .notRunning
                if available {
                    loadOllamaModels()
                }
            }
        }
    }
    
    private func loadOllamaModels() {
        isLoadingModels = true
        
        Task {
            let service = LLMService()
            let models = await service.listOllamaModels()
            await MainActor.run {
                availableOllamaModels = models
                isLoadingModels = false
                if !models.isEmpty && !models.contains(preferences.ollamaModel) {
                    preferences.ollamaModel = models.first ?? "llama3.2:latest"
                }
            }
        }
    }
    
    private func validateOpenAIKey() {
        Task {
            let service = LLMService()
            let isValid = await service.validateProvider(.openai, apiKey: preferences.openAIAPIKey)
            await MainActor.run {
                if isValid {
                    ollamaStatus = .running
                } else {
                    ollamaStatus = .notRunning
                }
            }
        }
    }
    
    private func validateAnthropicKey() {
        Task {
            let service = LLMService()
            let isValid = await service.validateProvider(.anthropic, apiKey: preferences.anthropicAPIKey)
            await MainActor.run {
                if isValid {
                    ollamaStatus = .running
                } else {
                    ollamaStatus = .notRunning
                }
            }
        }
    }
    
    private func validateCustomProvider() {
        Task {
            let service = LLMService()
            let isValid = await service.validateProvider(.custom, apiKey: preferences.customAPIKey)
            await MainActor.run {
                if isValid {
                    ollamaStatus = .running
                } else {
                    ollamaStatus = .notRunning
                }
            }
        }
    }
    
    private func checkAllPermissions() {
        Task {
            let manager = PermissionsManager()
            
            // Check microphone
            let micGranted = await manager.checkMicrophonePermission()
            let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
            await MainActor.run {
                switch micStatus {
                case .authorized:
                    microphoneStatus = .granted
                case .denied, .restricted:
                    microphoneStatus = .denied
                case .notDetermined:
                    microphoneStatus = .unknown
                @unknown default:
                    microphoneStatus = .unknown
                }
            }
            
            // Check screen recording
            let screenGranted = await manager.checkScreenRecordingPermission()
            await MainActor.run {
                screenRecordingStatus = screenGranted ? .granted : .unknown
            }
            
            // Check speech recognition
            let speechService = TranscriptionService()
            let speechGranted = speechService.checkPermission()
            await MainActor.run {
                speechRecognitionStatus = speechGranted ? .granted : .unknown
            }
        }
    }
    
    private func requestPermission(_ type: PermissionType) {
        Task {
            let manager = PermissionsManager()
            
            switch type {
            case .microphone:
                let granted = await manager.requestMicrophonePermission()
                await MainActor.run {
                    microphoneStatus = granted ? .granted : .denied
                }
                
            case .screenRecording:
                let granted = await manager.requestScreenRecordingPermission()
                await MainActor.run {
                    screenRecordingStatus = granted ? .granted : .denied
                }
                
            case .speechRecognition:
                let speechService = TranscriptionService()
                let granted = await speechService.requestPermission()
                await MainActor.run {
                    speechRecognitionStatus = granted ? .granted : .denied
                }
            }
        }
    }
    
    private func requestPermissionWithReset(_ type: PermissionType) {
        Task {
            let manager = PermissionsManager()
            
            switch type {
            case .microphone:
                let granted = await manager.requestMicrophonePermission()
                await MainActor.run {
                    microphoneStatus = granted ? .granted : .denied
                }
                
            case .screenRecording:
                let granted = await manager.requestScreenRecordingPermission()
                await MainActor.run {
                    screenRecordingStatus = granted ? .granted : .denied
                }
                
            case .speechRecognition:
                let speechService = TranscriptionService()
                let granted = await speechService.requestPermission()
                await MainActor.run {
                    speechRecognitionStatus = granted ? .granted : .denied
                }
            }
        }
    }
    
    private func requestScreenRecordingPermission() {
        Task {
            let manager = PermissionsManager()
            let granted = await manager.requestScreenRecordingPermission()
            await MainActor.run {
                self.screenRecordingStatus = granted ? .granted : .denied
            }
        }
    }
    
    private func requestSpeechRecognitionPermission() {
        Task {
            let service = TranscriptionService()
            let granted = await service.requestPermission()
            await MainActor.run {
                self.speechRecognitionStatus = granted ? .granted : .denied
            }
        }
    }
    
    private func requestMicrophonePermissionDirect() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                self.microphoneStatus = granted ? .granted : .denied
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            print("Microphone permission status: \(status.rawValue)")
        }
    }
    
    private func selectStoragePath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to save meeting recordings"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK, let url = panel.url {
            preferences.storagePath = url.path
        }
    }
    
    private func openStorageFolder() {
        let path = preferences.storagePath
        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        if FileManager.default.fileExists(atPath: expandedPath) {
            NSWorkspace.shared.open(url)
        } else {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                NSWorkspace.shared.open(url)
            } catch {
                print("Failed to create storage directory: \(error)")
            }
        }
    }
}

// MARK: - Ollama Status

enum OllamaStatus {
    case checking
    case running
    case notRunning
    
    var displayName: String {
        switch self {
        case .checking: return "Checking..."
        case .running: return Strings.Settings.ollamaConnected
        case .notRunning: return Strings.Settings.ollamaDisconnected
        }
    }
    
    var color: Color {
        switch self {
        case .checking: return DesignTokens.Colors.textSecondary
        case .running: return DesignTokens.Colors.success
        case .notRunning: return DesignTokens.Colors.warning
        }
    }
}

#Preview {
    SettingsView()
}
