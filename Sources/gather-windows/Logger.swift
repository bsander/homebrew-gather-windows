import Foundation

/// Global verbose flag
@MainActor
var VERBOSE = false

/// Log a message to stdout (JXA lines 76-78)
@MainActor
func log(_ message: String) {
    print(message)
}

/// Log a message only in verbose mode (JXA lines 80-84)
@MainActor
func logVerbose(_ message: String) {
    if VERBOSE {
        print(message)
    }
}

/// Log display information (JXA lines 148-165)
@MainActor
func logDisplayInfo(_ allDisplays: [DisplayInfo], _ builtInDisplay: DisplayInfo) {
    guard VERBOSE else { return }

    log("\nDisplays detected:")
    for display in allDisplays {
        let isBuiltIn = display.index == builtInDisplay.index
        let marker = isBuiltIn ? " [BUILT-IN]" : ""
        log("  [\(display.index)] \(display.name)\(marker)")
        log(String(format: "      Bounds: {x: %.0f, y: %.0f, width: %.0f, height: %.0f}",
                   display.x, display.y, display.width, display.height))

        if isBuiltIn {
            let safeArea = display.safeArea
            log(String(format: "      Safe area: {x: %.0f, y: %.0f, width: %.0f, height: %.0f}",
                       safeArea.origin.x, safeArea.origin.y, safeArea.width, safeArea.height))
        }
    }
    log("")
}

/// Format window bounds for logging
func formatBounds(_ bounds: CGRect) -> String {
    String(format: "pos=(%.0f, %.0f) size=(%.0f, %.0f)",
           bounds.origin.x, bounds.origin.y, bounds.width, bounds.height)
}

/// Get display location label (JXA lines 302-314)
func getDisplayLocation(_ bounds: CGRect, _ builtInDisplay: DisplayInfo) -> String {
    let centerX = bounds.origin.x + (bounds.width / 2)
    let centerY = bounds.origin.y + (bounds.height / 2)

    let onBuiltIn = (
        centerX >= builtInDisplay.x &&
        centerX <= builtInDisplay.x + builtInDisplay.width &&
        centerY >= builtInDisplay.y &&
        centerY <= builtInDisplay.y + builtInDisplay.height
    )

    return onBuiltIn ? "[BUILT-IN]" : "[EXTERNAL]"
}
