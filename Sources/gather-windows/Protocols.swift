import AppKit
import ApplicationServices

// MARK: - Protocols

/// Abstracts NSScreen.screens for testability
protocol ScreenProvider: Sendable {
    func screens() -> [(frame: CGRect, isMain: Bool)]
}

/// Abstracts NSWorkspace.shared.runningApplications for testability
protocol WorkspaceProvider: Sendable {
    func regularApplications() -> [(pid: pid_t, name: String)]
}

/// Abstracts all Accessibility API calls for testability.
/// Works at WindowInfo level so AXUIElement never leaks into tests.
protocol AccessibilityProvider: Sendable {
    func isAccessibilityTrusted() -> Bool
    func allWindows(forPID pid: pid_t, processName: String) -> [WindowInfo]
    func moveWindow(_ window: WindowInfo, to bounds: CGRect) -> Bool
    func currentBounds(of window: WindowInfo) -> CGRect?
}

// MARK: - Coordinate Conversion

/// Converts between NSScreen (Cocoa) and CG/AX coordinate systems.
/// Cocoa: origin at bottom-left of primary screen, y increases upward.
/// CG/AX: origin at top-left of primary screen, y increases downward.
enum CoordinateConverter {
    static func cocoaToCG(frame: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        let cgY = primaryScreenHeight - frame.origin.y - frame.height
        return CGRect(x: frame.origin.x, y: cgY, width: frame.width, height: frame.height)
    }
}

// MARK: - Production Conformances

struct SystemScreenProvider: ScreenProvider {
    func screens() -> [(frame: CGRect, isMain: Bool)] {
        let screens = NSScreen.screens
        guard let primary = screens.first else { return [] }
        let primaryHeight = primary.frame.height
        return screens.map { screen in
            let cgFrame = CoordinateConverter.cocoaToCG(
                frame: screen.frame,
                primaryScreenHeight: primaryHeight
            )
            return (cgFrame, screen == primary)
        }
    }
}

struct SystemWorkspaceProvider: WorkspaceProvider {
    func regularApplications() -> [(pid: pid_t, name: String)] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .map { ($0.processIdentifier, $0.localizedName ?? "Unknown") }
    }
}

struct SystemAccessibilityProvider: AccessibilityProvider {
    func isAccessibilityTrusted() -> Bool {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func allWindows(forPID pid: pid_t, processName: String) -> [WindowInfo] {
        let appElement = AXUIElementCreateApplication(pid)

        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsRef
        )

        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            return []
        }

        return windows.compactMap { extractWindowInfo($0, processName: processName) }
    }

    func moveWindow(_ window: WindowInfo, to bounds: CGRect) -> Bool {
        guard let element = window.element else { return false }

        var newSize = bounds.size
        var newPosition = bounds.origin

        guard let sizeValue = AXValueCreate(.cgSize, &newSize),
              let positionValue = AXValueCreate(.cgPoint, &newPosition) else {
            return false
        }

        let sizeResult = AXUIElementSetAttributeValue(
            element,
            kAXSizeAttribute as CFString,
            sizeValue
        )

        let positionResult = AXUIElementSetAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            positionValue
        )

        return sizeResult == .success && positionResult == .success
    }

    func currentBounds(of window: WindowInfo) -> CGRect? {
        guard let element = window.element else { return nil }

        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?

        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)

        var position = CGPoint.zero
        var size = CGSize.zero

        guard let posValue = posRef, let sizeValue = sizeRef else { return nil }
        AXValueGetValue(posValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)

        return CGRect(origin: position, size: size)
    }

    // MARK: - Private

    private func extractWindowInfo(
        _ windowElement: AXUIElement,
        processName: String
    ) -> WindowInfo? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        var titleRef: CFTypeRef?
        var minimizedRef: CFTypeRef?
        var fullscreenRef: CFTypeRef?

        AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionRef)
        AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeRef)
        AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &titleRef)
        AXUIElementCopyAttributeValue(windowElement, kAXMinimizedAttribute as CFString, &minimizedRef)
        let fullscreenAttr = "AXFullScreen" as CFString
        AXUIElementCopyAttributeValue(windowElement, fullscreenAttr, &fullscreenRef)

        var position = CGPoint.zero
        if let positionValue = positionRef {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        } else {
            return nil
        }

        var size = CGSize.zero
        if let sizeValue = sizeRef {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        } else {
            return nil
        }

        let title = (titleRef as? String) ?? "Untitled"
        let isMinimized = (minimizedRef as? Bool) ?? false
        let isFullscreen = (fullscreenRef as? Bool) ?? false
        let bounds = CGRect(origin: position, size: size)

        return WindowInfo(
            element: windowElement,
            processName: processName,
            title: title,
            bounds: bounds,
            isMinimized: isMinimized,
            isFullscreen: isFullscreen
        )
    }
}
