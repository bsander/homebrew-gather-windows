import AppKit
import Testing
@testable import gather_windows

@Suite("OverlayWindow")
@MainActor
struct OverlayWindowTests {
    @Test("can become key window for keyboard event capture")
    func canBecomeKey() {
        let screen = NSScreen.main!
        let overlay = OverlayWindow(screen: screen, screenNumber: 1)
        #expect(overlay.canBecomeKey == true)
    }

    @Test("message overlay covers screen frame")
    func messageOverlayCoverScreen() {
        let screen = NSScreen.main!
        let overlay = OverlayWindow(screen: screen, message: "Only one screen detected.")
        #expect(overlay.frame == screen.frame)
        #expect(overlay.canBecomeKey == true)
    }
}
