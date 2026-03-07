import SwiftUI
import AppKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var recordingMode: RecordingMode {
        didSet { save() }
    }
    
    @Published var visionProvider: VisionProvider {
        didSet { save() }
    }
    
    @Published var askForScreen: Bool {
        didSet { save() }
    }
    
    @Published var storagePath: String {
        didSet { save() }
    }
    
    @Published var autoCleanupDays: Int {
        didSet { save() }
    }
    
    @Published var llmModel: String {
        didSet { save() }
    }
    
    @Published var openAIKey: String {
        didSet { save() }
    }
    
    init() {
        let defaults = UserDefaults.standard
        self.recordingMode = RecordingMode(rawValue: defaults.string(forKey: "recordingMode") ?? "") ?? .audioOnly
        self.visionProvider = VisionProvider(rawValue: defaults.string(forKey: "visionProvider") ?? "") ?? .local
        self.askForScreen = defaults.bool(forKey: "askForScreen")
        self.storagePath = defaults.string(forKey: "storagePath") ?? "~/Documents/Meeting Notes"
        self.autoCleanupDays = defaults.integer(forKey: "autoCleanupDays")
        self.llmModel = defaults.string(forKey: "llmModel") ?? "llama3.2:3b"
        self.openAIKey = ""
    }
    
    func selectStoragePath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Select a folder to save meeting recordings"
        
        if panel.runModal() == .OK, let url = panel.url {
            self.storagePath = url.path
        }
    }
    
    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(recordingMode.rawValue, forKey: "recordingMode")
        defaults.set(visionProvider.rawValue, forKey: "visionProvider")
        defaults.set(askForScreen, forKey: "askForScreen")
        defaults.set(storagePath, forKey: "storagePath")
        defaults.set(autoCleanupDays, forKey: "autoCleanupDays")
        defaults.set(llmModel, forKey: "llmModel")
    }
}
