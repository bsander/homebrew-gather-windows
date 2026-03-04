import AppKit
import ApplicationServices

/// Display information for window positioning
struct DisplayInfo {
    let index: Int
    let frame: CGRect
    let isMain: Bool
    let name: String

    var width: CGFloat { frame.width }
    var height: CGFloat { frame.height }
    var x: CGFloat { frame.origin.x }
    var y: CGFloat { frame.origin.y }

    /// Safe area accounting for menu bar and dock margins
    var safeArea: CGRect {
        CGRect(
            x: frame.origin.x + Constants.sideMargin,
            y: frame.origin.y + Constants.topMargin,
            width: frame.width - (Constants.sideMargin * 2),
            height: frame.height - Constants.topMargin - Constants.bottomMargin
        )
    }
}

/// Window information extracted from Accessibility API
struct WindowInfo {
    let element: AXUIElement
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

/// Constants matching JXA implementation
enum Constants {
    /// Top margin for menu bar (MUST match JXA line 379)
    static let topMargin: CGFloat = 80
    /// Side margins (MUST match JXA line 380)
    static let sideMargin: CGFloat = 20
    /// Bottom margin (MUST match JXA line 381)
    static let bottomMargin: CGFloat = 20
    /// Tolerance for position verification (JXA line 317)
    static let verificationMargin: CGFloat = 50
}

/// Command-line options
struct Options {
    var help: Bool = false
    var includeFullscreen: Bool = false
    var verbose: Bool = false
    var hideDuringMove: Bool = false
}
