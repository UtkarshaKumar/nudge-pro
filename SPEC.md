# Nudge Pro - Specification Document

## 1. Project Overview

### Project Name
**Nudge Pro** - Privacy-First Meeting Recorder

### Project Type
macOS Desktop Application with dual distribution (App Store + Direct DMG)

### Core Feature Summary
A privacy-first meeting recording application that captures audio and screen content, processes it with local or cloud-based AI to extract action items, summaries, and slides - all at a fraction of Loom's subscription cost.

### Target Users
- **Individual Professionals**: Remote workers, freelancers, consultants
- **Teams**: Small to medium businesses wanting meeting documentation
- **Enterprises**: Teams requiring privacy-focused recording solutions

### Distribution
- **Mac App Store**: Sandboxed version with limited features
- **Direct Download (DMG)**: Full-featured version for power users
- **Price**: $49 one-time purchase

---

## 2. UI/UX Specification

### Design Philosophy
**Linear-Style Minimalist Design**
- Dark theme with high contrast
- Minimal visual noise
- Subtle gradient accents
- Clean typography
- Smooth micro-interactions

### Color Palette

| Role | Color | Hex Code |
|------|-------|----------|
| Background Primary | Deep Black | `#0D0D0F` |
| Background Secondary | Dark Gray | `#18181B` |
| Surface | Elevated Surface | `#1C1C1F` |
| Border | Subtle Border | `#27272A` |
| Border Hover | Border Hover | `#3F3F46` |
| Text Primary | White | `#FAFAFA` |
| Text Secondary | Muted Gray | `#A1A1AA` |
| Text Tertiary | Dim Gray | `#71717A` |
| Accent Primary | Purple | `#8B5CF6` |
| Accent Secondary | Indigo | `#6366F1` |
| Accent Gradient Start | Purple | `#8B5CF6` |
| Accent Gradient End | Indigo | `#6366F1` |
| Success | Green | `#22C55E` |
| Warning | Amber | `#F59E0B` |
| Error | Red | `#EF4444` |
| Recording Active | Red | `#F43F5E` |

### Typography

| Element | Font | Size | Weight |
|---------|------|------|--------|
| App Title | Inter | 28pt | Bold (700) |
| Screen Title | Inter | 24pt | Semibold (600) |
| Section Header | Inter | 18pt | Semibold (600) |
| Body | Inter | 14pt | Regular (400) |
| Body Small | Inter | 12pt | Regular (400) |
| Caption | Inter | 11pt | Regular (400) |
| Button | Inter | 14pt | Medium (500) |
| Code/Mono | JetBrains Mono | 12pt | Regular (400) |

### Spacing System (8pt Grid)

| Token | Value |
|-------|-------|
| xs | 4pt |
| sm | 8pt |
| md | 16pt |
| lg | 24pt |
| xl | 32pt |
| xxl | 48pt |

### Corner Radius

| Element | Radius |
|---------|--------|
| Buttons | 8pt |
| Cards | 12pt |
| Modals | 16pt |
| Input Fields | 6pt |

### Window Specifications

#### Main Window
- **Size**: 600pt width × 500pt height (minimum)
- **Style**: Borderless with custom title bar
- **Title Bar Height**: 40pt
- **Resize**: Enabled with minimum constraints

#### Settings Window
- **Size**: 500pt width × 600pt height
- **Style**: Modal sheet

#### Onboarding Window
- **Size**: 550pt width × 450pt height
- **Style**: Centered modal

---

## 3. Screen Specifications

### 3.1 Onboarding Flow

#### Screen 1: Welcome
- App logo (gradient sphere icon)
- App name: "nudge"
- Tagline: "Your intelligent meeting scribe"
- "Get Started" button

#### Screen 2: Recording Mode Selection
**Question**: "How do you want to record?"

| Option | Icon | Description |
|--------|------|-------------|
| Audio-only | 🎤 | Capture meeting audio only. Faster processing, uses less storage. |
| Screen + Audio | 📺 | Record your screen with audio. Full meeting capture with visual content. |

#### Screen 3: Vision Provider (only if Screen+Audio selected)
**Question**: "How should we process visual content?"

| Option | Icon | Description |
|--------|------|-------------|
| Local (Ollama) | 🖥️ | Free, runs on your Mac. Requires ~8GB RAM. Slower processing. |
| OpenAI API | ☁️ | Faster, better results. Provide your own API key (~10$/month). |

