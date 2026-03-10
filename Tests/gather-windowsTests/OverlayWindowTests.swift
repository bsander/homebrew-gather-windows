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
}
