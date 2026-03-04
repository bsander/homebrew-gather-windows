import Foundation
import CoreGraphics

/// Calculates new window bounds for moving to target display
/// CRITICAL: This implements JXA lines 377-433 EXACTLY
class BoundsCalculator {
    /// Calculate new bounds for window moving to target display
    /// Preserves aspect ratio, centers window, and clamps to safe area
    /// JXA lines 377-433
    static func calculateNewBounds(
        _ windowBounds: CGRect,
        _ targetDisplay: DisplayInfo
    ) -> CGRect {
        // Account for macOS menu bar (typically ~25px) and dock
        // Lines 379-381 - MUST match JXA exactly
        let topMargin = Constants.topMargin      // 80 - Extra space for menu bar
        let sideMargin = Constants.sideMargin    // 20 - Smaller side margins
        let bottomMargin = Constants.bottomMargin // 20

        var newWidth = windowBounds.width
        var newHeight = windowBounds.height

        // Calculate safe area within target display (lines 387-392)
        let safeArea = CGRect(
            x: targetDisplay.x + sideMargin,
            y: targetDisplay.y + topMargin,  // Account for menu bar
            width: targetDisplay.width - (sideMargin * 2),
            height: targetDisplay.height - topMargin - bottomMargin
        )

        // Resize if window is too large, maintaining aspect ratio (lines 395-402)
        if newWidth > safeArea.width || newHeight > safeArea.height {
            // Calculate scale to fit, preserving aspect ratio
            let scaleWidth = safeArea.width / newWidth
            let scaleHeight = safeArea.height / newHeight
            let scale = min(scaleWidth, scaleHeight)

            newWidth = floor(windowBounds.width * scale)
            newHeight = floor(windowBounds.height * scale)
        }

        // Calculate position - center in safe area (lines 405-407)
        var newX = safeArea.origin.x + floor((safeArea.width - newWidth) / 2)
        var newY = safeArea.origin.y + floor((safeArea.height - newHeight) / 2)

        // Final safety check - ensure completely within bounds (lines 410-411)
        let maxX = targetDisplay.x + targetDisplay.width - sideMargin
        let maxY = targetDisplay.y + targetDisplay.height - bottomMargin

        // Clamp to safe bounds (lines 414-425)
        if newX + newWidth > maxX {
            newX = maxX - newWidth
        }
        if newY + newHeight > maxY {
            newY = maxY - newHeight
        }
        if newX < targetDisplay.x + sideMargin {
            newX = targetDisplay.x + sideMargin
        }
        if newY < targetDisplay.y + topMargin {
            newY = targetDisplay.y + topMargin
        }

        // Return rounded values (lines 427-432)
        return CGRect(
            x: newX.rounded(),
            y: newY.rounded(),
            width: newWidth.rounded(),
            height: newHeight.rounded()
        )
    }
}
