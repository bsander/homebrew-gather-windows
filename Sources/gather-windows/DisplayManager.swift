import AppKit

/// Manages display detection and window positioning relative to displays
struct DisplayManager {
    let screenProvider: ScreenProvider

    init(screenProvider: ScreenProvider = SystemScreenProvider()) {
        self.screenProvider = screenProvider
    }

    /// Get all displays with stable numbering: main=1, others sorted left-to-right
    func getAllDisplays() -> [DisplayInfo] {
        ScreenNumbering.assignNumbers(screenProvider.screens())
    }

    /// Find display by its assigned number (1-based). Returns nil if out of range.
    func displayForNumber(_ number: Int) -> DisplayInfo? {
        let displays = getAllDisplays()
        return displays.first { $0.index == number }
    }

    /// Find the built-in display (JXA lines 136-145)
    /// The primary screen (menu bar) is typically the built-in display on MacBooks
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
