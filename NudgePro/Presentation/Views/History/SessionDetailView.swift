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
            // Centered Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue)
                        .font(.body.weight(.medium))
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 280)
            .padding(.vertical, 16)
            
            Divider()
            
            // Content based on selected tab
            switch selectedTab {
            case .notes:
                MeetingNotesView(session: session)
            case .recording:
                RecordingPlaybackView(session: session)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            VStack(alignment: .leading, spacing: 28) {
                // Meeting Notes Section
                if let notes = session.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        FormattedMeetingNotes(notes: notes)
                    }
                    .frame(maxWidth: 680, alignment: .leading)
                }
                
                // Action Items Section
                if !session.actions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Action Items")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.text)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(session.actions) { action in
                                ActionItemRow(action: action)
                            }
                        }
                    }
                    .frame(maxWidth: 680, alignment: .leading)
                }
                
                // Transcript Section
                if let transcript = session.transcript, !transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Full Transcript")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.text)
                        
                        Text(transcript)
                            .font(.system(size: 15))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineSpacing(6)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: 680, alignment: .leading)
                }
                
                // Empty state
                if (session.notes?.isEmpty ?? true) && session.actions.isEmpty && (session.transcript?.isEmpty ?? true) {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                        
                        Text("No meeting notes available")
                            .font(.system(size: 16))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 80)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.Colors.background)
    }
}

// Formatted meeting notes view with better hierarchy
struct FormattedMeetingNotes: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Parse and display notes with formatting
            let lines = notes.components(separatedBy: .newlines)
            
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if !line.isEmpty {
                    FormattedLine(line: line)
                }
            }
        }
        .textSelection(.enabled)
    }
}

struct FormattedLine: View {
    let line: String
    
    var body: some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasPrefix("# ") {
            // H1
            Text(trimmed.dropFirst(2))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(DesignTokens.Colors.text)
        } else if trimmed.hasPrefix("## ") {
            // H2
            Text(trimmed.dropFirst(3))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.text)
                .padding(.top, 8)
        } else if trimmed.hasPrefix("### ") {
            // H3
            Text(trimmed.dropFirst(4))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.text)
                .padding(.top, 4)
        } else if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") {
            // Bullet point
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 15))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                Text(trimmed.dropFirst(2))
                    .font(.system(size: 15))
                    .foregroundColor(DesignTokens.Colors.text)
                    .lineSpacing(4)
            }
        } else if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") {
            // Bold text
            let start = trimmed.index(trimmed.startIndex, offsetBy: 2)
            let end = trimmed.index(trimmed.endIndex, offsetBy: -2)
            Text(String(trimmed[start..<end]))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.text)
        } else {
            // Regular text
            Text(trimmed)
                .font(.system(size: 15))
                .foregroundColor(DesignTokens.Colors.text)
                .lineSpacing(4)
        }
    }
}

struct ActionItemRow: View {
    let action: ActionItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: action.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(action.status == .completed ? Color.green : Color.gray.opacity(0.4))
                .font(.system(size: 20))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(action.task)
                    .font(.system(size: 15))
                    .foregroundColor(action.status == .completed ? DesignTokens.Colors.textSecondary : DesignTokens.Colors.text)
                    .strikethrough(action.status == .completed)
                
                HStack(spacing: 16) {
                    if let assignee = action.assignee {
                        Label(assignee, systemImage: "person")
                            .font(.system(size: 13))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    if let deadline = action.deadline {
                        Label(deadline, systemImage: "calendar")
                            .font(.system(size: 13))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                if let sourceQuote = action.sourceQuote {
                    Text("\"\(sourceQuote)\"")
                        .font(.system(size: 13))
                        .italic()
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct RecordingPlaybackView: View {
    let session: Session
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        Group {
            if let audioPath = session.audioPath, FileManager.default.fileExists(atPath: audioPath.path) {
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Waveform visualization
                    WaveformView()
                        .frame(height: 80)
                    
                    Text("Meeting Recording")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.text)
                    
                    // Play button
                    Button(action: {
                        if isPlaying {
                            player?.pause()
                        } else {
                            player?.play()
                        }
                        isPlaying.toggle()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20))
                            Text(isPlaying ? "Pause" : "Play")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(width: 140, height: 48)
                        .background(DesignTokens.Colors.accent)
                        .cornerRadius(24)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button("Open in Finder") {
                        NSWorkspace.shared.selectFile(audioPath.path, inFileViewerRootedAtPath: "")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(DesignTokens.Colors.accent)
                    
                    Text(audioPath.lastPathComponent)
                        .font(.system(size: 12))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 40)
                .onAppear {
                    player = AVPlayer(url: audioPath)
                }
                .onDisappear {
                    player?.pause()
                    player = nil
                }
            } else if let notesPath = session.notesPath, FileManager.default.fileExists(atPath: notesPath.path) {
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 64))
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                    
                    Text("Meeting Notes File")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.text)
                    
                    Text(notesPath.path)
                        .font(.system(size: 13))
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
                .padding(40)
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "waveform.slash")
                        .font(.system(size: 64))
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                    
                    Text("Audio recording not available")
                        .font(.system(size: 17))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    if let audioPath = session.audioPath {
                        Text(audioPath.path)
                            .font(.system(size: 12))
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            }
        }
        .background(DesignTokens.Colors.background)
    }
}

// Simple animated waveform view
struct WaveformView: View {
    @State private var phase = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<30) { index in
                WaveformBar(index: index, phase: phase)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct WaveformBar: View {
    let index: Int
    let phase: Double
    
    var body: some View {
        let height = 20 + 40 * abs(sin(phase + Double(index) * 0.3))
        
        RoundedRectangle(cornerRadius: 2)
            .fill(DesignTokens.Colors.accent.opacity(0.6))
            .frame(width: 4, height: height)
    }
}
