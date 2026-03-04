import AppKit
import ApplicationServices

/// Manages window enumeration and movement using Accessibility API
class WindowManager {
    /// Move windows to target display (JXA lines 168-290)
    @MainActor
    static func moveWindowsToDisplay(
        _ targetDisplay: DisplayInfo,
        includeFullscreen: Bool,
        hideDuringMove: Bool
    ) async -> MoveResult {
        // Check Accessibility permissions
        guard checkAccessibilityPermissions() else {
            log("Error: Accessibility permissions required")
            log("Please grant Accessibility access in System Settings > Privacy & Security > Accessibility")
            exit(1)
        }

        // Get all running applications
        let runningApps = NSWorkspace.shared.runningApplications

        // Collect all windows to move
        var windowsToMove: [WindowMove] = []

        logVerbose("Collecting windows to move:")

        for app in runningApps {
            // Skip background-only apps
            guard app.activationPolicy == .regular else { continue }

            let processName = app.localizedName ?? "Unknown"
            let pid = app.processIdentifier

            // Get app's accessibility element
            let appElement = AXUIElementCreateApplication(pid)

            // Get windows for this app
            guard let windows = getWindows(for: appElement) else { continue }

            for windowElement in windows {
                // Extract window info with batch queries
                guard let windowInfo = extractWindowInfo(
                    windowElement,
                    processName: processName
                ) else { continue }

                // Skip minimized windows (JXA lines 192-194)
                if windowInfo.isMinimized {
                    continue
                }

                // Check if fullscreen (JXA lines 197-200)
                if windowInfo.isFullscreen && !includeFullscreen {
                    continue
                }

                // Check if window is on external display (JXA lines 214)
                if DisplayManager.isOnExternalDisplay(windowInfo.bounds, targetDisplay) {
                    let displayLocation = getDisplayLocation(windowInfo.bounds, targetDisplay)
                    let newBounds = BoundsCalculator.calculateNewBounds(
                        windowInfo.bounds,
                        targetDisplay
                    )

                    windowsToMove.append(WindowMove(
                        window: windowInfo,
                        beforeBounds: windowInfo.bounds,
                        newBounds: newBounds,
                        displayLocation: displayLocation
                    ))

                    logVerbose("  [\(processName)] \"\(windowInfo.title)\"")
                    logVerbose("    Current: \(formatBounds(windowInfo.bounds)) \(displayLocation)")
                    logVerbose("    Target:  \(formatBounds(newBounds))")
                    logVerbose("")
                }
            }
        }

        // Move all windows (JXA lines 247-280)
        logVerbose("Moving windows:")

        // For now, use sequential execution to avoid concurrency complexity
        // TODO: Implement parallel execution once Sendable conformance is added
        var movedCount = 0
        var verifiedCount = 0
        let verbose = VERBOSE

        for move in windowsToMove {
            let result = moveWindow(move, targetDisplay: targetDisplay, hideDuringMove: hideDuringMove, verbose: verbose)
            if result.moved {
                movedCount += 1
            }
            if result.verified {
                verifiedCount += 1
            }
        }

        // If not in verbose mode, assume all moves succeeded (JXA lines 283-285)
        if !verbose {
            verifiedCount = movedCount
        }

        return MoveResult(movedCount: movedCount, verifiedCount: verifiedCount)
    }

    /// Check if Accessibility permissions are granted
    private static func checkAccessibilityPermissions() -> Bool {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Get windows for an application element
    private static func getWindows(for appElement: AXUIElement) -> [AXUIElement]? {
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsRef
        )

        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            return nil
        }

        return windows
    }

    /// Extract window info with batch property queries
    /// PERFORMANCE CRITICAL: Minimizes API round-trips
    private static func extractWindowInfo(
        _ windowElement: AXUIElement,
        processName: String
    ) -> WindowInfo? {
        // Batch query all properties at once
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        var titleRef: CFTypeRef?
        var minimizedRef: CFTypeRef?
        var fullscreenRef: CFTypeRef?

        AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionRef)
        AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeRef)
        AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &titleRef)
        AXUIElementCopyAttributeValue(windowElement, kAXMinimizedAttribute as CFString, &minimizedRef)
        // Fullscreen attribute may not exist on all systems, fall back to heuristic
        let fullscreenAttr = "AXFullScreen" as CFString
        AXUIElementCopyAttributeValue(windowElement, fullscreenAttr, &fullscreenRef)

        // Extract position
        var position = CGPoint.zero
        if let positionValue = positionRef {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        } else {
            return nil
        }

        // Extract size
        var size = CGSize.zero
        if let sizeValue = sizeRef {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        } else {
            return nil
        }

        // Extract title
        let title = (titleRef as? String) ?? "Untitled"

        // Extract minimized state
        let isMinimized = (minimizedRef as? Bool) ?? false

        // Extract fullscreen state using native API (better than JXA heuristic)
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

    /// Move a single window (JXA lines 252-279)
    private static func moveWindow(
        _ move: WindowMove,
        targetDisplay: DisplayInfo,
        hideDuringMove: Bool,
        verbose: Bool
    ) -> (moved: Bool, verified: Bool) {
        let windowElement = move.window.element

        // Set size first, then position - helps with some window managers (JXA line 254-255)
        var newSize = move.newBounds.size
        var newPosition = move.newBounds.origin

        let sizeValue = AXValueCreate(.cgSize, &newSize)!
        let positionValue = AXValueCreate(.cgPoint, &newPosition)!

        // Move window
        let sizeResult = AXUIElementSetAttributeValue(
            windowElement,
            kAXSizeAttribute as CFString,
            sizeValue
        )

        let positionResult = AXUIElementSetAttributeValue(
            windowElement,
            kAXPositionAttribute as CFString,
            positionValue
        )

        guard sizeResult == .success && positionResult == .success else {
            // Can't log from non-main actor context
            return (moved: false, verified: false)
        }

        // Verify in verbose mode (JXA lines 259-276)
        if verbose {
            // Re-query position and size
            var afterPosRef: CFTypeRef?
            var afterSizeRef: CFTypeRef?

            AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &afterPosRef)
            AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &afterSizeRef)

            var afterPos = CGPoint.zero
            var afterSize = CGSize.zero

            if let posRef = afterPosRef {
                AXValueGetValue(posRef as! AXValue, .cgPoint, &afterPos)
            }
            if let sizeRef = afterSizeRef {
                AXValueGetValue(sizeRef as! AXValue, .cgSize, &afterSize)
            }

            let afterBounds = CGRect(origin: afterPos, size: afterSize)
            let verified = DisplayManager.isWithinDisplay(afterBounds, targetDisplay)

            // Can't log from non-main actor context - verification still works
            return (moved: true, verified: verified)
        }

        return (moved: true, verified: true)
    }
}
