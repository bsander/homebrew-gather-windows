import AppKit

/// Manages display detection and window positioning relative to displays
class DisplayManager {
    /// Get all displays (JXA lines 112-133)
    static func getAllDisplays() -> [DisplayInfo] {
        let screens = NSScreen.screens
        var displays: [DisplayInfo] = []

        for (index, screen) in screens.enumerated() {
            let frame = screen.frame
            let isMain = screen == NSScreen.main

            displays.append(DisplayInfo(
                index: index + 1,
                frame: frame,
                isMain: isMain,
                name: isMain ? "Main Display" : "Display \(index + 1)"
            ))
        }

        return displays
    }

    /// Find the built-in display (JXA lines 136-145)
    /// The main screen is typically the built-in display on MacBooks
    static func findBuiltInDisplay(_ allDisplays: [DisplayInfo]) -> DisplayInfo? {
        // First try to find the main display
        for display in allDisplays {
            if display.isMain {
                return display
            }
        }

        // Fallback to first display
        return allDisplays.first
    }

    /// Check if window is on external display (JXA lines 353-374)
    /// A window is external if it's NOT fully within the built-in display
    static func isOnExternalDisplay(_ windowBounds: CGRect, _ builtInDisplay: DisplayInfo) -> Bool {
        let windowRight = windowBounds.origin.x + windowBounds.width
        let windowBottom = windowBounds.origin.y + windowBounds.height

        let builtInMinX = builtInDisplay.x
        let builtInMaxX = builtInDisplay.x + builtInDisplay.width
        let builtInMinY = builtInDisplay.y
        let builtInMaxY = builtInDisplay.y + builtInDisplay.height

        // If the window is fully within the built-in display, it's not external
        let fullyWithin = (
            windowBounds.origin.x >= builtInMinX &&
            windowBounds.origin.y >= builtInMinY &&
            windowRight <= builtInMaxX &&
            windowBottom <= builtInMaxY
        )

        // If not fully within built-in, it's on external (or spanning)
        return !fullyWithin
    }

    /// Check if window is within display bounds (JXA lines 316-328)
    static func isWithinDisplay(_ bounds: CGRect, _ display: DisplayInfo) -> Bool {
        let margin = Constants.verificationMargin
        let right = bounds.origin.x + bounds.width
        let bottom = bounds.origin.y + bounds.height

        // Check that the window is mostly within the display
        // macOS may adjust positions slightly for menu bar, dock, etc.
        let withinX = bounds.origin.x >= display.x - margin && bounds.origin.x < display.x + display.width
        let withinY = bounds.origin.y >= display.y - margin && bounds.origin.y < display.y + display.height
        let rightWithin = right > display.x && right <= display.x + display.width + margin
        let bottomWithin = bottom > display.y && bottom <= display.y + display.height + margin

        return withinX && withinY && rightWithin && bottomWithin
    }
}
