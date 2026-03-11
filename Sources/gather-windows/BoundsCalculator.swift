import Foundation
import CoreGraphics

/// Calculates new window bounds for moving to target display
class BoundsCalculator {
    /// Calculate new bounds for window moving from source to target display.
    /// Maps the window's relative position and size proportionally.
    /// Clamps to target safe area so windows never end up off-screen.
    static func calculateNewBounds(
        _ windowBounds: CGRect,
        sourceDisplay: DisplayInfo,
        targetDisplay: DisplayInfo
    ) -> CGRect {
        // Compute relative position and size against source display frame
        let relX = (windowBounds.origin.x - sourceDisplay.x) / sourceDisplay.width
        let relY = (windowBounds.origin.y - sourceDisplay.y) / sourceDisplay.height
        let relW = windowBounds.width / sourceDisplay.width
        let relH = windowBounds.height / sourceDisplay.height

        // Map to target display frame
        var newX = targetDisplay.x + relX * targetDisplay.width
        var newY = targetDisplay.y + relY * targetDisplay.height
        var newWidth = relW * targetDisplay.width
        var newHeight = relH * targetDisplay.height

        // Round all values (accessibility API needs integers)
        newX = newX.rounded()
        newY = newY.rounded()
        newWidth = newWidth.rounded()
        newHeight = newHeight.rounded()

        let unclamped = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
        return clampToSafeArea(unclamped, targetDisplay: targetDisplay)
    }

    /// Clamp bounds to the safe area of the target display.
    /// Used both during initial calculation and for post-move correction
    /// when an app enforces a minimum size larger than requested.
    static func clampToSafeArea(_ bounds: CGRect, targetDisplay: DisplayInfo) -> CGRect {
        let topMargin = Constants.topMargin
        let sideMargin = Constants.sideMargin
        let bottomMargin = Constants.bottomMargin

        let safeWidth = targetDisplay.width - (sideMargin * 2)
        let safeHeight = targetDisplay.height - topMargin - bottomMargin

        let newWidth = min(bounds.width, safeWidth)
        let newHeight = min(bounds.height, safeHeight)
        var newX = bounds.origin.x
        var newY = bounds.origin.y

        let maxX = targetDisplay.x + targetDisplay.width - sideMargin
        let maxY = targetDisplay.y + targetDisplay.height - bottomMargin

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

        return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }
}
