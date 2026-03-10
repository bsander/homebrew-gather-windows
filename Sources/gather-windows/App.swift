import SwiftUI
@preconcurrency import UserNotifications

@main
struct GatherWindowsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible window — overlay windows are managed by AppDelegate
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayWindows: [OverlayWindow] = []
    private var keyboardHandler: KeyboardHandler?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = Array(CommandLine.arguments.dropFirst()) // drop executable path

        if args.isEmpty {
            startOverlayMode()
        } else {
            Task { @MainActor in
                let exitCode = await CLI.run(args)
                NSApp.terminate(nil)
                exit(exitCode)
            }
        }
    }

    @MainActor
    private func startOverlayMode() {
        // Check accessibility permissions before anything else
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options) {
            showNotification(
                title: "Gather Windows",
                body: "Accessibility permission required. Please grant access in System Settings → Privacy & Security → Accessibility, then relaunch."
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
            return
        }

        let displayManager = DisplayManager()
        let displays = displayManager.getAllDisplays()
        let screens = NSScreen.screens

        guard displays.count > 1 else {
            showNotification(
                title: "Gather Windows",
                body: "Only one screen detected."
            )
            // Quit after a short delay to allow notification to post
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
            return
        }

        // Create overlay window for each screen
        for screen in screens {
            // Match screen to display by frame
            let display = displays.first { displaysMatch($0.frame, screen.frame) }
            let number = display?.index ?? 0

            let overlay = OverlayWindow(screen: screen, screenNumber: number)
            overlay.orderFrontRegardless()
            overlayWindows.append(overlay)
        }

        // Make app active so it receives key events
        NSApp.activate(ignoringOtherApps: true)

        // Start keyboard handler
        keyboardHandler = KeyboardHandler(
            maxNumber: displays.count,
            onNumberPressed: { [weak self] number in
                self?.handleScreenSelection(number, displays: displays)
            },
            onEscape: { [weak self] in
                self?.closeOverlaysAndQuit()
            }
        )
        keyboardHandler?.start()
    }

    private func handleScreenSelection(_ number: Int, displays: [DisplayInfo]) {
        guard let targetDisplay = displays.first(where: { $0.index == number }) else { return }

        closeOverlays()

        Task { @MainActor in
            let windowManager = WindowManager()
            let result = await windowManager.moveWindowsToDisplay(
                targetDisplay,
                includeFullscreen: false,
                hideDuringMove: false
            )
            log("Moved \(result.movedCount) window(s) to \(targetDisplay.name)")
            NSApp.terminate(nil)
        }
    }

    private func closeOverlays() {
        keyboardHandler?.stop()
        keyboardHandler = nil
        for window in overlayWindows {
            window.close()
        }
        overlayWindows.removeAll()
    }

    private func closeOverlaysAndQuit() {
        closeOverlays()
        NSApp.terminate(nil)
    }

    private func displaysMatch(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.origin.x - b.origin.x) < 1 &&
        abs(a.origin.y - b.origin.y) < 1 &&
        abs(a.width - b.width) < 1 &&
        abs(a.height - b.height) < 1
    }

    private func showNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            let request = UNNotificationRequest(
                identifier: "gather-windows-info",
                content: content,
                trigger: nil
            )
            center.add(request)
        }
    }
}
