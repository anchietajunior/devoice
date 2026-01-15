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
