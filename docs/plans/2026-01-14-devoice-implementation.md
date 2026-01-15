# DeVoice Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a macOS menu bar app that converts voice to text using OpenAI Whisper API, triggered by holding the fn key.

**Architecture:** Swift/SwiftUI menu bar app with four core services (HotkeyManager, AudioRecorder, WhisperService, TextInjector) coordinated by a central AppState. Floating overlay window provides visual feedback.

**Tech Stack:** Swift 5.9, SwiftUI, AVFoundation, CGEvent API, Keychain Services

---

## Task 1: Create Xcode Project

**Files:**
- Create: `DeVoice.xcodeproj`
- Create: `DeVoice/DeVoiceApp.swift`

**Step 1: Create the Xcode project via command line**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice
mkdir -p DeVoice
```

**Step 2: Create the Swift Package manifest for the app**

Create `DeVoice/Package.swift`:
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeVoice",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DeVoice",
            path: "Sources"
        )
    ]
)
```

**Step 3: Create main app entry point**

Create `DeVoice/Sources/DeVoiceApp.swift`:
```swift
import SwiftUI

@main
struct DeVoiceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
```

**Step 4: Create AppDelegate skeleton**

Create `DeVoice/Sources/AppDelegate.swift`:
```swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "DeVoice")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Configurações...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Sair", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func openSettings() {
        // TODO: Implement settings window
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
```

**Step 5: Create Info.plist for permissions**

Create `DeVoice/Sources/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>DeVoice</string>
    <key>CFBundleIdentifier</key>
    <string>com.devoice.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>DeVoice precisa acessar o microfone para gravar sua voz e convertê-la em texto.</string>
</dict>
</plist>
```

**Step 6: Build and verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Build succeeds

**Step 7: Commit**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice
git init
git add .
git commit -m "feat: initial project setup with menu bar skeleton"
```

---

## Task 2: Implement AppState

**Files:**
- Create: `DeVoice/Sources/AppState.swift`

**Step 1: Create AppState with observable state**

Create `DeVoice/Sources/AppState.swift`:
```swift
import Foundation
import Combine

enum VoiceState {
    case idle
    case recording
    case processing
}

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var state: VoiceState = .idle
    @Published var apiKey: String = ""
    @Published var errorMessage: String?

    private init() {
        loadAPIKey()
    }

    func setState(_ newState: VoiceState) {
        state = newState
    }

    func setError(_ message: String) {
        errorMessage = message
    }

    func clearError() {
        errorMessage = nil
    }

    private func loadAPIKey() {
        apiKey = KeychainHelper.load(key: "openai_api_key") ?? ""
    }

    func saveAPIKey(_ key: String) {
        apiKey = key
        KeychainHelper.save(key: "openai_api_key", value: key)
    }
}
```

**Step 2: Build to verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Fails (KeychainHelper not found) - this is expected, we'll create it next

**Step 3: Commit**

```bash
git add DeVoice/Sources/AppState.swift
git commit -m "feat: add AppState for centralized state management"
```

---

## Task 3: Implement KeychainHelper

**Files:**
- Create: `DeVoice/Sources/Utilities/KeychainHelper.swift`

**Step 1: Create KeychainHelper**

Create `DeVoice/Sources/Utilities/KeychainHelper.swift`:
```swift
import Foundation
import Security

enum KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.devoice.app"
        ]

        SecItemDelete(query as CFDictionary)

        var newQuery = query
        newQuery[kSecValueData as String] = data

        SecItemAdd(newQuery as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.devoice.app",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.devoice.app"
        ]

        SecItemDelete(query as CFDictionary)
    }
}
```

**Step 2: Build to verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add DeVoice/Sources/Utilities/KeychainHelper.swift
git commit -m "feat: add KeychainHelper for secure API key storage"
```

---

## Task 4: Implement AudioRecorder

**Files:**
- Create: `DeVoice/Sources/Services/AudioRecorder.swift`

**Step 1: Create AudioRecorder service**

Create `DeVoice/Sources/Services/AudioRecorder.swift`:
```swift
import AVFoundation
import Foundation

class AudioRecorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private let tempFileURL: URL

    override init() {
        tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("devoice_recording.m4a")
        super.init()
    }

    func startRecording() throws {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Delete previous recording if exists
        try? FileManager.default.removeItem(at: tempFileURL)

        audioRecorder = try AVAudioRecorder(url: tempFileURL, settings: settings)
        audioRecorder?.record()
    }

    func stopRecording() -> URL? {
        guard let recorder = audioRecorder, recorder.isRecording else {
            return nil
        }

        recorder.stop()
        audioRecorder = nil

        // Verify file exists
        guard FileManager.default.fileExists(atPath: tempFileURL.path) else {
            return nil
        }

        return tempFileURL
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: tempFileURL)
    }

    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
```

