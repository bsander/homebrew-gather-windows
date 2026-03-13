import Testing
import CoreGraphics
@testable import gather_windows

@Suite("BoundsCalculator")
struct BoundsCalculatorTests {
    // Same aspect ratio displays (1.6:1) — visibleFrame = frame (no insets)
    let builtIn = makeDisplay(frame: CGRect(x: 0, y: 0, width: 1440, height: 900))
    let external = makeDisplay(index: 2, frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080), isMain: false, name: "External")

    // Different aspect ratio displays (user's real setup) with realistic visibleFrames
    let mainDisplay = makeDisplay(
        frame: CGRect(x: 0, y: 0, width: 1800, height: 1169),
        visibleFrame: CGRect(x: 0, y: 38, width: 1800, height: 1131)
    )
    let wideDisplay = makeDisplay(
        index: 2,
        frame: CGRect(x: -1089, y: -1600, width: 3840, height: 1600),
        visibleFrame: CGRect(x: -1089, y: -1562, width: 3840, height: 1562),
        isMain: false, name: "Wide"
    )

    // MARK: - Uniform scaling (aspect-ratio preserving)

    @Test func uniformScale_preservesWindowAspectRatio() {
        let window = CGRect(x: 225, y: 40, width: 1350, height: 1129)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        #expect(result.width < 2000)
    }

    @Test func uniformScale_sameAspectRatio_matchesProportional() {
        let large = makeDisplay(index: 2, frame: CGRect(x: 1440, y: 0, width: 2880, height: 1800), isMain: false, name: "Large")
        let window = CGRect(x: 200, y: 200, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: builtIn, targetDisplay: large)

        #expect(result.width == 800)
        #expect(result.height == 600)
    }

    @Test func uniformScale_widthConstrained() {
        let window = CGRect(x: 1440 + 200, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        #expect(result.width == 300)  // 400 * 0.75
        #expect(result.height == 225) // 300 * 0.75
    }

    @Test func uniformScale_heightConstrained() {
        let window = CGRect(x: 200, y: 200, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        let scale = min(wideDisplay.width / mainDisplay.width, wideDisplay.height / mainDisplay.height)
        let expectedW = (400.0 * scale).rounded()
        let expectedH = (300.0 * scale).rounded()
        #expect(result.width == expectedW)
        #expect(result.height == expectedH)
    }

    // MARK: - Aspect-matched region positioning

    @Test func position_centeredInAspectMatchedRegion() {
        let window = CGRect(x: 200, y: 200, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        let targetCenter = wideDisplay.x + wideDisplay.width / 2
        #expect(result.origin.x > wideDisplay.x + 500)
        #expect(result.origin.x < targetCenter)
    }

    @Test func sameSourceAndTarget_preservesPosition() {
        let window = CGRect(x: 200, y: 200, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: builtIn, targetDisplay: builtIn)

        #expect(result.origin.x == 200)
        #expect(result.origin.y == 200)
        #expect(result.width == 400)
        #expect(result.height == 300)
    }

    // MARK: - Snap-to-edge detection

    @Test func snappedToLeftEdge_staysOnLeftEdge() {
        let window = CGRect(x: 0, y: 200, width: 800, height: 600)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        #expect(result.origin.x == wideDisplay.visibleFrame.origin.x)
    }

    @Test func snappedToRightEdge_staysOnRightEdge() {
        let window = CGRect(x: 1000, y: 200, width: 800, height: 600)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        let maxX = wideDisplay.visibleFrame.origin.x + wideDisplay.visibleFrame.width
        #expect(result.origin.x + result.width == maxX)
    }

    @Test func snappedToTopEdge_staysOnTopEdge() {
        let window = CGRect(x: 200, y: 0, width: 800, height: 600)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        #expect(result.origin.y == wideDisplay.visibleFrame.origin.y)
    }

    @Test func snappedToBottomEdge_staysOnBottomEdge() {
        let window = CGRect(x: 200, y: 569, width: 800, height: 600)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        let maxY = wideDisplay.visibleFrame.origin.y + wideDisplay.visibleFrame.height
        #expect(result.origin.y + result.height == maxY)
    }

    @Test func notSnapped_positionedInRegion() {
        let window = CGRect(x: 200, y: 200, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        #expect(result.origin.x > wideDisplay.visibleFrame.origin.x + 100)
        let maxX = wideDisplay.visibleFrame.origin.x + wideDisplay.visibleFrame.width
        #expect(result.origin.x + result.width < maxX - 100)
    }

    @Test func snappedLeftAndTop_cornerSnap() {
        let window = CGRect(x: 0, y: 0, width: 800, height: 600)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        #expect(result.origin.x == wideDisplay.visibleFrame.origin.x)
        #expect(result.origin.y == wideDisplay.visibleFrame.origin.y)
    }

    @Test func fullHeight_fillsTargetSafeHeight() {
        // Window spanning full height of source (menu bar to bottom edge)
        // y=40 is within source topInset (38) + tolerance, bottom gap = 0
        // NOT all 4 edges (left offset = 200, not snapped)
        let window = CGRect(x: 200, y: 40, width: 800, height: 1129)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        #expect(result.height == wideDisplay.visibleFrame.height)
        #expect(result.origin.y == wideDisplay.visibleFrame.origin.y)
    }

    @Test func fullWidth_fillsTargetSafeWidth() {
        // Window spanning full width of source (not top/bottom snapped)
        let window = CGRect(x: 0, y: 200, width: 1800, height: 600)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        #expect(result.width == wideDisplay.visibleFrame.width)
        #expect(result.origin.x == wideDisplay.visibleFrame.origin.x)
    }

    @Test func maximized_usesProportionalScaling() {
        // Window snapped to all 4 edges (maximized) should NOT fill target safe area
        // Instead uses proportional scaling like a regular window
        let window = CGRect(x: 0, y: 38, width: 1800, height: 1131)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: mainDisplay, targetDisplay: wideDisplay)

        // Should NOT fill target safe area
        #expect(result.width < wideDisplay.visibleFrame.width)
        // Should be uniformly scaled
        let scale = min(wideDisplay.width / mainDisplay.width, wideDisplay.height / mainDisplay.height)
        let expectedW = (1800.0 * scale).rounded()
        let expectedH = (1131.0 * scale).rounded()
        #expect(result.width == expectedW)
        #expect(result.height == expectedH)
    }

    // MARK: - Clamping to safe area

    @Test func windowTooWide_clampedToSafeArea() {
        let window = CGRect(x: 1440 + 10, y: 100, width: 1900, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        #expect(result.width <= builtIn.visibleFrame.width)
    }

    @Test func windowTooTall_clampedToSafeArea() {
        let window = CGRect(x: 1440 + 100, y: 10, width: 400, height: 1070)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        #expect(result.height <= builtIn.visibleFrame.height)
    }

    @Test func windowPosition_clampedWithinSafeArea() {
        let window = CGRect(x: 1440 + 1500, y: 800, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        let safe = builtIn.visibleFrame
        #expect(result.origin.x + result.width <= safe.origin.x + safe.width)
        #expect(result.origin.y + result.height <= safe.origin.y + safe.height)
        #expect(result.origin.x >= safe.origin.x)
        #expect(result.origin.y >= safe.origin.y)
    }

    // MARK: - Different display configurations

    @Test func targetDisplayWithNegativeOrigin_boundsOffsetCorrectly() {
        let leftDisplay = makeDisplay(frame: CGRect(x: -1920, y: 0, width: 1920, height: 1080))
        let window = CGRect(x: 500, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: builtIn, targetDisplay: leftDisplay)

        #expect(result.origin.x >= -1920)
        #expect(result.origin.x + result.width <= 0)
    }

    @Test func targetDisplayWithPositiveOrigin_boundsOffsetCorrectly() {
        let rightDisplay = makeDisplay(frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080))
        let window = CGRect(x: 100, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: builtIn, targetDisplay: rightDisplay)

        #expect(result.origin.x >= 1440)
    }

    @Test func targetDisplayWithNegativeY_boundsPositionedCorrectly() {
        let display = makeDisplay(frame: CGRect(x: 1440, y: -180, width: 1920, height: 1080))
        let window = CGRect(x: 100, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: builtIn, targetDisplay: display)

        #expect(result.origin.y >= -180)
    }

    // MARK: - Scaling direction

    @Test func smallToLargeDisplay_windowScalesUp() {
        let window = CGRect(x: 200, y: 200, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: builtIn, targetDisplay: external)

        #expect(result.width > 400)
        #expect(result.height > 300)
    }

    @Test func largeToSmallDisplay_windowScalesDown() {
        let window = CGRect(x: 1440 + 200, y: 200, width: 800, height: 600)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        #expect(result.width < 800)
        #expect(result.height < 600)
    }

    // MARK: - Rounding

    @Test func resultValues_areRounded() {
        let display = makeDisplay(frame: CGRect(x: 0, y: 0, width: 1441, height: 901))
        let window = CGRect(x: 1440 + 300, y: 200, width: 300, height: 200)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: display)

        #expect(result.origin.x == result.origin.x.rounded())
        #expect(result.origin.y == result.origin.y.rounded())
        #expect(result.width == result.width.rounded())
        #expect(result.height == result.height.rounded())
    }

    // MARK: - clampToSafeArea

    @Test func clampToSafeArea_windowWithinBounds_unchanged() {
        let bounds = CGRect(x: 100, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.clampToSafeArea(bounds, targetDisplay: builtIn)
        #expect(result == bounds)
    }

    @Test func clampToSafeArea_windowExceedsRightEdge_positionShifted() {
        let bounds = CGRect(x: 900, y: 100, width: 600, height: 300)
        let result = BoundsCalculator.clampToSafeArea(bounds, targetDisplay: builtIn)
        let maxX = builtIn.visibleFrame.origin.x + builtIn.visibleFrame.width
        #expect(result.origin.x + result.width <= maxX)
        #expect(result.width == 600)
    }

    @Test func clampToSafeArea_windowExceedsBottomEdge_positionShifted() {
        let bounds = CGRect(x: 100, y: 600, width: 400, height: 400)
        let result = BoundsCalculator.clampToSafeArea(bounds, targetDisplay: builtIn)
        let maxY = builtIn.visibleFrame.origin.y + builtIn.visibleFrame.height
        #expect(result.origin.y + result.height <= maxY)
    }

    @Test func clampToSafeArea_windowTooWide_sizeAndPositionClamped() {
        let bounds = CGRect(x: 100, y: 100, width: 1500, height: 300)
        let result = BoundsCalculator.clampToSafeArea(bounds, targetDisplay: builtIn)
        #expect(result.width == builtIn.visibleFrame.width)
        #expect(result.origin.x >= builtIn.visibleFrame.origin.x)
    }

    // MARK: - Edge cases

    @Test func zeroSizeWindow_returnsZeroSize() {
        let window = CGRect(x: 1440 + 100, y: 100, width: 0, height: 0)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        #expect(result.width == 0)
        #expect(result.height == 0)
    }

    @Test func windowExactlySafeAreaSize_clampedCorrectly() {
        let window = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        #expect(result.width <= builtIn.visibleFrame.width)
        #expect(result.height <= builtIn.visibleFrame.height)
    }

    // MARK: - Real-world snap with visibleFrame insets

    @Test func calendarSnap_topRightBottom_noArtificialMargins() {
        // Calendar on source: snapped top+right+bottom (not left)
        // Source: external display 1800x1169, menu bar at 38px
        let source = makeDisplay(
            frame: CGRect(x: 0, y: 0, width: 1800, height: 1169),
            visibleFrame: CGRect(x: 0, y: 38, width: 1800, height: 1131)
        )
        // Target: built-in 3840x1600, menu bar at 38px
        let target = makeDisplay(
            index: 2,
            frame: CGRect(x: -1089, y: -1600, width: 3840, height: 1600),
            visibleFrame: CGRect(x: -1089, y: -1562, width: 3840, height: 1562),
            isMain: false, name: "Built-in"
        )
        let calendar = CGRect(x: 675, y: 40, width: 1125, height: 1129)
        let result = BoundsCalculator.calculateNewBounds(calendar, sourceDisplay: source, targetDisplay: target)

        // Should snap to target's actual right edge (no artificial 20px margin)
        let targetRight = target.visibleFrame.origin.x + target.visibleFrame.width
        #expect(result.origin.x + result.width == targetRight)
        // Should snap to target's actual top (visibleFrame top, not frame top - 80)
        #expect(result.origin.y == target.visibleFrame.origin.y)
        // Should snap to target's actual bottom
        let targetBottom = target.visibleFrame.origin.y + target.visibleFrame.height
        #expect(result.origin.y + result.height == targetBottom)
    }

    @Test func fastmailMaximized_proportionalNotFillTarget() {
        // Fastmail on source: snapped all 4 edges (maximized)
        let source = makeDisplay(
            frame: CGRect(x: 0, y: 0, width: 1800, height: 1169),
            visibleFrame: CGRect(x: 0, y: 38, width: 1800, height: 1131)
        )
        let target = makeDisplay(
            index: 2,
            frame: CGRect(x: -1089, y: -1600, width: 3840, height: 1600),
            visibleFrame: CGRect(x: -1089, y: -1562, width: 3840, height: 1562),
            isMain: false, name: "Built-in"
        )
        let fastmail = CGRect(x: 0, y: 38, width: 1800, height: 1131)
        let result = BoundsCalculator.calculateNewBounds(fastmail, sourceDisplay: source, targetDisplay: target)

        // Should NOT fill entire target safe area (3840x1562)
        #expect(result.width < target.visibleFrame.width)
        // Should be proportionally scaled
        let scale = min(target.width / source.width, target.height / source.height)
        let expectedW = (1800.0 * scale).rounded()
        #expect(result.width == expectedW)
    }
}
