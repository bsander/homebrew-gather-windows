import Foundation
import Testing
@testable import gather_windows

// MARK: - Mock ScreenProvider

struct MockScreenProvider: ScreenProvider {
    let mockScreens: [(frame: CGRect, isMain: Bool)]

    func screens() -> [(frame: CGRect, isMain: Bool)] {
        mockScreens
    }
}

// MARK: - Mock WorkspaceProvider

struct MockWorkspaceProvider: WorkspaceProvider {
    let apps: [(pid: pid_t, name: String)]

    func regularApplications() -> [(pid: pid_t, name: String)] {
        apps
    }
}

// MARK: - Mock AccessibilityProvider

final class MockAccessibilityProvider: AccessibilityProvider, @unchecked Sendable {
    var trusted: Bool = true
    var windowsByPID: [pid_t: [WindowInfo]] = [:]
    var moveResult: Bool = true
    private(set) var movedWindows: [(window: WindowInfo, bounds: CGRect)] = []
    var postMoveBounds: CGRect?
    var postMoveBoundsProvider: ((CGRect) -> CGRect?)? = nil

    func isAccessibilityTrusted() -> Bool {
        trusted
    }

    func checkAccessibility(prompt: Bool) -> Bool {
        trusted
    }

    func allWindows(forPID pid: pid_t, processName: String) -> [WindowInfo] {
        windowsByPID[pid] ?? []
    }

    func moveWindow(_ window: WindowInfo, to bounds: CGRect) -> Bool {
        movedWindows.append((window: window, bounds: bounds))
        return moveResult
    }

    func currentBounds(of window: WindowInfo) -> CGRect? {
        if let provider = postMoveBoundsProvider,
           let lastMove = movedWindows.last {
            return provider(lastMove.bounds)
        }
        return postMoveBounds
    }
}

// MARK: - Factory Helpers

func makeDisplay(
    index: Int = 1,
    frame: CGRect = CGRect(x: 0, y: 0, width: 1440, height: 900),
    isMain: Bool = true,
    name: String = "Built-in"
) -> DisplayInfo {
    DisplayInfo(index: index, frame: frame, isMain: isMain, name: name)
}

func makeWindow(
    processName: String = "TestApp",
    title: String = "Test Window",
    bounds: CGRect = CGRect(x: 2000, y: 100, width: 800, height: 600),
    isMinimized: Bool = false,
    isFullscreen: Bool = false
) -> WindowInfo {
    WindowInfo(
        element: nil,
        processName: processName,
        title: title,
        bounds: bounds,
        isMinimized: isMinimized,
        isFullscreen: isFullscreen
    )
}
