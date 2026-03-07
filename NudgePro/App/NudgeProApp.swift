import SwiftUI
import AVFoundation

@main
struct NudgeProApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var preferences = UserPreferences.shared
    @State private var showingOnboarding = false
    
    init() {
        // Check if onboarding was completed - load from UserDefaults directly
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        _showingOnboarding = State(initialValue: !hasCompleted)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .sheet(isPresented: $showingOnboarding) {
                    OnboardingView(onComplete: {
                        showingOnboarding = false
                    })
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 650)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Nudge") {
                    // TODO: Show about window
                }
            }

            CommandGroup(after: .appSettings) {
                Button("Show Onboarding") {
                    showingOnboarding = true
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Tab = .recording

    enum Tab {
        case recording
        case history
        case search
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Record", systemImage: DesignTokens.Icons.record)
                    .tag(Tab.recording)

                Label("History", systemImage: DesignTokens.Icons.calendar)
                    .tag(Tab.history)

                Label("Search", systemImage: DesignTokens.Icons.search)
                    .tag(Tab.search)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch selectedTab {
            case .recording:
                RecordingView()
            case .history:
                HistoryView()
            case .search:
                SearchView()
            }
        }
        .background(DesignTokens.Colors.background)
    }
}

struct HistoryView: View {
    @State private var sessions: [Session] = []
    @State private var selectedSession: Session?
    @State private var showingExportSheet = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private let exportService = ExportService()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                if sessions.isEmpty {
                    emptyState
                } else {
                    List(sessions, selection: $selectedSession) { session in
                        SessionRow(session: session)
                            .tag(session)
                            .contextMenu {
                                Button("Copy Notes") {
                                    if let notes = session.notes {
                                        exportService.copyToClipboard(notes)
                                    }
                                }

                                Button("Export...") {
                                    selectedSession = session
                                    showingExportSheet = true
                                }

                                Divider()

                                Button("Delete", role: .destructive) {
                                    deleteSession(session)
                                }
                            }
                    }
                }
            }
            .navigationTitle("History")
            .navigationSplitViewColumnWidth(min: 460, ideal: 580, max: 720)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Show All") {
                        columnVisibility = .all
                    }
                    .help("Show all columns")
                }
            }
            .task {
                sessions = SessionStore.shared.loadAll()
            }
            .sheet(isPresented: $showingExportSheet) {
                if let session = selectedSession {
                    ExportSheet(session: session)
                }
            }
        } detail: {
            if let session = selectedSession {
                SessionDetailView(session: session)
            } else {
                Text("Select a meeting to view details")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: DesignTokens.Icons.meeting)
                .font(.system(size: 64))
                .foregroundColor(DesignTokens.Colors.textTertiary)

            Text(Strings.History.empty)
                .font(DesignTokens.Typography.title)
                .foregroundColor(DesignTokens.Colors.text)

            Text(Strings.History.emptyMessage)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func deleteSession(_ session: Session) {
        SessionStore.shared.delete(session)
        sessions.removeAll { $0.id == session.id }
    }
}

struct SearchView: View {
    @State private var sessions: [Session] = []
    @State private var searchText = ""

    private var filteredSessions: [Session] {
        if searchText.isEmpty {
            return sessions
        }
        return sessions.filter { session in
            session.title.localizedCaseInsensitiveContains(searchText) ||
            (session.transcript?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (session.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        VStack {
            HStack {
                Image(systemName: DesignTokens.Icons.search)
                    .foregroundColor(DesignTokens.Colors.textSecondary)

                TextField(Strings.Search.placeholder, text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.surface)
            .cornerRadius(DesignTokens.CornerRadius.input)
            .padding(DesignTokens.Spacing.md)

            if filteredSessions.isEmpty {
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: DesignTokens.Icons.search)
                        .font(.system(size: 48))
                        .foregroundColor(DesignTokens.Colors.textTertiary)

                    Text(searchText.isEmpty ? "Enter search query" : Strings.Search.noResults)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                List(filteredSessions) { session in
                    SessionRow(session: session)
                }
            }
        }
        .navigationTitle("Search")
        .task {
            sessions = SessionStore.shared.loadAll()
        }
    }
}

struct SessionRow: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(session.title)
                .font(DesignTokens.Typography.headline)
                .foregroundColor(DesignTokens.Colors.text)
                .lineLimit(1)
            
            HStack {
                Text(session.formattedDate)
                    .font(DesignTokens.Typography.footnote)
                    .foregroundColor(DesignTokens.Colors.textSecondary)

                Text("\u{2022}")
                    .foregroundColor(DesignTokens.Colors.textTertiary)

                Text(session.formattedDuration)
                    .font(DesignTokens.Typography.footnote)
                    .foregroundColor(DesignTokens.Colors.textSecondary)

                if !session.actionItems.isEmpty {
                    Text("\u{2022}")
                        .foregroundColor(DesignTokens.Colors.textTertiary)

                    Text("\(session.actionItems.count) actions")
                        .font(DesignTokens.Typography.footnote)
                        .foregroundColor(DesignTokens.Colors.accent)
                }
            }
            
            // Meeting summary preview
            if let notes = session.notes, !notes.isEmpty {
                Text(notes.prefix(120) + (notes.count > 120 ? "..." : ""))
                    .font(DesignTokens.Typography.footnote)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(DesignTokens.Spacing.sm)
    }
}

struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let session: Session
    @State private var selectedFormat: ExportService.ExportFormat = .markdown

    private let exportService = ExportService()

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text("Export Meeting Notes")
                .font(DesignTokens.Typography.title)

            Picker("Format", selection: $selectedFormat) {
                Text("Markdown").tag(ExportService.ExportFormat.markdown)
                Text("Plain Text").tag(ExportService.ExportFormat.plainText)
                Text("JSON").tag(ExportService.ExportFormat.json)
            }
            .pickerStyle(.segmented)

            HStack(spacing: DesignTokens.Spacing.md) {
                Button("Copy to Clipboard") {
                    if let content = session.notes {
                        exportService.copyToClipboard(content)
                    }
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("Save File") {
                    exportService.saveToFile(session: session, format: selectedFormat)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: 400, height: 200)
    }
}
