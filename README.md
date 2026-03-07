# Nudge Pro

A macOS meeting recording app that records, transcribes, and generates AI-powered meeting notes.

## Features

- **Audio Recording** - Record meeting audio using microphone and system audio
- **Transcription** - Automatic speech-to-text using Apple's Speech framework
- **AI Meeting Notes** - Generate summaries and action items using LLM
- **Session History** - Browse and search past meetings
- **Export** - Export notes as Markdown

## Supported LLM Providers

- **Ollama** (default) - Free, runs locally
- **OpenAI** - GPT-4, GPT-3.5
- **Anthropic** - Claude
- **Custom** - Any OpenAI-compatible API (e.g., LM Studio)

## Requirements

- macOS 13.0+
- Microphone permission
- Screen Recording permission (for system audio)
- Speech Recognition permission (for transcription)

## Installation

1. Clone the repository
2. Open `NudgePro.xcodeproj` in Xcode
3. Build and run (Cmd+R)

### Setting up Ollama (recommended)

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull a model
ollama pull llama3.2:latest

# Start Ollama
ollama serve
```

## Usage

1. **First Launch** - Complete onboarding to grant permissions
2. **Record** - Click the record button to start recording
3. **Stop** - Click stop to end recording (processing happens in background)
4. **View Notes** - Check History for transcriptions and AI-generated notes

## Keyboard Shortcuts

- `Cmd+Shift+O` - Reopen onboarding

## Privacy

- All recordings stored locally on your Mac
- Transcription uses Apple's on-device Speech framework
- AI processing runs locally (Ollama) or via your API keys (OpenAI/Anthropic)
- No data sent to external servers unless you use cloud AI providers

## License

MIT
