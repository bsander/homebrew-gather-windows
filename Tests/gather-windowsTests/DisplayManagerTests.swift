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
                (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true)
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
                (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true),
                (frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080), isMain: false)
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
