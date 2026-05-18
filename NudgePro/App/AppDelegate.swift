import AppKit
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    
    // Meeting apps to monitor (exact bundle IDs)
    private let meetingApps: [String: String] = [
        "us.zoom.xos": "Zoom",
        "com.microsoft.teams": "Microsoft Teams",
        "com.google.Chrome": "Google Meet (Chrome)",
        "com.apple.Safari": "Safari"
    ]
    
    override init() {
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("DEBUG: App launched successfully")
        
        // Setup menu bar
        setupMenuBar()
        
        // Run cleanup of old sessions based on retention settings
        DispatchQueue.global(qos: .background).async {
            SessionStore.shared.cleanupOldSessions()
        }
        
        // Start monitoring for meeting app launches
        startMeetingAppMonitor()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup code
    }
    
    // MARK: - Menu Bar
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "record.circle", accessibilityDescription: "Nudge Pro")
            button.action = #selector(menuBarClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        statusMenu = NSMenu()
        statusMenu?.addItem(NSMenuItem(title: "Nudge Pro", action: nil, keyEquivalent: ""))
        statusMenu?.addItem(NSMenuItem.separator())
        statusMenu?.addItem(NSMenuItem.separator())
        
        let recordItem = NSMenuItem(title: "Start Recording", action: #selector(startRecording), keyEquivalent: "r")
        recordItem.keyEquivalentModifierMask = [.command, .shift]
        statusMenu?.addItem(recordItem)
        
        let stopItem = NSMenuItem(title: "Stop Recording", action: #selector(stopRecording), keyEquivalent: "s")
        stopItem.keyEquivalentModifierMask = [.command, .shift]
        statusMenu?.addItem(stopItem)
        
        statusMenu?.addItem(NSMenuItem.separator())
        
        let openItem = NSMenuItem(title: "Open Nudge Pro", action: #selector(openMainApp), keyEquivalent: "o")
        openItem.keyEquivalentModifierMask = [.command]
        statusMenu?.addItem(openItem)
        
        statusMenu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        statusMenu?.addItem(quitItem)
        
        statusItem?.menu = statusMenu
    }
    
    @objc private func menuBarClicked() {
        statusItem?.menu = statusMenu
        statusItem?.button?.performClick(nil)
    }
    
    @objc private func startRecording() {
        print("Menu bar: Start recording")
        // This would trigger the main app's recording functionality
        openMainApp()
    }
    
    @objc private func stopRecording() {
        print("Menu bar: Stop recording")
    }
    
    @objc private func openMainApp() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Meeting App Monitor
    
    private func startMeetingAppMonitor() {
        // Monitor for running applications
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidLaunch),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }
        
        // Check if it's a meeting app (exact match)
        if let name = meetingApps[bundleId] {
            print("Meeting app detected: \(name)")
            showMeetingAppAlert(appName: name)
        }
    }
    
    private func showMeetingAppAlert(appName: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = NSAlert()
            alert.messageText = "Start Recording?"
            alert.informativeText = "Would you like to start recording your \(appName) meeting?"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Start Recording")
            alert.addButton(withTitle: "Not Now")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self?.openMainApp()
            }
        }
    }
}
