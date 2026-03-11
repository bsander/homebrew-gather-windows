import Testing
import CoreGraphics
@testable import gather_windows

@Suite("WindowManager")
struct WindowManagerTests {
    let builtIn = makeDisplay(frame: CGRect(x: 0, y: 0, width: 1440, height: 900))

    // Helper to create a WindowManager with mocks
    func makeManager(
        apps: [(pid: pid_t, name: String)] = [(pid: 1, name: "TestApp")],
        accessibility: MockAccessibilityProvider = MockAccessibilityProvider()
    ) -> (WindowManager, MockAccessibilityProvider) {
        let workspace = MockWorkspaceProvider(apps: apps)
        let wm = WindowManager(workspace: workspace, accessibility: accessibility)
        return (wm, accessibility)
    }

    // MARK: - Accessibility gate

    @Test @MainActor func accessibilityDenied_returnsZeroMoves() async {
        let mock = MockAccessibilityProvider()
        mock.trusted = false
        mock.windowsByPID[1] = [
            makeWindow(bounds: CGRect(x: 2000, y: 100, width: 400, height: 300))
        ]
        let (wm, _) = makeManager(accessibility: mock)

        let result = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: false, hideDuringMove: false)
        #expect(result.movedCount == 0)
        #expect(result.verifiedCount == 0)
    }

    // MARK: - Filtering

    @Suite("Window Filtering")
    struct FilteringTests {
        let builtIn = makeDisplay(frame: CGRect(x: 0, y: 0, width: 1440, height: 900))

        @Test @MainActor func minimizedWindows_areSkipped() async {
            let mock = MockAccessibilityProvider()
            mock.windowsByPID[1] = [
                makeWindow(bounds: CGRect(x: 2000, y: 100, width: 400, height: 300), isMinimized: true)
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 0)
            #expect(mock.movedWindows.isEmpty)
        }

        @Test @MainActor func fullscreenWindows_skippedByDefault() async {
            let mock = MockAccessibilityProvider()
            mock.windowsByPID[1] = [
                makeWindow(bounds: CGRect(x: 2000, y: 100, width: 400, height: 300), isFullscreen: true)
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 0)
        }

        @Test @MainActor func fullscreenWindows_includedWhenFlagSet() async {
            let mock = MockAccessibilityProvider()
            mock.windowsByPID[1] = [
                makeWindow(bounds: CGRect(x: 2000, y: 100, width: 400, height: 300), isFullscreen: true)
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: true, hideDuringMove: false)
            #expect(result.movedCount == 1)
        }

        @Test @MainActor func windowsOnBuiltInDisplay_areSkipped() async {
            let mock = MockAccessibilityProvider()
            // Window fully inside built-in display
            mock.windowsByPID[1] = [
                makeWindow(bounds: CGRect(x: 100, y: 100, width: 400, height: 300))
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 0)
            #expect(mock.movedWindows.isEmpty)
        }

        @Test @MainActor func windowsOnExternalDisplay_areIncluded() async {
            let mock = MockAccessibilityProvider()
            mock.windowsByPID[1] = [
                makeWindow(bounds: CGRect(x: 2000, y: 100, width: 400, height: 300))
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 1)
        }
    }

    // MARK: - Move orchestration

    @Suite("Move Orchestration")
    struct OrchestrationTests {
        let builtIn = makeDisplay(frame: CGRect(x: 0, y: 0, width: 1440, height: 900))

        @Test @MainActor func singleExternalWindow_movedAndCounted() async {
            let mock = MockAccessibilityProvider()
            mock.windowsByPID[1] = [
                makeWindow(bounds: CGRect(x: 2000, y: 100, width: 400, height: 300))
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 1)
            #expect(result.verifiedCount == 1)
            #expect(mock.movedWindows.count == 1)
        }

        @Test @MainActor func multipleExternalWindows_allMovedAndCounted() async {
            let mock = MockAccessibilityProvider()
            mock.windowsByPID[1] = [
                makeWindow(title: "Win1", bounds: CGRect(x: 2000, y: 100, width: 400, height: 300)),
                makeWindow(title: "Win2", bounds: CGRect(x: 3000, y: 200, width: 500, height: 400)),
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 2)
            #expect(mock.movedWindows.count == 2)
        }

        @Test @MainActor func mixedWindows_onlyExternalMoved() async {
            let mock = MockAccessibilityProvider()
            mock.windowsByPID[1] = [
                makeWindow(title: "Internal", bounds: CGRect(x: 100, y: 100, width: 400, height: 300)),
                makeWindow(title: "External", bounds: CGRect(x: 2000, y: 100, width: 400, height: 300)),
                makeWindow(title: "Minimized", bounds: CGRect(x: 2000, y: 100, width: 400, height: 300), isMinimized: true),
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 1)
            #expect(mock.movedWindows.count == 1)
        }

        @Test @MainActor func noExternalWindows_returnsZeroMoves() async {
            let mock = MockAccessibilityProvider()
            mock.windowsByPID[1] = [
                makeWindow(bounds: CGRect(x: 100, y: 100, width: 400, height: 300))
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 0)
        }

        @Test @MainActor func moveFails_notCountedAsMoved() async {
            let mock = MockAccessibilityProvider()
            mock.moveResult = false
            mock.windowsByPID[1] = [
                makeWindow(bounds: CGRect(x: 2000, y: 100, width: 400, height: 300))
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 0)
        }
    }

    // MARK: - Bounds calculation integration

    // MARK: - Different-height display scenarios

    @Suite("Different Height Displays")
    struct DifferentHeightTests {
        // CG coords: primary 1440x900 at origin, taller secondary to the right
        let primary = makeDisplay(
            index: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            isMain: true, name: "Main Display"
        )
        let secondary = makeDisplay(
            index: 2,
            frame: CGRect(x: 1440, y: -180, width: 1920, height: 1080),
            isMain: false, name: "Display 2"
        )

        @Test @MainActor func windowOnSecondary_movedToPrimary() async {
            let mock = MockAccessibilityProvider()
            // Window on secondary display (CG coords: y is negative because secondary is taller)
            mock.windowsByPID[1] = [
                makeWindow(bounds: CGRect(x: 1600, y: -50, width: 500, height: 300))
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(primary, allDisplays: [primary, secondary], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 1)
            #expect(mock.movedWindows.count == 1)
            // New bounds should be within primary display area
            let newBounds = mock.movedWindows[0].bounds
            #expect(newBounds.origin.x >= 0)
            #expect(newBounds.origin.x + newBounds.width <= 1440)
            #expect(newBounds.origin.y >= 0)
            #expect(newBounds.origin.y + newBounds.height <= 900)
        }

        @Test @MainActor func windowOnPrimary_movedToTallerSecondary() async {
            let mock = MockAccessibilityProvider()
            mock.windowsByPID[1] = [
                makeWindow(bounds: CGRect(x: 100, y: 100, width: 500, height: 300))
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(secondary, allDisplays: [primary, secondary], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 1)
            #expect(mock.movedWindows.count == 1)
            // New bounds should be within secondary display area (CG coords)
            let newBounds = mock.movedWindows[0].bounds
            #expect(newBounds.origin.x >= 1440)
            #expect(newBounds.origin.x + newBounds.width <= 1440 + 1920)
            #expect(newBounds.origin.y >= -180)
            #expect(newBounds.origin.y + newBounds.height <= -180 + 1080)
        }

        @Test @MainActor func windowAlreadyOnSecondary_notMovedToSecondary() async {
            let mock = MockAccessibilityProvider()
            // Window fully within secondary display bounds (CG coords)
            mock.windowsByPID[1] = [
                makeWindow(bounds: CGRect(x: 1600, y: 100, width: 500, height: 300))
            ]
            let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
            let wm = WindowManager(workspace: workspace, accessibility: mock)

            let result = await wm.moveWindowsToDisplay(secondary, allDisplays: [primary, secondary], includeFullscreen: false, hideDuringMove: false)
            #expect(result.movedCount == 0)
            #expect(mock.movedWindows.isEmpty)
        }
    }

    // MARK: - Bounds calculation integration

    @Test @MainActor func movedWindow_receivesCalculatedBounds() async {
        let mock = MockAccessibilityProvider()
        let windowBounds = CGRect(x: 2000, y: 100, width: 800, height: 600)
        mock.windowsByPID[1] = [makeWindow(bounds: windowBounds)]

        let workspace = MockWorkspaceProvider(apps: [(pid: 1, name: "App")])
        let wm = WindowManager(workspace: workspace, accessibility: mock)

        _ = await wm.moveWindowsToDisplay(builtIn, allDisplays: [builtIn], includeFullscreen: false, hideDuringMove: false)

        let expectedBounds = BoundsCalculator.calculateNewBounds(windowBounds, sourceDisplay: builtIn, targetDisplay: builtIn)
        #expect(mock.movedWindows.count == 1)
        #expect(mock.movedWindows[0].bounds == expectedBounds)
    }
}
