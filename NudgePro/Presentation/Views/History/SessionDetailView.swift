import SwiftUI
import AVKit

struct SessionDetailView: View {
    let session: Session
    @State private var selectedTab: DetailTab = .notes
    
    enum DetailTab: String, CaseIterable {
        case notes = "Meeting Notes"
        case recording = "Recording"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue)
                        .font(.body.weight(.medium))
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
            
            // Content based on selected tab
            switch selectedTab {
            case .notes:
                MeetingNotesView(session: session)
            case .recording:
                RecordingPlaybackView(session: session)
            }
        }
        .navigationTitle(session.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text(session.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MeetingNotesView: View {
    let session: Session
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Meeting Notes Content
                if let notes = session.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Meeting Notes")
                            .font(DesignTokens.Typography.title)
                            .foregroundColor(DesignTokens.Colors.text)
                        
                        Text(notes)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.text)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: 700)
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Action Items
                if !session.actions.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Action Items")
                            .font(DesignTokens.Typography.title)
                            .foregroundColor(DesignTokens.Colors.text)
                        
                        ForEach(session.actions) { action in
                            ActionItemRow(action: action)
                        }
                    }
                    .frame(maxWidth: 700)
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Transcript
                if let transcript = session.transcript, !transcript.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Transcript")
                            .font(DesignTokens.Typography.title)
                            .foregroundColor(DesignTokens.Colors.text)
                        
                        Text(transcript)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .textSelection(.enabled)
                    }
                    .padding()
                }
                
                // Empty state if no notes
                if (session.notes?.isEmpty ?? true) && session.actions.isEmpty && (session.transcript?.isEmpty ?? true) {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                        
                        Text("No meeting notes available")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
        }
        .background(DesignTokens.Colors.background)
    }
}

struct ActionItemRow: View {
    let action: ActionItem
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: action.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(action.status == .completed ? .green : .secondary)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(action.task)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.text)
                    .strikethrough(action.status == .completed)
                
                HStack(spacing: DesignTokens.Spacing.sm) {
                    if let assignee = action.assignee {
                        Label(assignee, systemImage: "person")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    if let deadline = action.deadline {
                        Label(deadline, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                if let sourceQuote = action.sourceQuote {
                    Text("\"\(sourceQuote)\"")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                        .italic()
                }
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surface)
        .cornerRadius(8)
    }
}

struct RecordingPlaybackView: View {
    let session: Session
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        Group {
            // First try audioPath, then fall back to notesPath
            if let audioPath = session.audioPath, FileManager.default.fileExists(atPath: audioPath.path) {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    Spacer()
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 64))
                        .foregroundColor(DesignTokens.Colors.accent)
                    
                    Text("Meeting Recording")
                        .font(DesignTokens.Typography.title)
                        .foregroundColor(DesignTokens.Colors.text)
                    
                    // Simple play/pause button
                    Button(action: {
                        if isPlaying {
                            player?.pause()
                        } else {
                            player?.play()
                        }
                        isPlaying.toggle()
                    }) {
                        HStack {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 40))
                            Text(isPlaying ? "Pause" : "Play")
                                .font(.headline)
                        }
                        .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Open in Finder") {
                        NSWorkspace.shared.selectFile(audioPath.path, inFileViewerRootedAtPath: "")
                    }
                    .buttonStyle(.bordered)
                    
                    Text(audioPath.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(DesignTokens.Spacing.xl)
                .onAppear {
                    player = AVPlayer(url: audioPath)
                }
                .onDisappear {
                    player?.pause()
                    player = nil
                }
            } else if let notesPath = session.notesPath, FileManager.default.fileExists(atPath: notesPath.path) {
                // Show meeting notes file location
                VStack(spacing: DesignTokens.Spacing.md) {
                    Spacer()
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 64))
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                    
                    Text("Meeting Notes File")
                        .font(DesignTokens.Typography.title)
                        .foregroundColor(DesignTokens.Colors.text)
                    
                    Text(notesPath.path)
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Button("Open in Finder") {
                        NSWorkspace.shared.selectFile(notesPath.path, inFileViewerRootedAtPath: "")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(DesignTokens.Spacing.xl)
            } else {
                VStack(spacing: DesignTokens.Spacing.md) {
                    Spacer()
                    
                    Image(systemName: "waveform.slash")
                        .font(.system(size: 64))
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                    
                    Text("Audio recording not available")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    if let audioPath = session.audioPath {
                        Text(audioPath.path)
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(DesignTokens.Spacing.xl)
            }
        }
        .background(DesignTokens.Colors.background)
    }
}