**Step 2: Build to verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add DeVoice/Sources/Services/AudioRecorder.swift
git commit -m "feat: add AudioRecorder service for microphone capture"
```

---

## Task 5: Implement WhisperService

**Files:**
- Create: `DeVoice/Sources/Services/WhisperService.swift`

**Step 1: Create WhisperService**

Create `DeVoice/Sources/Services/WhisperService.swift`:
```swift
import Foundation

struct WhisperResponse: Codable {
    let text: String
}

struct WhisperError: Codable {
    let error: WhisperErrorDetail
}

struct WhisperErrorDetail: Codable {
    let message: String
}

class WhisperService {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func transcribe(audioURL: URL) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add file
        let audioData = try Data(contentsOf: audioURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhisperServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw WhisperServiceError.invalidAPIKey
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(WhisperError.self, from: data) {
                throw WhisperServiceError.apiError(errorResponse.error.message)
            }
            throw WhisperServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let result = try JSONDecoder().decode(WhisperResponse.self, from: data)
        return result.text
    }
}

enum WhisperServiceError: LocalizedError {
    case invalidAPIKey
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API Key inválida. Verifique suas configurações."
        case .invalidResponse:
            return "Resposta inválida do servidor."
        case .apiError(let message):
            return "Erro da API: \(message)"
        }
    }
}
```

**Step 2: Build to verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add DeVoice/Sources/Services/WhisperService.swift
git commit -m "feat: add WhisperService for OpenAI STT integration"
```

---

## Task 6: Implement TextInjector

**Files:**
- Create: `DeVoice/Sources/Services/TextInjector.swift`

**Step 1: Create TextInjector**

Create `DeVoice/Sources/Services/TextInjector.swift`:
```swift
import AppKit
import Carbon.HIToolbox

class TextInjector {
    func inject(text: String) {
        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)

        // Set new content
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V
        simulatePaste()

        // Restore previous clipboard content after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if let previous = previousContent {
                pasteboard.clearContents()
                pasteboard.setString(previous, forType: .string)
            }
        }
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key code for 'V' is 9
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
```

**Step 2: Build to verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add DeVoice/Sources/Services/TextInjector.swift
git commit -m "feat: add TextInjector for clipboard-based text injection"
```

---

## Task 7: Implement HotkeyManager

**Files:**
- Create: `DeVoice/Sources/Services/HotkeyManager.swift`

**Step 1: Create HotkeyManager**

Create `DeVoice/Sources/Services/HotkeyManager.swift`:
```swift
import AppKit
import Carbon.HIToolbox

class HotkeyManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isFnPressed = false

    var onFnPressed: (() -> Void)?
    var onFnReleased: (() -> Void)?

    func start() -> Bool {
        let eventMask = (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }

                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                manager.handleEvent(event)

                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handleEvent(_ event: CGEvent) {
        let flags = event.flags
        let fnPressed = flags.contains(.maskSecondaryFn)

        if fnPressed && !isFnPressed {
            isFnPressed = true
            DispatchQueue.main.async { [weak self] in
                self?.onFnPressed?()
            }
        } else if !fnPressed && isFnPressed {
            isFnPressed = false
            DispatchQueue.main.async { [weak self] in
                self?.onFnReleased?()
            }
        }
    }
}
```

**Step 2: Build to verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add DeVoice/Sources/Services/HotkeyManager.swift
git commit -m "feat: add HotkeyManager for fn key capture"
```

---

## Task 8: Implement SettingsView

**Files:**
- Create: `DeVoice/Sources/Views/SettingsView.swift`

**Step 1: Create SettingsView**

Create `DeVoice/Sources/Views/SettingsView.swift`:
```swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKeyInput: String = ""
    @State private var showKey: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configurações")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("OpenAI API Key")
                    .font(.headline)

                HStack {
                    if showKey {
                        TextField("sk-...", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("sk-...", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(action: { showKey.toggle() }) {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }

                Text("Sua API key é armazenada de forma segura no Keychain.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Permissões")
                    .font(.headline)

                HStack {
                    Image(systemName: TextInjector.checkAccessibilityPermission() ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(TextInjector.checkAccessibilityPermission() ? .green : .red)
                    Text("Acessibilidade")
                    Spacer()
                    if !TextInjector.checkAccessibilityPermission() {
                        Button("Habilitar") {
                            TextInjector.requestAccessibilityPermission()
                        }
                    }
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancelar") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Salvar") {
                    appState.saveAPIKey(apiKeyInput)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(apiKeyInput.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400, height: 280)
        .onAppear {
            apiKeyInput = appState.apiKey
        }
    }
}
```

