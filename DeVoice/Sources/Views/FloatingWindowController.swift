import AppKit
import SwiftUI

class FloatingWindowController {
    private var window: NSWindow?
    private var hostingView: NSHostingView<FloatingOverlay>?
    private let appState: AppState
    private let windowSize = NSSize(width: 160, height: 40)

    init(appState: AppState) {
        self.appState = appState
        createWindow()
    }

    func show() {
        positionWindow()
        window?.orderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func createWindow() {
        let contentView = FloatingOverlay(appState: appState)

        let hosting = NSHostingView(rootView: contentView)
        hosting.frame = NSRect(origin: .zero, size: windowSize)
        hosting.autoresizingMask = []

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false

        self.hostingView = hosting
        self.window = panel
    }

    private func positionWindow() {
        guard let screen = NSScreen.main, let window = window else { return }

        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - windowSize.width - 20
        let y = screenFrame.minY + 20

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
