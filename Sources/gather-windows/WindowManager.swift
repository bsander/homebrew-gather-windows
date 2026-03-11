import AppKit
import ApplicationServices

/// Manages window enumeration and movement using Accessibility API
struct WindowManager {
    let workspace: WorkspaceProvider
    let accessibility: AccessibilityProvider

    init(
        workspace: WorkspaceProvider = SystemWorkspaceProvider(),
        accessibility: AccessibilityProvider = SystemAccessibilityProvider()
    ) {
        self.workspace = workspace
        self.accessibility = accessibility
    }

    /// Move windows to target display (JXA lines 168-290)
    @MainActor
    func moveWindowsToDisplay(
        _ targetDisplay: DisplayInfo,
        allDisplays: [DisplayInfo],
        includeFullscreen: Bool,
        hideDuringMove: Bool
    ) async -> MoveResult {
        // Check Accessibility permissions
        guard accessibility.isAccessibilityTrusted() else {
            log("Error: Accessibility permissions required")
            log("Please grant Accessibility access in System Settings > Privacy & Security > Accessibility")
            return MoveResult(movedCount: 0, verifiedCount: 0)
        }

        // Get all running applications
        let apps = workspace.regularApplications()

        // Collect all windows to move
        var windowsToMove: [WindowMove] = []

        logVerbose("Collecting windows to move:")

        for app in apps {
            let windows = accessibility.allWindows(forPID: app.pid, processName: app.name)

            for windowInfo in windows {
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
                    let sourceDisplay = DisplayManager.displayContaining(windowInfo.bounds, allDisplays: allDisplays) ?? targetDisplay
                    let newBounds = BoundsCalculator.calculateNewBounds(
                        windowInfo.bounds,
                        sourceDisplay: sourceDisplay,
                        targetDisplay: targetDisplay
                    )

                    windowsToMove.append(WindowMove(
                        window: windowInfo,
                        beforeBounds: windowInfo.bounds,
                        newBounds: newBounds,
                        displayLocation: displayLocation
                    ))

                    logVerbose("  [\(app.name)] \"\(windowInfo.title)\"")
                    logVerbose("    Current: \(formatBounds(windowInfo.bounds)) \(displayLocation)")
                    logVerbose("    Target:  \(formatBounds(newBounds))")
                    logVerbose("")
                }
            }
        }

        // Move all windows (JXA lines 247-280)
        logVerbose("Moving windows:")

        var movedCount = 0
        var verifiedCount = 0
        let verbose = VERBOSE

        for move in windowsToMove {
            let moved = accessibility.moveWindow(move.window, to: move.newBounds)
            if moved {
                movedCount += 1

                if verbose {
                    if let afterBounds = accessibility.currentBounds(of: move.window) {
                        if DisplayManager.isWithinDisplay(afterBounds, targetDisplay) {
                            verifiedCount += 1
                        }
                    }
                }
            }
        }

        // If not in verbose mode, assume all moves succeeded (JXA lines 283-285)
        if !verbose {
            verifiedCount = movedCount
        }

        return MoveResult(movedCount: movedCount, verifiedCount: verifiedCount)
    }
}
