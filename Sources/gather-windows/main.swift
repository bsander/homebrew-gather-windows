import Foundation

@main
@MainActor
struct GatherWindows {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        let options = parseArguments(args)
        VERBOSE = options.verbose

        if options.help {
            showHelp()
            return
        }

        // Enumerate all displays
        let allDisplays = DisplayManager.getAllDisplays()
        guard let builtInDisplay = DisplayManager.findBuiltInDisplay(allDisplays) else {
            log("Error: Could not identify built-in display")
            Foundation.exit(1)
        }

        // Log display information
        logDisplayInfo(allDisplays, builtInDisplay)

        // Move windows to built-in display
        let result = await WindowManager.moveWindowsToDisplay(
            builtInDisplay,
            includeFullscreen: options.includeFullscreen,
            hideDuringMove: options.hideDuringMove
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