#### Screen 4: Monitor Selection (only if Screen+Audio selected)
**Question**: "Which screen should we record by default?"

| Option | Description |
|--------|-------------|
| Ask each time | Prompt me to select a screen every time I start recording. |
| [Monitor 1] | Built-in Retina Display |
| [Monitor 2] | External Monitor - 27" |
| ... | Additional detected monitors |

#### Screen 5: Storage Location
**Question**: "Where should we save your recordings?"

- Default: `~/Documents/Meeting Notes`
- "Choose..." button to select custom path
- Display available disk space

#### Screen 6: Completion
- Success checkmark animation
- "Start Recording" button

---

### 3.2 Main Recording View

#### Layout
```
┌─────────────────────────────────────────────────────┐
│ ○  nudge                           ─  □  ✕         │  <- Custom title bar
├─────────────────────────────────────────────────────┤
│                                                     │
│                                                     │
│                   ┌─────────┐                      │
│                   │    ●    │                      │  <- Recording indicator
│                   │   REC   │                      │
│                   └─────────┘                      │
│                                                     │
│               Meeting Title                        │
│               00:05:23                             │
│                                                     │
│            [ ⏹ Stop Recording ]                   │
│                                                     │
│                                                     │
├─────────────────────────────────────────────────────┤
│  📺 Screen: Built-in Retina Display               │
│  🎤 Audio: BlackHole 2ch                          │
│  💾 Recording to: ~/Documents/Meeting Notes       │
└─────────────────────────────────────────────────────┘
```

#### States
| State | Visual |
|-------|--------|
| Idle | "Start Recording" button visible |
| Recording | Red recording indicator, timer counting, "Stop" button |
| Processing | Progress indicator with step labels |
| Complete | Success message with "Open Notes" button |

---

### 3.3 Settings View

#### Sections

**Recording**
- Recording Mode: [Dropdown: Audio-only | Screen + Audio]
- Vision Provider: [Dropdown: Local | OpenAI]
- Default Monitor: [Dropdown: monitors]
- Ask for screen: [Toggle: Yes/No]

**Audio**
- Input Device: [Dropdown: available audio devices]
- Sample Rate: [Dropdown: 44100 | 48000]

**Storage**
- Save Location: [Path display + Change button]
- Auto-cleanup: [Dropdown: Never | 7 days | 30 days | 90 days]

**AI**
- LLM Model: [Dropdown: available Ollama models]
- OpenAI API Key: [Secure text field]

**About**
- Version: 1.0.0
- Check for Updates

---

### 3.4 Session History View

#### Layout
- List of past sessions
- Each item shows: Date, Title, Duration, Actions count
- Click to view details or re-process
- Search bar at top
- Filter by date range

---

## 4. Functional Specification

### 4.1 Core Features

#### Audio Recording
- Capture system audio via BlackHole virtual device
- Support for built-in microphone option
- Real-time audio level visualization
- Automatic gain control

#### Screen Recording
- Multi-monitor detection and selection
- Resolution: Native display resolution
- Frame rate: 15 fps (configurable: 10/15/30)
- Codec: H.264 (Hardware acceleration when available)
- Audio sync: Interleaved with video

#### Transcription
- Engine: Faster-Whisper (local)
- Models: tiny, base, small, medium, large
- Language: Auto-detect or manual selection
- Real-time transcription with chunked processing

#### Vision AI (Screen+Audio mode)
- Frame extraction: 1 frame per 5 seconds (configurable)
- Slide detection: Compare frames, extract key slides
- Content analysis: GPT-4V or Ollama vision models

#### Action Item Extraction
- Local LLM: Ollama with Llama 3.2
- Cloud option: OpenAI API
- Extract: Task, Assignee, Deadline, Context, Confidence

#### Meeting Analysis
- Summary generation
- Key decisions extraction
- Participant identification
- Topic/chapter detection

#### Output Generation
- Word document (.docx)
- Plain text transcript
- Extracted slides (images)
- Video file (optional)

### 4.2 User Interactions

| Action | Trigger | Response |
|--------|---------|----------|
| Start Recording | Click "Start" or keyboard shortcut | Begin capture, show recording UI |
| Stop Recording | Click "Stop" or keyboard shortcut | End capture, begin processing |
| Select Monitor | Dropdown selection | Update preview, save preference |
| Change Settings | Edit in settings panel | Save to config, apply immediately |
| View History | Click history tab | Load sessions list |
| Search Sessions | Type in search | Filter sessions in real-time |

### 4.3 Data Flow

