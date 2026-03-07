import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @State private var showingNotes = false
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            
            // Recording indicator
            RecordingIndicator(state: viewModel.recordingState)
            
            // Session title
            if let session = viewModel.currentSession {
                Text(session.title)
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)
            }
            
            // Timer
            Text(viewModel.elapsedTime.formattedTime)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(.textSecondary)
            
            // Error message
            if case .error(let message) = viewModel.recordingState {
                Text(message)
                    .font(.body)
                    .foregroundColor(.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            // Controls
            RecordingControls(
                state: viewModel.recordingState,
                hasMultipleDisplays: false,
                onStart: {
                    // Audio-only mode - no display selection needed
                    viewModel.startRecording(mode: .audioOnly)
                },
                onStop: {
                    viewModel.stopRecording()
                },
                onViewNotes: {
                    showingNotes = true
                },
                onReset: {
                    viewModel.reset()
                }
            )
            
            Spacer()
            
            // Status bar
            StatusBar(session: viewModel.currentSession, state: viewModel.recordingState)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        .sheet(isPresented: $showingNotes) {
            if let session = viewModel.currentSession {
                NotesView(session: session)
            }
        }
    }
}

struct RecordingIndicator: View {
    let state: RecordingState
    
    var body: some View {
        ZStack {
            Circle()
                .fill(state == .recording ? Color.recording.opacity(0.2) : Color.surface)
                .frame(width: 120, height: 120)
            
            Circle()
                .stroke(
                    state == .recording ? Color.recording : Color.border,
                    lineWidth: 3
                )
                .frame(width: 100, height: 100)
            
            if state == .recording {
                Circle()
                    .fill(Color.recording)
                    .frame(width: 16, height: 16)
                    .modifier(PulseModifier())
            } else {
                Image(systemName: "mic.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct RecordingControls: View {
    let state: RecordingState
    let hasMultipleDisplays: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onViewNotes: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        Group {
            switch state {
            case .idle:
                LinearButton(title: "Start Recording", icon: "record.circle", style: .primary) {
                    onStart()
                }
            case .recording:
                LinearButton(title: "Stop Recording", icon: "stop.fill", style: .destructive) {
                    onStop()
                }
            case .processing:
                HStack(spacing: Spacing.md) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                    Text("Processing...")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
            case .completed:
                VStack(spacing: Spacing.md) {
                    LinearButton(title: "View Notes", icon: "doc.text", style: .primary) {
                        onViewNotes()
                    }
                    
                    LinearButton(title: "New Recording", icon: "plus.circle", style: .secondary) {
                        onReset()
                    }
                }
            case .error:
                VStack(spacing: Spacing.md) {
                    LinearButton(title: "Try Again", icon: "arrow.clockwise", style: .primary) {
                        onReset()
                        onStart()
                    }
                    
                    LinearButton(title: "Open Settings", icon: "gearshape", style: .secondary) {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security")!)
                    }
                    
                    LinearButton(title: "Cancel", style: .ghost) {
                        onReset()
                    }
                }
            }
        }
    }
}

struct StatusBar: View {
    let session: Session?
    let state: RecordingState
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            if let session = session {
                // Recording status
                HStack(spacing: Spacing.xs) {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                
                Divider()
                    .frame(height: 12)
                
                // Storage path
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.textTertiary)
                    Text(session.storagePath)
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                        .lineLimit(1)
                }
            } else {
                Text("Ready to record")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.surface)
    }
    
    private var statusIcon: String {
        switch state {
        case .idle:
            return "mic.slash"
        case .recording:
            return "mic.fill"
        case .processing:
            return "gear"
        case .completed:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .idle:
            return .textTertiary
        case .recording:
            return .recording
        case .processing:
            return .warning
        case .completed:
            return .success
        case .error:
            return .error
        }
    }
    
    private var statusText: String {
        switch state {
        case .idle:
            return "Not recording"
        case .recording:
            return "Recording in progress"
        case .processing:
            return "Processing recording"
        case .completed:
            return "Recording completed"
        case .error:
            return "Recording failed"
        }
    }
}

// MARK: - Notes View

struct NotesView: View {
    let session: Session
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(session.title)
                        .font(.screenTitle)
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: Spacing.md) {
                        Label(session.duration.formattedTime, systemImage: "clock")
                        Label(session.startedAt.formatted(.dateTime), systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentPrimary)
            }
            .padding(Spacing.lg)
            .background(Color.surface)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Action Items Section
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "checklist")
                                .foregroundColor(.accentPrimary)
                            Text("Action Items")
                                .font(.sectionHeader)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Text("\(session.actions.count)")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 4)
                                .background(Color.surface)
                                .cornerRadius(CornerRadius.input)
                        }
                        
                        if session.actions.isEmpty {
                            Text("No action items extracted")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .padding(Spacing.lg)
                                .frame(maxWidth: .infinity)
                                .background(Color.surface)
                                .cornerRadius(CornerRadius.card)
                        } else {
                            VStack(spacing: Spacing.md) {
                                ForEach(session.actions) { action in
                                    ActionItemCard(action: action)
                                }
                            }
                        }
                    }
                    
                    // Transcript Section (if available)
                    if let transcript = session.transcript, !transcript.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Image(systemName: "text.quote")
                                    .foregroundColor(.accentPrimary)
                                Text("Transcript")
                                    .font(.sectionHeader)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                Text("\(transcript.split(separator: " ").count) words")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, 4)
                                    .background(Color.surface)
                                    .cornerRadius(CornerRadius.input)
                            }
                            
                            ScrollView {
                                Text(transcript)
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 200)
                            .padding(Spacing.md)
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.card)
                        }
                    }
                    
                    // Recording Details
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentPrimary)
                            Text("Recording Details")
                                .font(.sectionHeader)
                                .foregroundColor(.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            DetailRow(label: "Mode", value: session.recordingMode.displayName)
                            DetailRow(label: "Status", value: session.status.rawValue.capitalized)
                            DetailRow(label: "Storage", value: session.storagePath)
                            
                            if let monitor = session.monitor {
                                DetailRow(label: "Display", value: "\(monitor.name) (\(monitor.resolution))")
                            }
                        }
                        .padding(Spacing.md)
                        .background(Color.surface)
                        .cornerRadius(CornerRadius.card)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.background)
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

