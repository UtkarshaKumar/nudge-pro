import ScreenCaptureKit
import Foundation
import CoreGraphics

/// Manages display detection and selection using ScreenCaptureKit
@available(macOS 12.3, *)
@MainActor
final class DisplayManager {
    
    /// Represents a display/monitor
    struct Display: Identifiable, Hashable {
        let id: String
        let displayID: CGDirectDisplayID
        let name: String
        let width: Int
        let height: Int
        let isPrimary: Bool
        
        var resolution: String {
            "\(width) × \(height)"
        }
        
        var displayName: String {
            if isPrimary {
                return "\(name) (Primary)"
            }
            return name
        }
        
        /// Convert to Monitor model for compatibility
        func toMonitor() -> Monitor {
            Monitor(
                id: id,
                name: name,
                width: width,
                height: height,
                isPrimary: isPrimary,
                displayID: UInt32(displayID)
            )
        }
    }
    
    // MARK: - Display Discovery
    
    /// Get all available displays
    func getDisplays() async throws -> [Display] {
        let content = try await SCShareableContent.current
        
        var displays: [Display] = []
        
        for scDisplay in content.displays {
            let display = Display(
                id: "\(scDisplay.displayID)",
                displayID: scDisplay.displayID,
                name: getDisplayName(for: scDisplay),
                width: scDisplay.width,
                height: scDisplay.height,
                isPrimary: CGDisplayIsMain(scDisplay.displayID) != 0
            )
            displays.append(display)
        }
        
        // Sort: primary first, then by size
        displays.sort { display1, display2 in
            if display1.isPrimary != display2.isPrimary {
                return display1.isPrimary
            }
            return (display1.width * display1.height) > (display2.width * display2.height)
        }
        
        print("🖥️ Found \(displays.count) displays")
        for display in displays {
            print("  - \(display.displayName): \(display.resolution)")
        }
        
        return displays
    }
    
    /// Get primary display
    func getPrimaryDisplay() async throws -> Display? {
        let displays = try await getDisplays()
        return displays.first { $0.isPrimary }
    }
    
    /// Get display by ID
    func getDisplay(byID displayID: String) async throws -> Display? {
        let displays = try await getDisplays()
        return displays.first { $0.id == displayID }
    }
    
    // MARK: - Display Info
    
    private func getDisplayName(for display: SCDisplay) -> String {
        let displayID = display.displayID
        let width = display.width
        let height = display.height
        
        // Check if it's a built-in display
        if CGDisplayIsBuiltin(displayID) != 0 {
            return "MacBook Display (\(width)×\(height))"
        }
        
        // For external displays, include resolution
        if CGDisplayIsMain(displayID) != 0 {
            return "Primary Display (\(width)×\(height))"
        } else {
            return "External Display (\(width)×\(height))"
        }
    }
    
    /// Get thumbnail image of a display
    func getThumbnail(for display: Display, size: CGSize = CGSize(width: 320, height: 180)) async throws -> CGImage? {
        let content = try await SCShareableContent.current
        
        guard let scDisplay = content.displays.first(where: { $0.displayID == display.displayID }) else {
            return nil
        }
        
        let filter = SCContentFilter(display: scDisplay, excludingWindows: [])
        
        let config = SCStreamConfiguration()
        config.width = Int(size.width)
        config.height = Int(size.height)
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        config.queueDepth = 3
        
        if #available(macOS 14.0, *) {
            do {
                let image = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: config
                )
                print("📸 Captured thumbnail for \(display.name)")
                return image
            } catch {
                print("❌ Failed to capture thumbnail: \(error.localizedDescription)")
                return nil
            }
        } else {
            // SCScreenshotManager is only available on macOS 14+
            print("⚠️ Thumbnail capture requires macOS 14+. Returning nil thumbnail.")
            return nil
        }
    }
}

