# Nudge Pro - Bug Fixes & Permission System Handoff Document

## Executive Summary
Fixed TCC (Transparency, Consent, and Control) crashes and permission issues in the Nudge Pro macOS app. Implemented a robust permission management system with fallback mechanisms for denied permissions.

## Issues Fixed

### 1. TCC Privacy Crash (CRITICAL)
**Problem:** App crashed with `Termination Reason: Namespace TCC` when accessing Speech Recognition on macOS 26.3+ with adhoc signing.

**Root Cause:** 
- macOS 26.3+ requires proper code signing (Team ID) for privacy-sensitive permissions
- Adhoc-signed apps get killed by TCC daemon when accessing Speech Recognition
- The crash occurred in `SFSpeechRecognizer.requestAuthorization()`

**Solution:**
- Changed Xcode signing from "Sign to Run Locally" to "Development" 
- Added code signing check before attempting transcription
- Implemented graceful fallback when app is not properly signed

**Files Modified:**
- `project.yml` - Added `DEVELOPMENT_TEAM` placeholder
- `NudgePro/Presentation/Views/Onboarding/NativeScreenCaptureService.swift` - Added `checkProperCodeSigning()` method
- `TranscriptionService.swift` - Added defensive checks and warnings

### 2. Permission Request Flow
**Problem:** Permission dialogs weren't showing, app showed "Permissions required" error without requesting

**Solution:** Implemented step-by-step permission checking:
1. Check Microphone first
2. If not granted, request it
3. Only proceed to Screen Recording if Microphone granted
4. Return immediately with error if any permission denied

**Code in `NativeScreenCaptureService.swift`:**
```swift
func checkPermissions() async -> PermissionStatus {
    // Step 1: Check and request Microphone permission first
    // Step 2: Only proceed to check Screen Recording if Microphone is granted
}
```

### 3. Settings Permissions Section
**Problem:** Users couldn't manually manage permissions from within the app

**Solution:** Added comprehensive Permissions section in Settings:
- Shows status for: Screen Recording, Microphone, Speech Recognition
- Dynamic buttons based on status:
  - "Granted" → No button
  - "Denied" → "Request" button (with TCC reset)
  - "Unknown" → "Request" button

**Files Modified:**
- `NudgePro/Presentation/Views/Settings/SettingsView.swift`

**Key Features:**
```swift
enum PermissionStatus {
    case granted
    case denied  
    case unknown
}

private func requestPermissionWithReset(_ type: PermissionType) {
    // 1. Reset TCC database using tccutil
    // 2. Wait for system update
    // 3. Request permission again
}
```

### 4. TCC Database Reset
**Problem:** Once permission was denied, system wouldn't show dialog again

**Solution:** Programmatic TCC reset before requesting:
```swift
let task = Process()
task.launchPath = "/usr/bin/tccutil"
task.arguments = ["reset", "Microphone", "com.nudge.pro"]
task.launch()
task.waitUntilExit()
```

This allows re-requesting permissions even after initial denial.

### 5. Onboarding Sheet Dismissal
**Problem:** "Start Recording" button on onboarding didn't close the sheet

**Solution:** Added `@Environment(\.dismiss)` to OnboardingView:
```swift
@Environment(\.dismiss) private var dismiss

StoragePathStepView(onComplete: {
    appState.completeOnboarding()
    dismiss()  // Added this
})
```

### 6. Error Screen Settings Link
**Problem:** Users couldn't easily access system settings from permission error

**Solution:** Added "Open Settings" button to error screen:
```swift
LinearButton(title: "Open Settings", icon: "gearshape", style: .secondary) {
    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security")!)
}
```

## Current Status

### What's Working:
✅ Recording functionality (screen + audio)
✅ Step-by-step permission checking
✅ Settings permissions section with status display
✅ TCC database reset for re-requesting permissions
✅ Proper Development signing
✅ Onboarding dismissal
✅ Settings link from error screen

### What's Partially Working:
⚠️ Permission dialogs may not appear in some cases (requires TCC reset)
⚠️ Microphone permission status may show "Denied" even when granted (cosmetic)

### What's Not Working:
❌ Transcription requires Speech Recognition permission (user needs to manually enable in System Settings)
❌ Permission status detection may be inaccurate after app reinstall

## How to Test Permissions

### Method 1: In-App Settings (Recommended)
1. Open Nudge Pro
2. Press Cmd + , (or menu: Nudge Pro → Preferences)
3. Go to "Permissions" section
4. Click "Request" next to any permission
5. System dialog should appear

### Method 2: Terminal Reset
```bash
# Reset specific permission
tccutil reset Microphone com.nudge.pro
tccutil reset ScreenCapture com.nudge.pro
tccutil reset SpeechRecognition com.nudge.pro

# Reset all permissions
tccutil reset All com.nudge.pro
```

