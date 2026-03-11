import Testing
import CoreGraphics
@testable import gather_windows

@Suite("BoundsCalculator")
struct BoundsCalculatorTests {
    // Two displays for testing
    let builtIn = makeDisplay(frame: CGRect(x: 0, y: 0, width: 1440, height: 900))
    let external = makeDisplay(index: 2, frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080), isMain: false, name: "External")

    // MARK: - Proportional position mapping

    @Test func windowPosition_mappedProportionally() {
        // Window at (200, 100) on a 1920x1080 display → relative (200/1920, 100/1080)
        // Mapped to 1440x900: (150, 83)
        let window = CGRect(x: 1440 + 200, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        // relX = 200/1920 ≈ 0.1042, newX = 0 + 0.1042 * 1440 = 150
        // relY = 100/1080 ≈ 0.0926, newY = 0 + 0.0926 * 900 = 83
        #expect(result.origin.x == 150)
        #expect(result.origin.y == 83)
    }

    @Test func windowSize_scaledProportionally() {
        // 400x300 on 1920x1080 → relW=400/1920, relH=300/1080
        // On 1440x900: w = 300, h = 250
        let window = CGRect(x: 1440 + 200, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        #expect(result.width == 300)
        #expect(result.height == 250)
    }

    @Test func windowAtOrigin_staysAtOriginRegion() {
        // Window at source display origin
        let window = CGRect(x: 1440, y: 0, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        // relX=0, relY=0 → newX=0, newY=0, but clamped to safe area
        #expect(result.origin.x == Constants.sideMargin) // 20
        #expect(result.origin.y == Constants.topMargin)   // 80
    }

    @Test func sameSourceAndTarget_preservesPosition() {
        // Moving window to the same display should keep it roughly in place
        let window = CGRect(x: 200, y: 200, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: builtIn, targetDisplay: builtIn)

        #expect(result.origin.x == 200)
        #expect(result.origin.y == 200)
        #expect(result.width == 400)
        #expect(result.height == 300)
    }

    // MARK: - Clamping to safe area

    @Test func windowTooWide_clampedToSafeArea() {
        // Window that would be too wide after proportional scaling
        // 1800/1920 * 1440 = 1350 — fits in safe area (1400)
        // But a window nearly full-width on source: 1900/1920 * 1440 = 1425 > 1400
        let window = CGRect(x: 1440 + 10, y: 100, width: 1900, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        let safeWidth = builtIn.width - Constants.sideMargin * 2  // 1400
        #expect(result.width <= safeWidth)
    }

    @Test func windowTooTall_clampedToSafeArea() {
        let window = CGRect(x: 1440 + 100, y: 10, width: 400, height: 1070)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        let safeHeight = builtIn.height - Constants.topMargin - Constants.bottomMargin  // 800
        #expect(result.height <= safeHeight)
    }

    @Test func windowPosition_clampedWithinSafeArea() {
        // Window near bottom-right of source → after mapping, should stay in safe area
        let window = CGRect(x: 1440 + 1500, y: 800, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        let maxX = builtIn.x + builtIn.width - Constants.sideMargin
        let maxY = builtIn.y + builtIn.height - Constants.bottomMargin
        #expect(result.origin.x + result.width <= maxX)
        #expect(result.origin.y + result.height <= maxY)
        #expect(result.origin.x >= builtIn.x + Constants.sideMargin)
        #expect(result.origin.y >= builtIn.y + Constants.topMargin)
    }

    // MARK: - Different display configurations

    @Test func targetDisplayWithNegativeOrigin_boundsOffsetCorrectly() {
        let leftDisplay = makeDisplay(frame: CGRect(x: -1920, y: 0, width: 1920, height: 1080))
        let window = CGRect(x: 500, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: builtIn, targetDisplay: leftDisplay)

        // Position should be within left display bounds
        #expect(result.origin.x >= -1920 + Constants.sideMargin)
        #expect(result.origin.x + result.width <= 0 - Constants.sideMargin)
    }

    @Test func targetDisplayWithPositiveOrigin_boundsOffsetCorrectly() {
        let rightDisplay = makeDisplay(frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080))
        let window = CGRect(x: 100, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: builtIn, targetDisplay: rightDisplay)

        #expect(result.origin.x >= 1440 + Constants.sideMargin)
    }

    @Test func targetDisplayWithNegativeY_boundsPositionedCorrectly() {
        let display = makeDisplay(frame: CGRect(x: 1440, y: -180, width: 1920, height: 1080))
        let window = CGRect(x: 100, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: builtIn, targetDisplay: display)

        #expect(result.origin.y >= -180 + Constants.topMargin)
    }

    // MARK: - Scaling between different-sized displays

    @Test func smallToLargeDisplay_windowScalesUp() {
        // 400x300 on 1440x900 → relW=400/1440, relH=300/900
        // On 1920x1080: w=533, h=360
        let window = CGRect(x: 200, y: 200, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: builtIn, targetDisplay: external)

        #expect(result.width > 400)  // Should scale up
        #expect(result.height > 300)
    }

    @Test func largeToSmallDisplay_windowScalesDown() {
        let window = CGRect(x: 1440 + 200, y: 200, width: 800, height: 600)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        #expect(result.width < 800)  // Should scale down
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
        // Window right edge at 1500, max is 1440 - 20 = 1420
        let bounds = CGRect(x: 900, y: 100, width: 600, height: 300)
        let result = BoundsCalculator.clampToSafeArea(bounds, targetDisplay: builtIn)
        let maxX = builtIn.x + builtIn.width - Constants.sideMargin
        #expect(result.origin.x + result.width <= maxX)
        #expect(result.width == 600) // width unchanged, only position shifts
    }

    @Test func clampToSafeArea_windowExceedsBottomEdge_positionShifted() {
        let bounds = CGRect(x: 100, y: 600, width: 400, height: 400)
        let result = BoundsCalculator.clampToSafeArea(bounds, targetDisplay: builtIn)
        let maxY = builtIn.y + builtIn.height - Constants.bottomMargin
        #expect(result.origin.y + result.height <= maxY)
    }

    @Test func clampToSafeArea_windowTooWide_sizeAndPositionClamped() {
        // Width exceeds safe area (1440 - 40 = 1400)
        let bounds = CGRect(x: 100, y: 100, width: 1500, height: 300)
        let result = BoundsCalculator.clampToSafeArea(bounds, targetDisplay: builtIn)
        let safeWidth = builtIn.width - Constants.sideMargin * 2
        #expect(result.width == safeWidth)
        #expect(result.origin.x >= builtIn.x + Constants.sideMargin)
    }

    // MARK: - Edge cases

    @Test func zeroSizeWindow_returnsZeroSize() {
        let window = CGRect(x: 1440 + 100, y: 100, width: 0, height: 0)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        #expect(result.width == 0)
        #expect(result.height == 0)
    }

    @Test func windowExactlySafeAreaSize_clampedCorrectly() {
        // Full-size window on source
        let window = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let result = BoundsCalculator.calculateNewBounds(window, sourceDisplay: external, targetDisplay: builtIn)

        let safeWidth = builtIn.width - Constants.sideMargin * 2
        let safeHeight = builtIn.height - Constants.topMargin - Constants.bottomMargin
        #expect(result.width <= safeWidth)
        #expect(result.height <= safeHeight)
    }
}
