import AppKit

/// Monitors keyboard events for overlay mode
class KeyboardHandler {
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private let onNumberPressed: (Int) -> Void
    private let onEscape: () -> Void
    private let maxNumber: Int

    init(maxNumber: Int, onNumberPressed: @escaping (Int) -> Void, onEscape: @escaping () -> Void) {
        self.maxNumber = maxNumber
        self.onNumberPressed = onNumberPressed
        self.onEscape = onEscape
    }

    func start() {
        // Local monitor: fires when app is active, can consume events
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKey(event)
            return nil // consume the event
        }
        // Global monitor: fires when app is NOT active (fallback)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKey(event)
        }
    }

    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        localMonitor = nil
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        globalMonitor = nil
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
