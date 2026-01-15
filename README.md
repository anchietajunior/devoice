# DeVoice

A native macOS menu bar app that converts your voice to text using OpenAI's Whisper API. Simply hold the **fn** key, speak, and release — your words appear wherever your cursor is.

## Features

- **Press-and-hold activation** — Hold `fn` to record, release to transcribe
- **Universal text injection** — Works in any app with a text field
- **Visual feedback** — Menu bar icon changes color + floating indicator
- **Secure storage** — API key stored in macOS Keychain
- **Lightweight** — Native Swift app, minimal resource usage

## Demo

| State | Menu Bar | Floating Indicator |
|-------|----------|-------------------|
| Idle | Gray mic icon | Hidden |
| Recording | Red mic icon | "Gravando..." |
| Processing | Yellow mic icon | "Transcrevendo..." |

## Requirements

- macOS 13.0 or later
- OpenAI API key ([get one here](https://platform.openai.com/api-keys))

## Installation

### Build from source

```bash
git clone https://github.com/yourusername/devoice.git
cd devoice/DeVoice
swift build -c release
```

### Run

```bash
swift run
```

Or copy the built binary to your Applications folder:

```bash
cp .build/release/DeVoice /Applications/
```

## Setup

1. **Launch DeVoice** — A microphone icon appears in your menu bar

2. **Add your API key** — Click the icon → "Configurações..." → Enter your OpenAI API key → Save

3. **Grant permissions** — When prompted, allow:
   - **Accessibility** — Required to capture the fn key and inject text
   - **Microphone** — Required to record your voice

## Usage

1. Place your cursor in any text field
2. **Press and hold** the `fn` key
3. Speak clearly
4. **Release** the `fn` key
5. Wait briefly while your speech is transcribed
6. Text appears at your cursor position

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│  fn pressed                                             │
│      ↓                                                  │
│  Start recording (AVFoundation)                         │
│      ↓                                                  │
│  fn released                                            │
│      ↓                                                  │
│  Send audio to OpenAI Whisper API                       │
│      ↓                                                  │
│  Receive transcribed text                               │
│      ↓                                                  │
│  Inject text via clipboard + Cmd+V                      │
│      ↓                                                  │
│  Restore original clipboard                             │
└─────────────────────────────────────────────────────────┘
```

## Architecture

```
DeVoice/
├── Sources/
│   ├── DeVoiceApp.swift          # App entry point
│   ├── AppDelegate.swift         # Menu bar + integration
│   ├── AppState.swift            # Centralized state management
│   ├── VoiceController.swift     # Main coordinator
│   ├── Services/
│   │   ├── HotkeyManager.swift   # fn key capture (CGEventTap)
│   │   ├── AudioRecorder.swift   # Microphone recording
│   │   ├── WhisperService.swift  # OpenAI API integration
│   │   └── TextInjector.swift    # Text injection via clipboard
│   ├── Views/
│   │   ├── SettingsView.swift    # Settings window
│   │   ├── FloatingOverlay.swift # Status indicator
│   │   └── FloatingWindowController.swift
│   └── Utilities/
│       └── KeychainHelper.swift  # Secure API key storage
└── Package.swift
```

## Privacy & Security

- Your API key is stored securely in the macOS Keychain
- Audio is recorded to a temporary file and deleted after transcription
- Audio is sent directly to OpenAI's API — no intermediate servers
- The app requires Accessibility permission only to capture hotkeys and inject text

## Troubleshooting

### The fn key doesn't trigger recording

1. Go to **System Settings → Privacy & Security → Accessibility**
2. Find DeVoice and enable it
3. Restart the app

### No text appears after speaking

1. Check that your API key is valid in Settings
2. Ensure you have an active internet connection
3. Check the Microphone permission in System Settings

### Text appears in wrong location

The app uses clipboard + paste (Cmd+V). Make sure your cursor is in an active text field before releasing the fn key.

## Tech Stack

- **Swift 5.9** + **SwiftUI**
- **AVFoundation** — Audio recording
- **CGEventTap** — Global hotkey capture
- **OpenAI Whisper API** — Speech-to-text

## License

MIT

## Acknowledgments

Inspired by [Whisper Flow](https://github.com/lspahija/whisper-flow) and similar voice-to-text utilities.
