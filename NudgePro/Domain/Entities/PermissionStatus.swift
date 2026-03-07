import Foundation

/// Represents the current state of required permissions
struct PermissionStatus {
    let canRecordAudio: Bool
    let canRecordScreen: Bool
    let missingPermissions: [String]

    var canRecord: Bool {
        canRecordAudio && canRecordScreen
    }
}
