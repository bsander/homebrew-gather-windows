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

@MainActor
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

    private func startOverlayMode() {
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

        // Check accessibility before showing overlays (without prompting)
        let accessibility = SystemAccessibilityProvider()
        if !accessibility.checkAccessibility(prompt: false) {
            // Not trusted — show the System Settings dialog once, then exit
            _ = accessibility.checkAccessibility(prompt: true)
            showNotification(
                title: "Gather Windows",
                body: "Accessibility permission required. Please grant access in System Settings > Privacy & Security > Accessibility, then relaunch."
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
            return
        }

        let primaryHeight = screens.first?.frame.height ?? 0

        // Create overlay window for each screen
        for screen in screens {
            let display = CoordinateConverter.matchScreenToDisplay(
                screenFrame: screen.frame,
                displays: displays,
                primaryScreenHeight: primaryHeight
            )
            let number = display?.index ?? 0

            let overlay = OverlayWindow(screen: screen, screenNumber: number)
            overlay.orderFrontRegardless()
            overlayWindows.append(overlay)
        }

        // Switch to .regular so the app can receive keyboard focus.
        // Reverted to .accessory in closeOverlays() to hide the Dock icon.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        overlayWindows.first?.makeKeyAndOrderFront(nil)

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

        // Defer to next run loop iteration so the NSEvent monitor callback
        // returns cleanly before we remove it — removing a monitor from
        // within its own callback causes a SIGSEGV.
        DispatchQueue.main.async { [weak self] in
            self?.closeOverlays()

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
    }

    private func closeOverlays() {
        keyboardHandler?.stop()
        keyboardHandler = nil
        for window in overlayWindows {
            window.close()
        }
        overlayWindows.removeAll()
        NSApp.setActivationPolicy(.accessory)
    }

    private func closeOverlaysAndQuit() {
        // Also defer for the same reason — Escape is handled by the same monitor
        DispatchQueue.main.async { [weak self] in
            self?.closeOverlays()
            NSApp.terminate(nil)
        }
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
