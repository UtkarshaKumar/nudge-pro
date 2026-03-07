import AppKit
import UniformTypeIdentifiers

class ExportService {
    enum ExportFormat: String, CaseIterable {
        case markdown
        case plainText
        case json
    }

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func saveToFile(session: Session, format: ExportFormat) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(session.title).\(format == .json ? "json" : "md")"

        if panel.runModal() == .OK, let url = panel.url {
            let content = formatSession(session, format: format)
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func formatSession(_ session: Session, format: ExportFormat) -> String {
        switch format {
        case .markdown:
            return session.notes ?? session.transcript ?? session.title
        case .plainText:
            return session.notes ?? session.transcript ?? session.title
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(session), let str = String(data: data, encoding: .utf8) {
                return str
            }
            return "{}"
        }
    }
}
