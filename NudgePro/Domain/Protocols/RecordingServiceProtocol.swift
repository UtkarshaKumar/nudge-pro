import Foundation

/// Protocol defining recording service capabilities
protocol RecordingServiceProtocol {
    func startRecording(mode: RecordingMode, monitor: Monitor?) async throws -> Session
    func stopRecording() async throws -> Session
    func getAvailableMonitors() async -> [Monitor]
    func checkPermissions() async -> PermissionStatus
}
