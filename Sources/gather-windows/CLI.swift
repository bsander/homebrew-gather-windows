import ArgumentParser

/// Command-line interface for gather-windows
@main
struct GatherWindowsCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gather-windows",
        abstract: "Move all windows from external displays to built-in display"
    )

    @Flag(name: .long, help: "Move fullscreen windows (exits fullscreen mode)")
    var includeFullscreen = false

    @Flag(name: .long, help: "Hide windows before moving (prevents screen share flash)")
    var hideDuringMove = false

    @Flag(name: .shortAndLong, help: "Show detailed logging of window movements")
    var verbose = false

    @MainActor
    func run() async throws {
        VERBOSE = verbose

        // Enumerate all displays
        let displayManager = DisplayManager()
        let allDisplays = displayManager.getAllDisplays()
        guard let builtInDisplay = DisplayManager.findBuiltInDisplay(allDisplays) else {
            log("Error: Could not identify built-in display")
            throw ExitCode.failure
        }

        // Log display information
        logDisplayInfo(allDisplays, builtInDisplay)

        // Move windows to built-in display
        let windowManager = WindowManager()
        let result = await windowManager.moveWindowsToDisplay(
            builtInDisplay,
            includeFullscreen: includeFullscreen,
            hideDuringMove: hideDuringMove
        )

        // Report results
        let windowText = result.movedCount != 1 ? "windows" : "window"
        log("\nMoved \(result.movedCount) \(windowText) to built-in display")

        if result.verifiedCount == result.movedCount {
            logVerbose("All windows verified within bounds ✓")
        } else {
            log("Warning: \(result.movedCount - result.verifiedCount) window(s) may not be fully within bounds")
        }
    }
}
