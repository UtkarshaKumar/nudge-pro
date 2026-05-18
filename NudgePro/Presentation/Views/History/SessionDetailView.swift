import SwiftUI

struct SessionDetailView: View {
    let session: Session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                headerSection

                if session.notes != nil || !session.actions.isEmpty || session.transcript != nil {
                    contentSection
                } else {
                    emptyContentSection
                }
            }
            .padding(Spacing.xl)
        }
        .background(Color.background)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(session.title)
                .font(.screenTitle)
                .foregroundColor(.textPrimary)

            HStack(spacing: Spacing.md) {
                Label(session.formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Label(session.formattedDuration, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                sessionStatusBadge
            }
        }
    }

    private var sessionStatusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: session.status.icon)
            Text(session.status.rawValue.capitalized)
        }
        .font(.caption)
        .foregroundColor(session.status.color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 4)
        .background(session.status.color.opacity(0.15))
        .cornerRadius(CornerRadius.input)
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            notesSection

            actionItemsSection

            transcriptSection

            detailsSection
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesSection: some View {
        if let notes = session.notes, !notes.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                sectionHeader(icon: "doc.text.fill", title: "Meeting Notes")

                Text(notes)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.card)
            }
        }
    }

    // MARK: - Action Items

    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(
                icon: "checklist",
                title: "Action Items",
                badge: "\(session.actions.count)"
            )

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
    }

    // MARK: - Transcript

    @ViewBuilder
    private var transcriptSection: some View {
        if let transcript = session.transcript, !transcript.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                sectionHeader(
                    icon: "text.quote",
                    title: "Transcript",
                    badge: "\(transcript.split(separator: " ").count) words"
                )

                ScrollView {
                    Text(transcript)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 300)
                .padding(Spacing.md)
                .background(Color.surface)
                .cornerRadius(CornerRadius.card)
            }
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(icon: "info.circle", title: "Recording Details")

            VStack(alignment: .leading, spacing: Spacing.sm) {
                DetailRow(label: "Mode", value: session.recordingMode.displayName)
                DetailRow(label: "Status", value: session.status.rawValue.capitalized)
                DetailRow(label: "Storage", value: session.storagePath)

                if let monitor = session.monitor {
                    DetailRow(label: "Display", value: "\(monitor.name) (\(monitor.resolution))")
                }

                if !session.participants.isEmpty {
                    DetailRow(label: "Participants", value: session.participants.joined(separator: ", "))
                }
            }
            .padding(Spacing.md)
            .background(Color.surface)
            .cornerRadius(CornerRadius.card)
        }
    }

    // MARK: - Empty State

    private var emptyContentSection: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)

            Text("This session is still processing")
                .font(.sectionHeader)
                .foregroundColor(.textSecondary)

            Text("Meeting notes and action items will appear here once processing is complete.")
                .font(.body)
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String, badge: String? = nil) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentPrimary)
            Text(title)
                .font(.sectionHeader)
                .foregroundColor(.textPrimary)

            if let badge = badge {
                Spacer()
                Text(badge)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.input)
            }
        }
    }
}
