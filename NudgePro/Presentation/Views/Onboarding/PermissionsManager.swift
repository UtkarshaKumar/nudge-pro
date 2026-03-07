import AVFoundation
import ScreenCaptureKit
import AppKit

/// Manages macOS permissions for screen recording and microphone access
@MainActor
final class PermissionsManager: ObservableObject {
    
    @Published private(set) var screenRecordingStatus: PermissionState = .notDetermined
    @Published private(set) var microphoneStatus: PermissionState = .notDetermined

    enum PermissionState {
        case notDetermined
        case denied
        case authorized

        var isAuthorized: Bool {
            self == .authorized
        }
    }
    
    // MARK: - Screen Recording
    
    /// Check if screen recording permission is granted
    /// Note: This will NOT trigger the permission prompt - it only checks current state
    func checkScreenRecordingPermission() async -> Bool {
        // First try the robust fall-back: can we see window titles from other apps?
        // If we can, screen recording is definitively granted.
        if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            let myPID = NSRunningApplication.current.processIdentifier
            var otherAppWindowsWithName = 0
            
            for window in windowList {
                if let pid = window[kCGWindowOwnerPID as String] as? Int32,
                   let name = window[kCGWindowName as String] as? String,
                   pid != myPID,
                   !name.isEmpty {
                    otherAppWindowsWithName += 1
                }
            }
            
            if otherAppWindowsWithName > 0 {
                screenRecordingStatus = .authorized
                print("✅ Screen recording permission: Authorized (via CGWindowList)")
                return true
            }
        }
        
        // ScreenCaptureKit is available on macOS 12.3+
        if #available(macOS 12.3, *) {
            do {
                _ = try await SCShareableContent.current
                screenRecordingStatus = .authorized
                print("✅ Screen recording permission: Authorized (via SCShareableContent)")
                return true
            } catch {
                screenRecordingStatus = .denied
                print("❌ Screen recording permission check failed: \(error.localizedDescription)")
                return false
            }
        } else {
            // Fallback for older macOS versions
            print("⚠️ ScreenCaptureKit not available on this macOS version")
            screenRecordingStatus = .denied
            return false
        }
    }
    
    /// Request screen recording permission
    /// This WILL trigger the system permission dialog on first attempt
    func requestScreenRecordingPermission() async -> Bool {
        if #available(macOS 12.3, *) {
            print("🖥️ Attempting to access screen content to trigger permission prompt...")
            do {
                _ = try await SCShareableContent.current
                screenRecordingStatus = .authorized
                print("✅ Screen recording permission granted")
                return true
            } catch {
                // SCShareableContent might throw a false negative TCC error in derived data builds
                // Fallback to checking the permission
                if await checkScreenRecordingPermission() {
                    return true
                }
                screenRecordingStatus = .denied
                print("❌ Screen recording permission denied: \(error.localizedDescription)")
                return false
            }
        }
        return false
    }
    
    /// Open System Preferences to Screen Recording settings
    func openScreenRecordingSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
        print("🔧 Opening Screen Recording settings")
    }
    
    // MARK: - Microphone
    
    /// Check microphone permission status
    func checkMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            microphoneStatus = .authorized
            print("✅ Microphone permission: Authorized")
            return true
        case .denied, .restricted:
            microphoneStatus = .denied
            print("❌ Microphone permission: Denied")
            return false
        case .notDetermined:
            microphoneStatus = .notDetermined
            print("⚠️ Microphone permission: Not determined")
            return false
        @unknown default:
            microphoneStatus = .denied
            return false
        }
    }
    
    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        
        if granted {
            microphoneStatus = .authorized
            print("✅ Microphone permission granted")
        } else {
            microphoneStatus = .denied
            print("❌ Microphone permission denied")
        }
        
        return granted
    }
    
    /// Open System Preferences to Microphone settings
    func openMicrophoneSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
        NSWorkspace.shared.open(url)
        print("🔧 Opening Microphone settings")
    }
    
    // MARK: - Combined Check
    
    /// Check all required permissions
    func checkAllPermissions() async -> (screenRecording: Bool, microphone: Bool) {
        async let screenCheck = checkScreenRecordingPermission()
        async let micCheck = checkMicrophonePermission()
        
        let results = await (screenCheck, micCheck)
        print("📋 Permission status - Screen: \(results.0), Microphone: \(results.1)")
        return results
    }
    
    /// Request all required permissions
    func requestAllPermissions() async -> (screenRecording: Bool, microphone: Bool) {
        async let screenRequest = requestScreenRecordingPermission()
        async let micRequest = requestMicrophonePermission()
        
        let results = await (screenRequest, micRequest)
        print("📋 Permissions requested - Screen: \(results.0), Microphone: \(results.1)")
        return results
    }
    
    /// Check if app has all required permissions
    func checkAllRequiredPermissions() async -> Bool {
        let results = await checkAllPermissions()
        return results.screenRecording && results.microphone
    }
    
    // MARK: - Synchronous Check
    
    /// Check permissions synchronously (basic check without prompts)
    func checkPermissionsSync() -> (canRecord: Bool, canRecordAudio: Bool, canRecordScreen: Bool, missingPermissions: [String]) {
        var missing: [String] = []
        
        // Check screen recording - try CGWindowList first (most reliable)
        var screenAuthorized = false
        if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            let myPID = NSRunningApplication.current.processIdentifier
            var otherAppWindowsWithName = 0
            for window in windowList {
                if let pid = window[kCGWindowOwnerPID as String] as? Int32,
                   let name = window[kCGWindowName as String] as? String,
                   pid != myPID,
                   !name.isEmpty {
                    otherAppWindowsWithName += 1
                }
            }
            screenAuthorized = otherAppWindowsWithName > 0
        }
        
        // Check microphone
        let micAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        
        let canRecord = screenAuthorized
        let canRecordAudio = micAuthorized
        let canRecordScreen = screenAuthorized
        
        if !screenAuthorized {
            missing.append("Screen Recording")
        }
        if !micAuthorized {
            missing.append("Microphone")
        }
        
        return (canRecord, canRecordAudio, canRecordScreen, missing)
    }
}
