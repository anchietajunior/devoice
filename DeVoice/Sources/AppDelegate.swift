import AppKit
import SwiftUI
import Combine

@MainActor
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
        voiceController = VoiceController(appState: AppState.shared)
        if !voiceController!.start() {
            // Will prompt for accessibility permission
        }
    }

    private func observeStateChanges() {
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

        AppState.shared.clearError()
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