struct ActionItemCard: View {
    let action: ActionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Task
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: action.status.icon)
                    .foregroundColor(.accentPrimary)
                    .frame(width: 20)
                
                Text(action.task)
                    .font(.body)
                    .foregroundColor(.textPrimary)
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let assignee = action.assignee {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                        Text(assignee)
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                }
                
                if let deadline = action.deadline {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(deadline)
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                }
                
                if let context = action.context {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10))
                        Text(context)
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                }
            }
            .padding(.leading, 28)
            
            // Confidence
            HStack {
                Text("Confidence:")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                
                ProgressView(value: action.confidence)
                    .progressViewStyle(.linear)
                    .tint(.accentPrimary)
                    .frame(width: 80)
                
                Text("\(Int(action.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.leading, 28)
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.card)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.textTertiary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.body)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Display Picker View

struct DisplayPickerView: View {
    let displays: [Monitor]
    @Binding var selectedDisplay: Monitor?
    let onStart: (RecordingMode) -> Void
    let onCancel: () -> Void
    
    @State private var selectedMode: RecordingMode = .screenAndAudio
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            VStack(spacing: Spacing.sm) {
                Image(systemName: "display.2")
                    .font(.system(size: 48))
                    .foregroundColor(.accentPrimary)
                
                Text("Select Display to Record")
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)
                
                Text("Choose which monitor you want to capture")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, Spacing.xl)
            
            // Display list
            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(displays) { display in
                        DisplayRow(
                            display: display,
                            isSelected: selectedDisplay?.id == display.id,
                            onSelect: {
                                selectedDisplay = display
                            }
                        )
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            
            // Recording mode picker
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Recording Mode")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                Picker("Mode", selection: $selectedMode) {
                    Text("Audio Only").tag(RecordingMode.audioOnly)
                    Text("Screen + Audio").tag(RecordingMode.screenAndAudio)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, Spacing.lg)
            
            // Actions
            HStack(spacing: Spacing.md) {
                LinearButton(title: "Cancel", style: .ghost) {
                    onCancel()
                }
                
                Spacer()
                
                LinearButton(
                    title: "Start Recording",
                    icon: "record.circle",
                    style: .primary
                ) {
                    onStart(selectedMode)
                }
                .disabled(selectedDisplay == nil)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .frame(width: 500, height: 600)
        .background(Color.background)
    }
}

struct DisplayRow: View {
    let display: Monitor
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Display icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.surface)
                        .frame(width: 60, height: 40)
                    
                    Image(systemName: display.isPrimary ? "display" : "display.2")
                        .font(.system(size: 24))
                        .foregroundColor(.textSecondary)
                }
                
                // Display info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(display.name)
                            .font(.body)
                            .foregroundColor(.textPrimary)
                        
                        if display.isPrimary {
                            Text("Primary")
                                .font(.caption)
                                .foregroundColor(.accentPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentPrimary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(display.resolution)
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentPrimary)
                        .font(.system(size: 24))
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

#Preview {
    RecordingView()
}
