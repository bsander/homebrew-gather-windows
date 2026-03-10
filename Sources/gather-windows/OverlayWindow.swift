import AppKit
import SwiftUI

/// Borderless fullscreen overlay window positioned on a specific screen
class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }

    init(screen: NSScreen, screenNumber: Int) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.setFrame(screen.frame, display: false)
        self.level = .screenSaver
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.ignoresMouseEvents = true

        let hostingView = NSHostingView(rootView: OverlayView(screenNumber: screenNumber))
        hostingView.frame = self.contentView?.bounds ?? screen.frame
        self.contentView = hostingView
    }
}
