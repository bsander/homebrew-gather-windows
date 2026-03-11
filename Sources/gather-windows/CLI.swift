import Foundation

/// CLI mode: parse arguments and gather windows to a specific screen
enum CLI {
    /// Parse CLI arguments and run gather. Returns exit code.
    @MainActor
    static func run(_ args: [String]) async -> Int32 {
        // Parse target screen from first argument
        let targetArg = args[0]
        let targetNumber: Int

        if targetArg == "main" {
            targetNumber = 1
        } else if let num = Int(targetArg), num > 0 {
            targetNumber = num
        } else {
            printUsage()
            return 1
        }

        // Parse optional flags from remaining args
        var verbose = false
        var includeFullscreen = false
        var hideDuringMove = false

        for arg in args.dropFirst() {
            switch arg {
            case "--verbose", "-v":
                verbose = true
            case "--include-fullscreen":
                includeFullscreen = true
            case "--hide-during-move":
                hideDuringMove = true
            default:
                FileHandle.standardError.write(Data("Unknown option: \(arg)\n".utf8))
                printUsage()
                return 1
            }
        }

        VERBOSE = verbose

        let displayManager = DisplayManager()
        let allDisplays = displayManager.getAllDisplays()

        guard let targetDisplay = displayManager.displayForNumber(targetNumber) else {
            FileHandle.standardError.write(
                Data("Error: No screen with number \(targetNumber). Available: 1-\(allDisplays.count)\n".utf8)
            )
            return 1
        }

        logDisplayInfo(allDisplays, targetDisplay)

        let windowManager = WindowManager()
        let result = await windowManager.moveWindowsToDisplay(
            targetDisplay,
            allDisplays: allDisplays,
            includeFullscreen: includeFullscreen,
            hideDuringMove: hideDuringMove
        )

        let windowText = result.movedCount != 1 ? "windows" : "window"
        log("Moved \(result.movedCount) \(windowText) to \(targetDisplay.name)")

        return 0
    }

    static func printUsage() {
        let usage = """
        Usage: gather-windows [<screen-number> | main] [options]

        Arguments:
          <screen-number>       Target screen number (1 = main display)
          main                  Alias for screen 1

        Options:
          --verbose, -v         Show detailed logging
          --include-fullscreen  Move fullscreen windows too
          --hide-during-move    Hide windows before moving

        When launched without arguments, shows overlay UI for screen selection.
        """
        FileHandle.standardError.write(Data(usage.utf8))
    }
}
