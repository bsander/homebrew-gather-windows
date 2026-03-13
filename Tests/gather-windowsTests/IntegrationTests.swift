import Testing
import CoreGraphics
@testable import gather_windows

@Suite("Integration")
struct IntegrationTests {

    @Test func realDisplayEnumeration_returnsAtLeastOneDisplay() {
        let dm = DisplayManager()
        let displays = dm.getAllDisplays()

        #expect(!displays.isEmpty)
        #expect(displays.contains { $0.isMain })
    }

    @Test func cocoaToCGConversion_primaryDisplay() {
        // Primary display: same in both coordinate systems
        let result = CoordinateConverter.cocoaToCG(
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            primaryScreenHeight: 900
        )
        #expect(result == CGRect(x: 0, y: 0, width: 1440, height: 900))
    }

    @Test func cocoaToCGConversion_tallerSecondary() {
        // NSScreen frame for taller secondary (bottom-aligned): (1440, 0, 1920, 1080)
        // Expected CG frame: (1440, -180, 1920, 1080)
        let result = CoordinateConverter.cocoaToCG(
            frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
            primaryScreenHeight: 900
        )
        #expect(result == CGRect(x: 1440, y: -180, width: 1920, height: 1080))
    }

    @Test func cocoaToCGConversion_shorterSecondary() {
        // NSScreen frame for shorter secondary (bottom-aligned, primary 900px tall):
        // Cocoa: (1440, 0, 1920, 720) — origin at bottom-left
        // CG: (1440, 180, 1920, 720) — top of secondary is 180px below top of primary
        let result = CoordinateConverter.cocoaToCG(
            frame: CGRect(x: 1440, y: 0, width: 1920, height: 720),
            primaryScreenHeight: 900
        )
        #expect(result == CGRect(x: 1440, y: 180, width: 1920, height: 720))
    }

    @Test func cocoaToCGConversion_displayAbove() {
        // NSScreen frame for display positioned above primary:
        // Cocoa: (0, 900, 1920, 1080) — origin at bottom-left, y=900 means above primary
        // CG: (0, -1080, 1920, 1080) — top of display is 1080px above top of primary
        let result = CoordinateConverter.cocoaToCG(
            frame: CGRect(x: 0, y: 900, width: 1920, height: 1080),
            primaryScreenHeight: 900
        )
        #expect(result == CGRect(x: 0, y: -1080, width: 1920, height: 1080))
    }

    @Test func matchScreenToDisplay_convertsCocoaToCGBeforeMatching() {
        // Primary: Cocoa (0,0,1440,900) → CG (0,0,1440,900) — matches display 1
        // Secondary: Cocoa (1440,0,1920,1080) → CG (1440,-180,1920,1080) — matches display 2
        let displays = [
            makeDisplay(index: 1, frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true, name: "Main"),
            makeDisplay(index: 2, frame: CGRect(x: 1440, y: -180, width: 1920, height: 1080), isMain: false, name: "External"),
        ]

        let primaryCocoaFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let secondaryCocoaFrame = CGRect(x: 1440, y: 0, width: 1920, height: 1080)

        let match1 = CoordinateConverter.matchScreenToDisplay(
            screenFrame: primaryCocoaFrame,
            displays: displays,
            primaryScreenHeight: 900
        )
        #expect(match1?.index == 1)

        let match2 = CoordinateConverter.matchScreenToDisplay(
            screenFrame: secondaryCocoaFrame,
            displays: displays,
            primaryScreenHeight: 900
        )
        #expect(match2?.index == 2)
    }

    @Test func matchScreenToDisplay_returnsNilForUnmatchedScreen() {
        let displays = [
            makeDisplay(index: 1, frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true, name: "Main"),
        ]

        let unmatchedFrame = CGRect(x: 5000, y: 0, width: 1920, height: 1080)
        let match = CoordinateConverter.matchScreenToDisplay(
            screenFrame: unmatchedFrame,
            displays: displays,
            primaryScreenHeight: 900
        )
        #expect(match == nil)
    }

    @Test func realDisplayHasSafeArea_notLargerThanFrame() {
        let dm = DisplayManager()
        let displays = dm.getAllDisplays()

        for display in displays {
            let safe = display.safeArea
            #expect(safe.width <= display.width)
            #expect(safe.height <= display.height)
        }
    }
}
