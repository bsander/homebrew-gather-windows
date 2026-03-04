import Foundation
import AppKit

/// Parse command-line arguments (JXA lines 46-71)
func parseArguments(_ args: [String]) -> Options {
    var options = Options()

    for arg in args {
        switch arg {
        case "--help", "-h":
            options.help = true
        case "--include-fullscreen":
            options.includeFullscreen = true
        case "--verbose", "-v":
            options.verbose = true
        case "--hide-during-move":
            options.hideDuringMove = true
        default:
            print("Unknown argument: \(arg)")
            options.help = true
        }
    }

    return options
}

/// Show help message (JXA lines 86-110)
func showHelp() {
    let name = "gather-windows-swift"

    print("""
\(name) - Move all windows from external displays to built-in display

Usage:
  \(name) [options]

Options:
  --include-fullscreen    Move fullscreen windows (exits fullscreen mode)
  --hide-during-move     Hide windows before moving (prevents screen share flash)
  --verbose, -v          Show detailed logging of window movements
  --help, -h             Show this help message

Examples:
  \(name)                           # Move windows, skip fullscreen
  \(name) --include-fullscreen      # Move all windows including fullscreen
  \(name) --hide-during-move        # Hide windows before moving (privacy mode)

Notes:
  - Skips minimized windows (preserves hidden state)
  - Preserves relative window positions proportionally
  - Resizes windows that are too large to fit built-in display
  - Requires Accessibility permissions (macOS will prompt on first run)
""")
}