```
User Action
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│                  SwiftUI View Layer                     │
│  (User interface, captures events)                      │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                   ViewModel Layer                       │
│  (State management, business logic orchestration)       │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                 Application Layer                       │
│  (Use Cases: StartRecording, StopRecording, etc.)      │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                Infrastructure Layer                     │
│  (PythonBridge → Python Core → System APIs)            │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    Core Modules                         │
│  Audio → Screen → Transcription → Vision → Extraction  │
└─────────────────────────────────────────────────────────┘
```

### 4.4 Key Modules

#### SwiftUI Layer
| Module | Responsibility |
|--------|---------------|
| `OnboardingViewModel` | Manage onboarding state and flow |
| `RecordingViewModel` | Manage recording session state |
| `SettingsViewModel` | Handle settings persistence |
| `PythonBridgeService` | Communicate with Python core |

#### Python Core
| Module | Responsibility |
|--------|---------------|
| `audio/capture.py` | System audio capture |
| `screen/capture.py` | Screen recording |
| `transcription/engine.py` | Whisper transcription |
| `vision/frame_extractor.py` | Frame sampling |
| `vision/providers/` | Vision AI providers |
| `extraction/action_extractor.py` | LLM action extraction |
| `storage/database.py` | SQLite persistence |

### 4.5 Edge Cases

| Scenario | Handling |
|----------|----------|
| No audio device | Show error, disable recording |
| No screen recording permission | Prompt to enable in System Settings |
| Disk full | Warning before recording, stop if full |
| Ollama not running | Auto-start Ollama or prompt user |
| OpenAI API key invalid | Show error, allow retry |
| Recording interrupted | Auto-save partial session |
| Multiple monitors disconnected | Fall back to primary display |

---

## 5. Technical Specification

### 5.1 Technology Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI |
| App Architecture | MVVM + Clean Architecture |
| Backend | Python 3.11+ |
| Audio Capture | sounddevice + BlackHole |
| Screen Capture | ffmpeg + avfoundation |
| Transcription | faster-whisper |
| LLM (Local) | Ollama |
| LLM (Cloud) | OpenAI API |
| Storage | SQLite |
| Word Export | python-docx |
| Packaging | Xcode + create-dmg |

### 5.2 Distribution

| Channel | Build Target | Entitlements |
|---------|--------------|--------------|
| App Store | NudgePro-AppStore | Sandbox enabled |
| Direct Download | NudgePro-Direct | Full access |

### 5.3 Dependencies (Python)

```
faster-whisper
sounddevice
numpy
ffmpeg-python
python-docx
python-dotenv
sqlalchemy
pydantic
```

### 5.4 System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| macOS | 12.3 (Monterey) | 14.0 (Sonoma) |
| RAM | 8GB | 16GB |
| Storage | 2GB free | 10GB free |
| Processor | Apple Silicon | Apple Silicon |

---

## 6. Acceptance Criteria

### 6.1 Core Functionality
- [ ] Audio-only recording works with BlackHole
- [ ] Screen recording works with ffmpeg
- [ ] Multi-monitor detection works
- [ ] Monitor selection works
- [ ] Transcription generates accurate results
- [ ] Action items are extracted correctly
- [ ] Word documents are generated properly

### 6.2 UI/UX
- [ ] Onboarding wizard completes all steps
- [ ] Recording view shows correct states
- [ ] Settings persist between sessions
- [ ] Dark theme is consistent throughout

### 6.3 Distribution
- [ ] DMG builds successfully
- [ ] App runs outside App Store
- [ ] Notarization passes
- [ ] App Store build meets guidelines

### 6.4 Performance
- [ ] Recording doesn't drop frames
- [ ] UI remains responsive during recording
- [ ] Processing completes in reasonable time

---

## 7. Non-Functional Requirements

### Privacy
- All processing on-device (unless user provides API key)
- No telemetry or analytics without consent
- Audio/video never leaves user's machine

### Security
- API keys stored in Keychain
- App Sandbox enabled for App Store
- Proper code signing and notarization

### Accessibility
- VoiceOver support
- Keyboard navigation
- High contrast mode support

---

## 8. Future Enhancements (Out of Scope)

- [ ] Multi-language transcription
- [ ] Team sharing and collaboration
- [ ] Cloud storage integration
- [ ] Web dashboard
- [ ] Mobile companion app
- [ ] Real-time transcription display

---

*Document Version: 1.0*  
*Last Updated: March 2026*
