import Testing
import CoreGraphics
@testable import gather_windows

@Suite("BoundsCalculator")
struct BoundsCalculatorTests {
    // Standard built-in display: 1440x900 at origin
    let builtIn = makeDisplay(frame: CGRect(x: 0, y: 0, width: 1440, height: 900))

    // Safe area for the standard display:
    // x: 20, y: 80, width: 1400, height: 800

    @Test func windowThatFits_isCenteredInSafeArea() {
        let window = CGRect(x: 2000, y: 100, width: 800, height: 600)
        let result = BoundsCalculator.calculateNewBounds(window, builtIn)

        // Centered in safe area (1400x800 starting at 20,80)
        // x = 20 + floor((1400 - 800) / 2) = 20 + 300 = 320
        // y = 80 + floor((800 - 600) / 2) = 80 + 100 = 180
        #expect(result.width == 800)
        #expect(result.height == 600)
        #expect(result.origin.x == 320)
        #expect(result.origin.y == 180)
    }

    @Test func smallWindow_isCenteredInSafeArea() {
        let window = CGRect(x: 3000, y: 200, width: 200, height: 150)
        let result = BoundsCalculator.calculateNewBounds(window, builtIn)

        #expect(result.width == 200)
        #expect(result.height == 150)
        // x = 20 + floor((1400 - 200) / 2) = 20 + 600 = 620
        // y = 80 + floor((800 - 150) / 2) = 80 + 325 = 405
        #expect(result.origin.x == 620)
        #expect(result.origin.y == 405)
    }

    @Test func windowTooWide_scaledDownPreservingAspectRatio() {
        // Window wider than safe area (1400) but shorter than safe height (800)
        let window = CGRect(x: 2000, y: 0, width: 2800, height: 600)
        let result = BoundsCalculator.calculateNewBounds(window, builtIn)

        // scaleWidth = 1400 / 2800 = 0.5
        // scaleHeight = 800 / 600 = 1.333
        // scale = min(0.5, 1.333) = 0.5
        // newWidth = floor(2800 * 0.5) = 1400
        // newHeight = floor(600 * 0.5) = 300
        #expect(result.width == 1400)
        #expect(result.height == 300)
    }

    @Test func windowTooTall_scaledDownPreservingAspectRatio() {
        // Window taller than safe area (800) but narrower than safe width (1400)
        let window = CGRect(x: 2000, y: 0, width: 400, height: 1600)
        let result = BoundsCalculator.calculateNewBounds(window, builtIn)

        // scaleWidth = 1400 / 400 = 3.5
        // scaleHeight = 800 / 1600 = 0.5
        // scale = 0.5
        // newWidth = floor(400 * 0.5) = 200
        // newHeight = floor(1600 * 0.5) = 800
        #expect(result.width == 200)
        #expect(result.height == 800)
    }

    @Test func windowTooBigBothDimensions_scaledBySmallestFactor() {
        let window = CGRect(x: 2000, y: 0, width: 2800, height: 1600)
        let result = BoundsCalculator.calculateNewBounds(window, builtIn)

        // scaleWidth = 1400 / 2800 = 0.5
        // scaleHeight = 800 / 1600 = 0.5
        // scale = 0.5
        // newWidth = floor(2800 * 0.5) = 1400
        // newHeight = floor(1600 * 0.5) = 800
        #expect(result.width == 1400)
        #expect(result.height == 800)
    }

    @Test func windowExactlySafeAreaSize_noScaling() {
        let window = CGRect(x: 2000, y: 0, width: 1400, height: 800)
        let result = BoundsCalculator.calculateNewBounds(window, builtIn)

        #expect(result.width == 1400)
        #expect(result.height == 800)
        // Centered: x = 20, y = 80
        #expect(result.origin.x == 20)
        #expect(result.origin.y == 80)
    }

