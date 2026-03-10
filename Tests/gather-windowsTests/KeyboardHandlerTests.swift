import Testing
import AppKit
@testable import gather_windows

@Suite("KeyboardHandler")
struct KeyboardHandlerTests {

    @Test @MainActor func numberKeyCallsOnNumberPressed() {
        var receivedNumber: Int?
        let handler = KeyboardHandler(
            maxNumber: 3,
            onNumberPressed: { receivedNumber = $0 },
            onEscape: {}
        )

        // Simulate pressing "2"
        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "2",
            charactersIgnoringModifiers: "2",
            isARepeat: false,
            keyCode: 19 // key code for "2"
        )!

        handler.handleKeyForTesting(event)
        #expect(receivedNumber == 2)
    }

    @Test @MainActor func escapeKeyCallsOnEscape() {
        var escapeCalled = false
        let handler = KeyboardHandler(
            maxNumber: 3,
            onNumberPressed: { _ in },
            onEscape: { escapeCalled = true }
        )

        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "\u{1B}",
            charactersIgnoringModifiers: "\u{1B}",
            isARepeat: false,
            keyCode: 53 // Escape
        )!

        handler.handleKeyForTesting(event)
        #expect(escapeCalled)
    }

    @Test @MainActor func numberAboveMax_isIgnored() {
        var receivedNumber: Int?
        let handler = KeyboardHandler(
            maxNumber: 2,
            onNumberPressed: { receivedNumber = $0 },
            onEscape: {}
        )

        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "5",
            charactersIgnoringModifiers: "5",
            isARepeat: false,
            keyCode: 23
        )!

        handler.handleKeyForTesting(event)
        #expect(receivedNumber == nil)
    }

    @Test @MainActor func letterKey_isIgnored() {
        var receivedNumber: Int?
        var escapeCalled = false
        let handler = KeyboardHandler(
            maxNumber: 3,
            onNumberPressed: { receivedNumber = $0 },
            onEscape: { escapeCalled = true }
        )

        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "a",
            charactersIgnoringModifiers: "a",
            isARepeat: false,
            keyCode: 0
        )!

        handler.handleKeyForTesting(event)
        #expect(receivedNumber == nil)
        #expect(!escapeCalled)
    }
}
