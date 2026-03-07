import SwiftUI

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    @Published var monitorSelectionMode: MonitorSelectionMode {
        didSet { UserDefaults.standard.set(monitorSelectionMode.rawValue, forKey: "monitorSelectionMode") }
    }
    @Published var selectedTemplateID: String {
        didSet { UserDefaults.standard.set(selectedTemplateID, forKey: "selectedTemplateID") }
    }
    @Published var ollamaModel: String {
        didSet { UserDefaults.standard.set(ollamaModel, forKey: "ollamaModel") }
    }
    @Published var cleanupRetentionDays: Int {
        didSet { UserDefaults.standard.set(cleanupRetentionDays, forKey: "cleanupRetentionDays") }
    }
    @Published var storagePath: String {
        didSet { UserDefaults.standard.set(storagePath, forKey: "storagePath") }
    }
    
    // LLM Provider settings
    @Published var llmProvider: LLMProvider {
        didSet { UserDefaults.standard.set(llmProvider.rawValue, forKey: "llmProvider") }
    }
    @Published var openAIAPIKey: String {
        didSet { UserDefaults.standard.set(openAIAPIKey, forKey: "openAIAPIKey") }
    }
    @Published var anthropicAPIKey: String {
        didSet { UserDefaults.standard.set(anthropicAPIKey, forKey: "anthropicAPIKey") }
    }
    @Published var openAIModel: String {
        didSet { UserDefaults.standard.set(openAIModel, forKey: "openAIModel") }
    }
    @Published var anthropicModel: String {
        didSet { UserDefaults.standard.set(anthropicModel, forKey: "anthropicModel") }
    }
    // Custom provider settings
    @Published var customAPIKey: String {
        didSet { UserDefaults.standard.set(customAPIKey, forKey: "customAPIKey") }
    }
    @Published var customEndpoint: String {
        didSet { UserDefaults.standard.set(customEndpoint, forKey: "customEndpoint") }
    }
    @Published var customModel: String {
        didSet { UserDefaults.standard.set(customModel, forKey: "customModel") }
    }
    
    // Base URLs for each provider
    @Published var ollamaBaseURL: String {
        didSet { UserDefaults.standard.set(ollamaBaseURL, forKey: "ollamaBaseURL") }
    }
    @Published var openAIBaseURL: String {
        didSet { UserDefaults.standard.set(openAIBaseURL, forKey: "openAIBaseURL") }
    }
    @Published var anthropicBaseURL: String {
        didSet { UserDefaults.standard.set(anthropicBaseURL, forKey: "anthropicBaseURL") }
    }

    private init() {
        let defaults = UserDefaults.standard
        self.hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        self.monitorSelectionMode = MonitorSelectionMode(rawValue: defaults.string(forKey: "monitorSelectionMode") ?? "") ?? .automatic
        self.selectedTemplateID = defaults.string(forKey: "selectedTemplateID") ?? "default"
        self.ollamaModel = defaults.string(forKey: "ollamaModel") ?? "llama3.2:latest"
        self.cleanupRetentionDays = defaults.integer(forKey: "cleanupRetentionDays")
        
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let defaultStorage = docsURL?.appendingPathComponent("Nudge Sessions").path ?? "~/Documents/Nudge Sessions"
        self.storagePath = defaults.string(forKey: "storagePath") ?? defaultStorage
        
        // LLM Provider settings
        if let providerRaw = defaults.string(forKey: "llmProvider"),
           let provider = LLMProvider(rawValue: providerRaw) {
            self.llmProvider = provider
        } else {
            self.llmProvider = .ollama  // Default to Ollama - free and runs locally
        }
        self.openAIAPIKey = defaults.string(forKey: "openAIAPIKey") ?? ""
        self.anthropicAPIKey = defaults.string(forKey: "anthropicAPIKey") ?? ""
        self.openAIModel = defaults.string(forKey: "openAIModel") ?? "gpt-4o-mini"
        self.anthropicModel = defaults.string(forKey: "anthropicModel") ?? "claude-3-haiku-20240307"
        self.customAPIKey = defaults.string(forKey: "customAPIKey") ?? ""
        self.customEndpoint = defaults.string(forKey: "customEndpoint") ?? "http://localhost:1234/v1"
        self.customModel = defaults.string(forKey: "customModel") ?? "llama3.2"
        
        // Base URLs
        self.ollamaBaseURL = defaults.string(forKey: "ollamaBaseURL") ?? "http://localhost:11434"
        self.openAIBaseURL = defaults.string(forKey: "openAIBaseURL") ?? "https://api.openai.com"
        self.anthropicBaseURL = defaults.string(forKey: "anthropicBaseURL") ?? "https://api.anthropic.com"
    }

    func reset() {
        hasCompletedOnboarding = false
        monitorSelectionMode = .automatic
        selectedTemplateID = "default"
        ollamaModel = "llama3.2:latest"
        cleanupRetentionDays = 7
        
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        storagePath = docsURL?.appendingPathComponent("Nudge Sessions").path ?? "~/Documents/Nudge Sessions"
        
        llmProvider = .ollama
        openAIAPIKey = ""
        anthropicAPIKey = ""
        openAIModel = "gpt-4o-mini"
        anthropicModel = "claude-3-haiku-20240307"
        customAPIKey = ""
        customEndpoint = "http://localhost:1234/v1"
        customModel = "llama3.2"
        ollamaBaseURL = "http://localhost:11434"
        openAIBaseURL = "https://api.openai.com"
        anthropicBaseURL = "https://api.anthropic.com"
    }
}