    @Test func veryLargeWindow_scaledToFitSafeArea() {
        let window = CGRect(x: 0, y: 0, width: 5600, height: 3200)
        let result = BoundsCalculator.calculateNewBounds(window, builtIn)

        // scaleWidth = 1400 / 5600 = 0.25
        // scaleHeight = 800 / 3200 = 0.25
        // scale = 0.25
        #expect(result.width == 1400)
        #expect(result.height == 800)
    }

    @Test func targetDisplayWithNegativeOrigin_boundsOffsetCorrectly() {
        // External display to the left
        let display = makeDisplay(frame: CGRect(x: -1920, y: 0, width: 1920, height: 1080))
        let window = CGRect(x: 500, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, display)

        // Safe area: x=-1900, y=80, w=1880, h=980
        // Centered: x = -1900 + floor((1880 - 400) / 2) = -1900 + 740 = -1160
        // y = 80 + floor((980 - 300) / 2) = 80 + 340 = 420
        #expect(result.origin.x == -1160)
        #expect(result.origin.y == 420)
        #expect(result.width == 400)
        #expect(result.height == 300)
    }

    @Test func targetDisplayWithPositiveOrigin_boundsOffsetCorrectly() {
        // Display to the right
        let display = makeDisplay(frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080))
        let window = CGRect(x: 100, y: 100, width: 400, height: 300)
        let result = BoundsCalculator.calculateNewBounds(window, display)

        // Safe area: x=1460, y=80, w=1880, h=980
        // Centered: x = 1460 + floor((1880 - 400) / 2) = 1460 + 740 = 2200
        #expect(result.origin.x == 2200)
        #expect(result.width == 400)
    }

    @Test func ultraWideWindow_scaledMaintainingRatio() {
        // 3440x100 ultrawide
        let window = CGRect(x: 2000, y: 0, width: 3440, height: 100)
        let result = BoundsCalculator.calculateNewBounds(window, builtIn)

        // scaleWidth = 1400 / 3440 ≈ 0.4069...
        // scaleHeight = 800 / 100 = 8.0
        // scale = 0.4069
        // newWidth = floor(3440 * 0.4069...) = floor(1399.76...) = 1399 (using exact: 1400/3440*3440 = 1400)
        // Actually: scale = 1400/3440, newWidth = floor(3440 * 1400/3440) = floor(1400) = 1400
        // newHeight = floor(100 * 1400/3440) = floor(40.697...) = 40
        #expect(result.width == 1400)
        #expect(result.height == 40)
    }

    @Test func tallNarrowWindow_scaledMaintainingRatio() {
        // 100x1600 tall narrow
        let window = CGRect(x: 2000, y: 0, width: 100, height: 1600)
        let result = BoundsCalculator.calculateNewBounds(window, builtIn)

        // scaleWidth = 1400 / 100 = 14.0
        // scaleHeight = 800 / 1600 = 0.5
        // scale = 0.5
        // newWidth = floor(100 * 0.5) = 50
        // newHeight = floor(1600 * 0.5) = 800
        #expect(result.width == 50)
        #expect(result.height == 800)
    }

    @Test func resultValues_areRounded() {
        // Use dimensions that produce fractional intermediate values
        let display = makeDisplay(frame: CGRect(x: 0, y: 0, width: 1441, height: 901))
        let window = CGRect(x: 2000, y: 0, width: 300, height: 200)
        let result = BoundsCalculator.calculateNewBounds(window, display)

        // All result values should be whole numbers
        #expect(result.origin.x == result.origin.x.rounded())
        #expect(result.origin.y == result.origin.y.rounded())
        #expect(result.width == result.width.rounded())
        #expect(result.height == result.height.rounded())
    }

    @Test func zeroSizeWindow_returnsZeroSizeCentered() {
        let window = CGRect(x: 2000, y: 0, width: 0, height: 0)
        let result = BoundsCalculator.calculateNewBounds(window, builtIn)

        #expect(result.width == 0)
        #expect(result.height == 0)
    }
}
