import Foundation
import CoreGraphics

/// Calculates new window bounds for moving to target display
class BoundsCalculator {
    /// Snap tolerance in points for detecting edge-snapped windows
    static let snapTolerance: CGFloat = 10

    /// Calculate new bounds for window moving from source to target display.
    /// Uses uniform scaling (aspect-ratio preserving) with snap-to-edge detection.
    /// Windows are positioned within an aspect-matched sub-region of the target,
    /// centered on the extra axis. Clamps to target safe area.
    static func calculateNewBounds(
        _ windowBounds: CGRect,
        sourceDisplay: DisplayInfo,
        targetDisplay: DisplayInfo
    ) -> CGRect {
        // Uniform scale factor: use the smaller ratio to preserve aspect ratio
        let scaleX = targetDisplay.width / sourceDisplay.width
        let scaleY = targetDisplay.height / sourceDisplay.height
        let scale = min(scaleX, scaleY)

        // Scale window size uniformly
        var newWidth = (windowBounds.width * scale).rounded()
        var newHeight = (windowBounds.height * scale).rounded()

        // Aspect-matched region: source display scaled uniformly, centered in target
        let regionWidth = sourceDisplay.width * scale
        let regionHeight = sourceDisplay.height * scale
        let regionX = targetDisplay.x + ((targetDisplay.width - regionWidth) / 2).rounded()
        let regionY = targetDisplay.y + ((targetDisplay.height - regionHeight) / 2).rounded()

        // Map position within the aspect-matched region
        let offsetX = windowBounds.origin.x - sourceDisplay.x
        let offsetY = windowBounds.origin.y - sourceDisplay.y
        var newX = (regionX + offsetX * scale).rounded()
        var newY = (regionY + offsetY * scale).rounded()

        // Snap-to-edge: if window was flush with a source edge,
        // snap to the corresponding target edge instead of the region edge.
        // Uses source display's visibleFrame insets for detection tolerance
        // and target display's visibleFrame for placement.
        let tol = snapTolerance

        // Detect edge snaps using source display insets
        let sourceTopTol = max(tol, sourceDisplay.topInset + tol)
        let sourceBottomTol = max(tol, sourceDisplay.bottomInset + tol)
        let sourceLeftTol = max(tol, sourceDisplay.leftInset + tol)
        let sourceRightTol = max(tol, sourceDisplay.rightInset + tol)

        let snappedLeft = offsetX <= sourceLeftTol
        let snappedRight = sourceDisplay.width - (offsetX + windowBounds.width) <= sourceRightTol
        let snappedTop = offsetY <= sourceTopTol
        let snappedBottom = sourceDisplay.height - (offsetY + windowBounds.height) <= sourceBottomTol

        // If snapped to ALL four edges (maximized), use proportional scaling only
        if snappedLeft && snappedRight && snappedTop && snappedBottom {
            let unclamped = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
            return clampToSafeArea(unclamped, targetDisplay: targetDisplay)
        }

        // Use target display's real visibleFrame insets for snap placement
        let targetSafe = targetDisplay.visibleFrame

        // Full-span detection: if snapped to opposite edges, fill the target safe area
        if snappedLeft && snappedRight {
            newWidth = targetSafe.width
            newX = targetSafe.origin.x
        } else {
            if snappedLeft { newX = targetSafe.origin.x }
            if snappedRight { newX = targetSafe.origin.x + targetSafe.width - newWidth }
        }

        if snappedTop && snappedBottom {
            newHeight = targetSafe.height
            newY = targetSafe.origin.y
        } else {
            if snappedTop { newY = targetSafe.origin.y }
            if snappedBottom { newY = targetSafe.origin.y + targetSafe.height - newHeight }
        }

        let unclamped = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
        return clampToSafeArea(unclamped, targetDisplay: targetDisplay)
    }

    /// Clamp bounds to the safe area of the target display.
    /// Used both during initial calculation and for post-move correction
    /// when an app enforces a minimum size larger than requested.
    static func clampToSafeArea(_ bounds: CGRect, targetDisplay: DisplayInfo) -> CGRect {
        let safe = targetDisplay.visibleFrame

        let newWidth = min(bounds.width, safe.width)
        let newHeight = min(bounds.height, safe.height)
        var newX = bounds.origin.x
        var newY = bounds.origin.y

        let maxX = safe.origin.x + safe.width
        let maxY = safe.origin.y + safe.height

        if newX + newWidth > maxX {
            newX = maxX - newWidth
        }
        if newY + newHeight > maxY {
            newY = maxY - newHeight
        }
        if newX < safe.origin.x {
            newX = safe.origin.x
        }
        if newY < safe.origin.y {
            newY = safe.origin.y
        }

        return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }
}
