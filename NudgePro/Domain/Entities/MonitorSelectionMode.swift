import Foundation

enum MonitorSelectionMode: String, CaseIterable {
    case automatic
    case ask
    case specific

    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .ask: return "Ask Each Time"
        case .specific: return "Specific Monitor"
        }
    }
}
