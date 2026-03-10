import AppKit

/// Monitors keyboard events for overlay mode
class KeyboardHandler {
    private var monitor: Any?
    private let onNumberPressed: (Int) -> Void
    private let onEscape: () -> Void
    private let maxNumber: Int

    init(maxNumber: Int, onNumberPressed: @escaping (Int) -> Void, onEscape: @escaping () -> Void) {
        self.maxNumber = maxNumber
        self.onNumberPressed = onNumberPressed
        self.onEscape = onEscape
    }

    func start() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKey(event)
            return nil // consume the event
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    /// Exposed for testing — same as handleKey
    func handleKeyForTesting(_ event: NSEvent) {
        handleKey(event)
    }

    private func handleKey(_ event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onEscape()
            return
        }

        // Number keys: characters "1"-"9"
        guard let chars = event.characters,
              let number = Int(chars),
              number >= 1,
              number <= maxNumber else {
            return // invalid key — ignore
        }

        onNumberPressed(number)
    }
}
