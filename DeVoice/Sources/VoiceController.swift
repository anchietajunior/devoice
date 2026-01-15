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
            appState.setError("Microphone permission denied.")
            return
        }

        do {
            try audioRecorder.startRecording()
            appState.setState(.recording)
            floatingWindow.show()
        } catch {
            appState.setError("Failed to start recording: \(error.localizedDescription)")
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
            appState.setError("API Key not configured.")
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
