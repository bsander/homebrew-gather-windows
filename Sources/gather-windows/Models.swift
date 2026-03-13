import AppKit
import ApplicationServices

/// Display information for window positioning
struct DisplayInfo {
    let index: Int
    let frame: CGRect
    let visibleFrame: CGRect
    let isMain: Bool
    let name: String

    var width: CGFloat { frame.width }
    var height: CGFloat { frame.height }
    var x: CGFloat { frame.origin.x }
    var y: CGFloat { frame.origin.y }

    /// Real safe area from NSScreen.visibleFrame (accounts for menu bar, dock, notch)
    var safeArea: CGRect { visibleFrame }

    /// Insets derived from visibleFrame relative to frame
    var topInset: CGFloat { visibleFrame.origin.y - frame.origin.y }
    var leftInset: CGFloat { visibleFrame.origin.x - frame.origin.x }
    var rightInset: CGFloat { (frame.origin.x + frame.width) - (visibleFrame.origin.x + visibleFrame.width) }
    var bottomInset: CGFloat { (frame.origin.y + frame.height) - (visibleFrame.origin.y + visibleFrame.height) }
}

/// Window information extracted from Accessibility API
struct WindowInfo {
    let element: AXUIElement?
    let processName: String
    let title: String
    let bounds: CGRect
    let isMinimized: Bool
    let isFullscreen: Bool
}

/// Window move operation
struct WindowMove {
    let window: WindowInfo
    let beforeBounds: CGRect
    let newBounds: CGRect
    let displayLocation: String
}

/// Result of window movement operation
struct MoveResult {
    let movedCount: Int
    let verifiedCount: Int
}

enum Constants {
    /// Tolerance for position verification (JXA line 317)
    static let verificationMargin: CGFloat = 50
}