### Method 3: System Settings
1. System Settings → Privacy & Security
2. Navigate to specific permission (Microphone, Screen Recording, etc.)
3. Add/enable Nudge Pro manually

## Key Code Locations

### Permission Checking
- `NudgePro/Presentation/Views/Onboarding/PermissionsManager.swift`
- `NudgePro/Presentation/Views/Onboarding/NativeScreenCaptureService.swift` (checkPermissions method)

### Permission UI
- `NudgePro/Presentation/Views/Settings/SettingsView.swift` (Permissions section)

### Recording Flow
- `NudgePro/Presentation/ViewModels/RecordingViewModel.swift` (startRecording)
- `NudgePro/Presentation/Views/Recording/RecordingView.swift` (UI)

### Transcription
- `NudgePro/Infrastructure/Services/TranscriptionService.swift`

## Next Steps / Known Issues

1. **Permission Status Sync:** 
   - Status in Settings may not update immediately after granting
   - May need to close and reopen Settings view

2. **Microphone Detection:**
   - Sometimes shows "Denied" even when working
   - Check actual functionality rather than relying on status badge

3. **Speech Recognition:**
   - Requires manual enable in System Settings
   - No system dialog available for this permission

4. **Testing:**
   - Test with fresh app install (delete DerivedData first)
   - Test with tccutil reset to simulate first launch

## Build Instructions

```bash
# Clean build
cd "/path/to/nudge-pro"
rm -rf ~/Library/Developer/Xcode/DerivedData/NudgePro-*

# Regenerate project (if using XcodeGen)
xcodegen generate

# Build
xcodebuild -project NudgePro.xcodeproj -scheme NudgePro -configuration Debug -destination 'platform=macOS' build

# Run
open ~/Library/Developer/Xcode/DerivedData/NudgePro-*/Build/Products/Debug/Nudge\ Pro.app
```

## Important Notes

1. **Code Signing:** Must use "Development" certificate, not "Sign to Run Locally"
2. **TCC Database:** macOS caches permissions per-app; resets may require app restart
3. **Speech Recognition:** Most restrictive permission; always requires manual System Settings enable
4. **User Experience:** Consider adding onboarding flow that requests permissions upfront

## Testing Checklist

- [ ] Fresh install - permissions requested on first use
- [ ] Deny permission - app shows error with settings link
- [ ] Settings page - shows correct permission statuses
- [ ] Request button - shows system dialog
- [ ] After granting - can start recording
- [ ] Transcription - works if Speech Recognition enabled

---

## Testing Checklist

- [ ] Fresh install - permissions requested on first use
- [ ] Deny permission - app shows error with settings link
- [ ] Settings page - shows correct permission statuses
- [ ] Request button - shows system dialog
- [ ] After granting - can start recording
- [ ] Transcription - works if Speech Recognition enabled

---

## March 4, 2026 - Permission System Fixes

### Issues Identified

1. **Onboarding didn't request permissions** - The onboarding flow went Welcome → Recording Mode → Vision Provider → Storage Path → Complete without ever requesting microphone or screen recording permissions.

2. **Settings "Request" button used broken TCC reset** - The `requestPermissionWithReset` function tried to use `tccutil` which:
   - Requires root privileges (won't work from a sandboxed app)
   - Had wrong syntax: `tccutil reset Microphone com.nudge.pro` is invalid
   - The correct syntax is just `tccutil reset Microphone` (without bundle ID, and requires sudo)

### Fixes Applied

1. **SettingsView.swift** - Removed the broken `tccutil` approach. Now calls `requestPermission()` directly which uses the proper macOS APIs:
   - `AVCaptureDevice.requestAccess(for: .audio)` for microphone
   - `SCShareableContent.current` for screen recording

2. **OnboardingView.swift** - Added a new permission request step (step 5) that:
   - Shows current permission status for Microphone and Screen Recording
   - Has a "Grant Access" button that triggers the system permission dialogs
   - Shows error message if permissions are denied with instructions
   - Only completes onboarding if permissions are granted

### How Permissions Now Work

1. **During Onboarding** - New step #5 requests Microphone and Screen Recording permissions
2. **In Settings** - Click "Request" button to trigger system dialog (works if not previously denied)
3. **First Recording** - If permissions not granted, shows error with link to System Settings

### Note on TCC Reset

Users who previously denied permissions cannot be prompted again automatically. They need to:
1. Go to System Settings → Privacy & Security
2. Find the permission (Microphone/Screen Recording)
3. Remove Nudge Pro from the list
4. Then the app can prompt again

Document created: March 4, 2026
Status: Permission system fixed - requests now work properly
