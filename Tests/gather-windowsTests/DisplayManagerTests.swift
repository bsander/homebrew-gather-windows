import Testing
import CoreGraphics
@testable import gather_windows

@Suite("DisplayManager")
struct DisplayManagerTests {

    // MARK: - getAllDisplays

    @Suite("getAllDisplays")
    struct GetAllDisplaysTests {
        @Test func singleMainDisplay_returnsOneDisplayMarkedMain() {
            let provider = MockScreenProvider(mockScreens: [
                (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), visibleFrame: CGRect.zero, isMain: true)
            ])
            let dm = DisplayManager(screenProvider: provider)
            let displays = dm.getAllDisplays()

            #expect(displays.count == 1)
            #expect(displays[0].isMain == true)
            #expect(displays[0].index == 1)
            #expect(displays[0].name == "Main Display")
            #expect(displays[0].width == 1440)
        }

        @Test func twoDisplays_mainFlagCorrect() {
            let provider = MockScreenProvider(mockScreens: [
                (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), visibleFrame: CGRect.zero, isMain: true),
                (frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080), visibleFrame: CGRect.zero, isMain: false)
            ])
            let dm = DisplayManager(screenProvider: provider)
            let displays = dm.getAllDisplays()

            #expect(displays.count == 2)
            #expect(displays[0].isMain == true)
            #expect(displays[0].name == "Main Display")
            #expect(displays[1].isMain == false)
            #expect(displays[1].name == "Display 2")
            #expect(displays[1].index == 2)
        }

        @Test func noDisplays_returnsEmptyArray() {
            let provider = MockScreenProvider(mockScreens: [])
            let dm = DisplayManager(screenProvider: provider)
            let displays = dm.getAllDisplays()

            #expect(displays.isEmpty)
        }
    }

    // MARK: - findBuiltInDisplay

    @Suite("findBuiltInDisplay")
    struct FindBuiltInDisplayTests {
        @Test func singleMainDisplay_returnsThatDisplay() {
            let display = makeDisplay(index: 1, isMain: true, name: "Main Display")
            let result = DisplayManager.findBuiltInDisplay([display])

            #expect(result?.index == 1)
            #expect(result?.isMain == true)
        }

        @Test func multipleDisplays_returnsMainOne() {
            let displays = [
                makeDisplay(index: 1, frame: CGRect(x: -1920, y: 0, width: 1920, height: 1080), isMain: false, name: "External"),
                makeDisplay(index: 2, frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true, name: "Built-in"),
            ]
            let result = DisplayManager.findBuiltInDisplay(displays)

            #expect(result?.index == 2)
            #expect(result?.isMain == true)
        }

        @Test func noMainDisplay_fallsBackToFirst() {
            let displays = [
                makeDisplay(index: 1, isMain: false, name: "Display 1"),
                makeDisplay(index: 2, isMain: false, name: "Display 2"),
            ]
            let result = DisplayManager.findBuiltInDisplay(displays)

            #expect(result?.index == 1)
        }

        @Test func emptyList_returnsNil() {
            let result = DisplayManager.findBuiltInDisplay([])
            #expect(result == nil)
        }
    }

    // MARK: - isOnExternalDisplay

    @Suite("isOnExternalDisplay")
    struct IsOnExternalDisplayTests {
        let builtIn = makeDisplay(frame: CGRect(x: 0, y: 0, width: 1440, height: 900))

        @Test func windowFullyInsideBuiltIn_returnsFalse() {
            let window = CGRect(x: 100, y: 100, width: 400, height: 300)
            #expect(DisplayManager.isOnExternalDisplay(window, builtIn) == false)
        }

        @Test func windowFullyOutsideBuiltIn_returnsTrue() {
            let window = CGRect(x: 2000, y: 100, width: 400, height: 300)
            #expect(DisplayManager.isOnExternalDisplay(window, builtIn) == true)
        }

        @Test func windowPartiallyOverlapping_returnsTrue() {
            // Right edge extends past built-in display
            let window = CGRect(x: 1200, y: 100, width: 400, height: 300)
            #expect(DisplayManager.isOnExternalDisplay(window, builtIn) == true)
        }

        @Test func windowAtExactEdge_returnsFalse() {
            // Window exactly fits at right edge: x=1040, width=400, right=1440 == display width
            let window = CGRect(x: 1040, y: 0, width: 400, height: 900)
            #expect(DisplayManager.isOnExternalDisplay(window, builtIn) == false)
        }

        @Test func windowOnePixelOutside_returnsTrue() {
            let window = CGRect(x: 1041, y: 0, width: 400, height: 300)
            #expect(DisplayManager.isOnExternalDisplay(window, builtIn) == true)
        }

        @Test func windowOnLeftExternalDisplay_returnsTrue() {
            let window = CGRect(x: -500, y: 100, width: 400, height: 300)
            #expect(DisplayManager.isOnExternalDisplay(window, builtIn) == true)
        }

        @Test func windowOnDisplayAbove_returnsTrue() {
            let window = CGRect(x: 100, y: -500, width: 400, height: 300)
            #expect(DisplayManager.isOnExternalDisplay(window, builtIn) == true)
        }

        // Different-height displays: secondary is taller, top extends above primary
        // CG coords: primary (0,0,1440,900), secondary (1440,-180,1920,1080)
        @Test func windowOnTallerSecondary_detectedAsExternalToMain() {
            let window = CGRect(x: 1500, y: -100, width: 500, height: 300)
            #expect(DisplayManager.isOnExternalDisplay(window, builtIn) == true)
        }

        @Test func windowOnTallerSecondary_detectedAsOnSecondary() {
            let secondary = makeDisplay(
                index: 2,
                frame: CGRect(x: 1440, y: -180, width: 1920, height: 1080),
                isMain: false, name: "External"
            )
            // Window at (1500, -100) is within secondary (1440..<3360, -180..<900)
            let window = CGRect(x: 1500, y: -100, width: 500, height: 300)
            #expect(DisplayManager.isOnExternalDisplay(window, secondary) == false)
        }
    }

    // MARK: - displayForNumber

    @Suite("displayForNumber")
    struct DisplayForNumberTests {
        @Test func number1_returnsMainDisplay() {
            let screens: [(frame: CGRect, visibleFrame: CGRect, isMain: Bool)] = [
                (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), visibleFrame: CGRect.zero, isMain: true),
                (frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080), visibleFrame: CGRect.zero, isMain: false),
            ]
            let dm = DisplayManager(screenProvider: MockScreenProvider(mockScreens: screens))
            let display = dm.displayForNumber(1)

            #expect(display != nil)
            #expect(display?.isMain == true)
            #expect(display?.index == 1)
        }

        @Test func number2_returnsSecondDisplay() {
            let screens: [(frame: CGRect, visibleFrame: CGRect, isMain: Bool)] = [
                (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), visibleFrame: CGRect.zero, isMain: true),
                (frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080), visibleFrame: CGRect.zero, isMain: false),
            ]
            let dm = DisplayManager(screenProvider: MockScreenProvider(mockScreens: screens))
            let display = dm.displayForNumber(2)

            #expect(display != nil)
            #expect(display?.isMain == false)
            #expect(display?.index == 2)
        }

        @Test func invalidNumber_returnsNil() {
            let screens: [(frame: CGRect, visibleFrame: CGRect, isMain: Bool)] = [
                (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), visibleFrame: CGRect.zero, isMain: true),
            ]
            let dm = DisplayManager(screenProvider: MockScreenProvider(mockScreens: screens))
            let display = dm.displayForNumber(5)

            #expect(display == nil)
        }

        @Test func number0_returnsNil() {
            let screens: [(frame: CGRect, visibleFrame: CGRect, isMain: Bool)] = [
                (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), visibleFrame: CGRect.zero, isMain: true),
            ]
            let dm = DisplayManager(screenProvider: MockScreenProvider(mockScreens: screens))

            #expect(dm.displayForNumber(0) == nil)
        }

        @Test func usesScreenNumberingOrder() {
            // External on left, main on right — external should be #2 despite being first in array
            let screens: [(frame: CGRect, visibleFrame: CGRect, isMain: Bool)] = [
                (frame: CGRect(x: -1920, y: 0, width: 1920, height: 1080), visibleFrame: CGRect.zero, isMain: false),
                (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), visibleFrame: CGRect.zero, isMain: true),
            ]
            let dm = DisplayManager(screenProvider: MockScreenProvider(mockScreens: screens))

            let display1 = dm.displayForNumber(1)
            #expect(display1?.isMain == true)

            let display2 = dm.displayForNumber(2)
            #expect(display2?.isMain == false)
            #expect(display2?.frame.origin.x == -1920)
        }
    }

    // MARK: - displayContaining

    @Suite("displayContaining")
    struct DisplayContainingTests {
        let display1 = makeDisplay(index: 1, frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true, name: "Main Display")
        let display2 = makeDisplay(index: 2, frame: CGRect(x: 1440, y: -180, width: 1920, height: 1080), isMain: false, name: "Display 2")

        @Test func windowOnDisplay1_returnsDisplay1() {
            let window = CGRect(x: 100, y: 100, width: 400, height: 300)
            let result = DisplayManager.displayContaining(window, allDisplays: [display1, display2])
            #expect(result?.index == 1)
        }

        @Test func windowOnDisplay2_returnsDisplay2() {
            let window = CGRect(x: 1600, y: -50, width: 500, height: 300)
            let result = DisplayManager.displayContaining(window, allDisplays: [display1, display2])
            #expect(result?.index == 2)
        }

        @Test func windowSpanningDisplays_usesCenter() {
            // Window spans from display1 into display2, but center is on display2
            let window = CGRect(x: 1400, y: 100, width: 400, height: 300)
            // Center: (1600, 250) — within display2 (1440..<3360, -180..<900)
            let result = DisplayManager.displayContaining(window, allDisplays: [display1, display2])
            #expect(result?.index == 2)
        }

        @Test func windowOffScreen_returnsNil() {
            let window = CGRect(x: 5000, y: 5000, width: 400, height: 300)
            let result = DisplayManager.displayContaining(window, allDisplays: [display1, display2])
            #expect(result == nil)
        }
    }

    // MARK: - isWithinDisplay

    @Suite("isWithinDisplay")
    struct IsWithinDisplayTests {
        let display = makeDisplay(frame: CGRect(x: 0, y: 0, width: 1440, height: 900))

        @Test func windowFullyInside_returnsTrue() {
            let bounds = CGRect(x: 100, y: 100, width: 400, height: 300)
            #expect(DisplayManager.isWithinDisplay(bounds, display) == true)
        }

        @Test func windowSlightlyOutside_withinMargin_returnsTrue() {
            // Window shifted left by 30px (within 50px margin)
            let bounds = CGRect(x: -30, y: 100, width: 400, height: 300)
            #expect(DisplayManager.isWithinDisplay(bounds, display) == true)
        }

        @Test func windowFarOutside_returnsFalse() {
            let bounds = CGRect(x: 2000, y: 100, width: 400, height: 300)
            #expect(DisplayManager.isWithinDisplay(bounds, display) == false)
        }

        @Test func windowAtExactMarginBoundary_returnsTrue() {
            // x = -50 (exactly at margin boundary)
            let bounds = CGRect(x: -50, y: 0, width: 400, height: 300)
            #expect(DisplayManager.isWithinDisplay(bounds, display) == true)
        }

        @Test func windowOnePixelBeyondMargin_returnsFalse() {
            // x = -51 (one pixel beyond margin)
            let bounds = CGRect(x: -51, y: 100, width: 400, height: 300)
            #expect(DisplayManager.isWithinDisplay(bounds, display) == false)
        }
    }
}
