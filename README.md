# DeVoice

A native macOS menu bar app that converts your voice to text using OpenAI's Whisper API. Hold the **fn** key, speak, release — your words appear wherever your cursor is.

## Features

- **Press-and-hold activation** — Hold `fn` to record, release to transcribe
- **Universal text injection** — Works in any app with a text field
- **Visual feedback** — Menu bar icon changes color + floating indicator
- **Secure storage** — API key stored in macOS Keychain
- **Lightweight** — Native Swift app, minimal resource usage

## Requirements

- macOS 13.0 or later
- OpenAI API key — [Get one here](https://platform.openai.com/api-keys)

## Installation

### Download (Recommended)

1. Download `DeVoice-x.x.x-macOS.zip` from the [Releases](https://github.com/yourusername/devoice/releases) page
2. Unzip and drag `DeVoice.app` to your **Applications** folder
3. **Important:** Right-click the app → **Open** (required for first launch to bypass Gatekeeper)
4. Grant Accessibility permission when prompted (one-time setup)

### Build from source

```bash
git clone https://github.com/yourusername/devoice.git
cd devoice

./scripts/build-app.sh
cp -r build/DeVoice.app /Applications/
```

> **Note for developers:** Rebuilding the app changes its signature, which may require re-granting Accessibility permission. This only affects development, not end users.

## Setup

### 1. Launch DeVoice

Open DeVoice from Launchpad, Spotlight (Cmd+Space), or `/Applications/DeVoice.app`.

A microphone icon will appear in your menu bar.

### 2. Grant Accessibility Permission

On first launch, macOS will prompt you to grant Accessibility permission:

1. Click **Open System Settings** when prompted
2. In **Privacy & Security → Accessibility**, find **DeVoice**
3. Toggle it **ON**
4. **Quit and reopen DeVoice** (required for permission to take effect)

> **Note:** If you rebuild the app, you may need to remove the old entry and re-enable the new one.

### 3. Add your OpenAI API Key

1. Click the microphone icon in the menu bar
2. Select **Settings...**
3. Enter your OpenAI API key
4. Click **Save**

### 4. Grant Microphone Permission

The first time you record, macOS will ask for microphone access. Click **OK** to allow.

## Usage

1. Place your cursor in any text field (browser, editor, notes, etc.)
2. **Press and hold** the `fn` key
3. Speak clearly
4. **Release** the `fn` key
5. Wait briefly while your speech is transcribed
6. Text appears at your cursor position

### Visual Feedback

| State | Menu Bar Icon | Floating Indicator |
|-------|--------------|-------------------|
| Ready | Gray microphone | Hidden |
| Recording | Red microphone | "Recording..." |
| Transcribing | Yellow microphone | "Transcribing..." |

## Troubleshooting

### The fn key doesn't trigger recording

1. Open **System Settings → Privacy & Security → Accessibility**
2. If DeVoice is listed, toggle it OFF then ON again
3. If not listed, remove any old DeVoice entries and reopen the app
4. **Restart the app** after changing permissions

### App keeps asking for Accessibility permission

This happens when you rebuild the app (the signature changes). Fix:

```bash
# Reset permissions for DeVoice
tccutil reset Accessibility com.devoice.app

# Reopen the app and grant permission again
open /Applications/DeVoice.app
```

### No text appears after speaking

1. Verify your API key is valid in Settings
2. Check your internet connection
3. Ensure Microphone permission is granted in System Settings

### Text appears in wrong location

Make sure your cursor is in an active, focused text field before releasing the fn key.

## How It Works

```
fn pressed → Start recording (microphone)
     ↓
fn released → Stop recording
     ↓
Send audio to OpenAI Whisper API
     ↓
Receive transcribed text
     ↓
Paste text at cursor (via clipboard + Cmd+V)
     ↓
Restore original clipboard
```

## Project Structure

```
DeVoice/
├── Package.swift
├── Sources/
│   ├── DeVoiceApp.swift           # App entry point
│   ├── AppDelegate.swift          # Menu bar setup
│   ├── AppState.swift             # State management
│   ├── VoiceController.swift      # Main coordinator
│   ├── Services/
│   │   ├── HotkeyManager.swift    # fn key capture
│   │   ├── AudioRecorder.swift    # Microphone recording
│   │   ├── WhisperService.swift   # OpenAI API client
│   │   └── TextInjector.swift     # Text injection
│   ├── Views/
│   │   ├── SettingsView.swift     # Settings window
│   │   ├── FloatingOverlay.swift  # Status indicator
│   │   └── FloatingWindowController.swift
│   └── Utilities/
│       └── KeychainHelper.swift   # Secure storage
└── scripts/
    └── build-app.sh               # Build script
```

## Privacy & Security

- **API Key** — Stored securely in macOS Keychain, never in plain text
- **Audio** — Recorded to a temporary file, deleted immediately after transcription
- **Network** — Audio sent directly to OpenAI's API, no intermediate servers
- **Permissions** — Accessibility is only used to capture the fn key and paste text

## Tech Stack

- Swift 5.9 + SwiftUI
- AVFoundation (audio recording)
- CGEventTap (global hotkey)
- OpenAI Whisper API (speech-to-text)

## Development

```bash
# Run in development mode
cd DeVoice
swift run

# Build release
./scripts/build-app.sh
```

## License

MIT

## Acknowledgments

Inspired by [Whisper Flow](https://github.com/lspahija/whisper-flow) and similar voice-to-text utilities.