**Step 2: Build to verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add DeVoice/Sources/Views/SettingsView.swift
git commit -m "feat: add SettingsView for API key configuration"
```

---

## Task 9: Implement FloatingOverlay

**Files:**
- Create: `DeVoice/Sources/Views/FloatingOverlay.swift`

**Step 1: Create FloatingOverlay view**

Create `DeVoice/Sources/Views/FloatingOverlay.swift`:
```swift
import SwiftUI

struct FloatingOverlay: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(stateColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(stateColor.opacity(0.5), lineWidth: 2)
                        .scaleEffect(appState.state == .recording ? 1.5 : 1.0)
                        .opacity(appState.state == .recording ? 0 : 1)
                        .animation(
                            appState.state == .recording
                                ? .easeOut(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: appState.state
                        )
                )

            Text(stateText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private var stateColor: Color {
        switch appState.state {
        case .idle:
            return .gray
        case .recording:
            return .red
        case .processing:
            return .yellow
        }
    }

    private var stateText: String {
        switch appState.state {
        case .idle:
            return "Pronto"
        case .recording:
            return "Gravando..."
        case .processing:
            return "Transcrevendo..."
        }
    }
}
```

**Step 2: Build to verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add DeVoice/Sources/Views/FloatingOverlay.swift
git commit -m "feat: add FloatingOverlay for visual feedback"
```

---

## Task 10: Implement FloatingWindowController

**Files:**
- Create: `DeVoice/Sources/Views/FloatingWindowController.swift`

**Step 1: Create FloatingWindowController**

Create `DeVoice/Sources/Views/FloatingWindowController.swift`:
```swift
import AppKit
import SwiftUI

class FloatingWindowController {
    private var window: NSWindow?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        if window == nil {
            createWindow()
        }
        window?.orderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func createWindow() {
        let contentView = FloatingOverlay(appState: appState)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = CGRect(x: 0, y: 0, width: 180, height: 44)

        let window = NSWindow(
            contentRect: hostingView.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isMovableByWindowBackground = false
        window.hasShadow = false

        positionWindow(window)

        self.window = window
    }

    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame

        let x = screenFrame.maxX - windowFrame.width - 20
        let y = screenFrame.minY + 20

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
```

**Step 2: Build to verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add DeVoice/Sources/Views/FloatingWindowController.swift
git commit -m "feat: add FloatingWindowController for overlay positioning"
```

---

## Task 11: Implement VoiceController (Coordinator)

**Files:**
- Create: `DeVoice/Sources/VoiceController.swift`

**Step 1: Create VoiceController**

Create `DeVoice/Sources/VoiceController.swift`:
```swift
import Foundation

@MainActor
class VoiceController {
    private let appState: AppState
    private let hotkeyManager = HotkeyManager()
    private let audioRecorder = AudioRecorder()
    private let textInjector = TextInjector()
    private let floatingWindow: FloatingWindowController

    init(appState: AppState) {
        self.appState = appState
        self.floatingWindow = FloatingWindowController(appState: appState)
        setupHotkey()
    }

    private func setupHotkey() {
        hotkeyManager.onFnPressed = { [weak self] in
            Task { @MainActor in
                await self?.startRecording()
            }
        }

        hotkeyManager.onFnReleased = { [weak self] in
            Task { @MainActor in
                await self?.stopRecordingAndTranscribe()
            }
        }
    }

    func start() -> Bool {
        guard TextInjector.checkAccessibilityPermission() else {
            TextInjector.requestAccessibilityPermission()
            return false
        }

        return hotkeyManager.start()
    }

    func stop() {
        hotkeyManager.stop()
    }

    private func startRecording() async {
        guard appState.state == .idle else { return }

        let hasPermission = await AudioRecorder.requestPermission()
        guard hasPermission else {
            appState.setError("Permissão de microfone negada.")
            return
        }

        do {
            try audioRecorder.startRecording()
            appState.setState(.recording)
            floatingWindow.show()
        } catch {
            appState.setError("Erro ao iniciar gravação: \(error.localizedDescription)")
        }
    }

    private func stopRecordingAndTranscribe() async {
        guard appState.state == .recording else { return }

        guard let audioURL = audioRecorder.stopRecording() else {
            appState.setState(.idle)
            floatingWindow.hide()
            return
        }

        appState.setState(.processing)

        guard !appState.apiKey.isEmpty else {
            appState.setError("API Key não configurada.")
            appState.setState(.idle)
            floatingWindow.hide()
            audioRecorder.cleanup()
            return
        }

        let whisperService = WhisperService(apiKey: appState.apiKey)

        do {
            let text = try await whisperService.transcribe(audioURL: audioURL)
            textInjector.inject(text: text)
        } catch {
            appState.setError(error.localizedDescription)
        }

        audioRecorder.cleanup()
        appState.setState(.idle)
        floatingWindow.hide()
    }
}
```

**Step 2: Build to verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add DeVoice/Sources/VoiceController.swift
git commit -m "feat: add VoiceController to coordinate all services"
```

---

## Task 12: Update AppDelegate with Full Integration

**Files:**
- Modify: `DeVoice/Sources/AppDelegate.swift`

**Step 1: Update AppDelegate**

Replace content of `DeVoice/Sources/AppDelegate.swift`:
```swift
import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var voiceController: VoiceController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupVoiceController()
        observeStateChanges()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon(state: .idle)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Configurações...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Sair", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func setupVoiceController() {
        Task { @MainActor in
            voiceController = VoiceController(appState: AppState.shared)
            if !voiceController!.start() {
                // Will prompt for accessibility permission
            }
        }
    }

    private func observeStateChanges() {
        Task { @MainActor in
            AppState.shared.$state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.updateStatusIcon(state: state)
                }
                .store(in: &cancellables)

            AppState.shared.$errorMessage
                .receive(on: DispatchQueue.main)
                .compactMap { $0 }
                .sink { [weak self] message in
                    self?.showError(message)
                }
                .store(in: &cancellables)
        }
    }

    private func updateStatusIcon(state: VoiceState) {
        let symbolName: String
        let color: NSColor

        switch state {
        case .idle:
            symbolName = "mic.fill"
            color = .secondaryLabelColor
        case .recording:
            symbolName = "mic.fill"
            color = .systemRed
        case .processing:
            symbolName = "mic.fill"
            color = .systemYellow
        }

        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            var image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "DeVoice")
            image = image?.withSymbolConfiguration(config)
            image?.isTemplate = state == .idle

            if state != .idle {
                image = image?.tinted(with: color)
            }

            button.image = image
        }
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(appState: AppState.shared)
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 280),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "DeVoice - Configurações"
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            settingsWindow?.center()
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Erro"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()

        Task { @MainActor in
            AppState.shared.clearError()
        }
    }

    @objc private func quit() {
        voiceController?.stop()
        NSApp.terminate(nil)
    }
}

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: image.size)
        rect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}
```

**Step 2: Build to verify**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add DeVoice/Sources/AppDelegate.swift
git commit -m "feat: integrate all components in AppDelegate"
```

---

## Task 13: Test the Complete App

**Step 1: Run the app**

```bash
cd /Users/joseanchieta/Documents/Dev/devoice/DeVoice
swift run
```

Expected: App starts, shows icon in menu bar

**Step 2: Verify menu bar icon appears**

- Gray microphone icon should appear in menu bar
- Click should show menu with "Configurações..." and "Sair"

**Step 3: Open settings and add API key**

- Click menu bar icon → "Configurações..."
- Add your OpenAI API key
- Click "Salvar"

**Step 4: Grant permissions**

- System should prompt for Accessibility permission
- System should prompt for Microphone permission
- Grant both

**Step 5: Test voice-to-text**

- Open any text field (Notes, browser, etc.)
- Hold fn key → icon turns red, floating window appears
- Speak something
- Release fn → icon turns yellow, "Transcrevendo..."
- Text should appear where cursor was

**Step 6: Final commit**

```bash
git add .
git commit -m "feat: complete DeVoice v1.0 implementation"
```

---

## Summary

**Files created:**
- `DeVoice/Package.swift`
- `DeVoice/Sources/DeVoiceApp.swift`
- `DeVoice/Sources/AppDelegate.swift`
- `DeVoice/Sources/AppState.swift`
- `DeVoice/Sources/VoiceController.swift`
- `DeVoice/Sources/Info.plist`
- `DeVoice/Sources/Utilities/KeychainHelper.swift`
- `DeVoice/Sources/Services/AudioRecorder.swift`
- `DeVoice/Sources/Services/WhisperService.swift`
- `DeVoice/Sources/Services/TextInjector.swift`
- `DeVoice/Sources/Services/HotkeyManager.swift`
- `DeVoice/Sources/Views/SettingsView.swift`
- `DeVoice/Sources/Views/FloatingOverlay.swift`
- `DeVoice/Sources/Views/FloatingWindowController.swift`
