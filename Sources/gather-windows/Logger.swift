import Foundation

/// Global verbose flag (runtime, set by --verbose CLI arg)
@MainActor
var VERBOSE = false

// MARK: - File Logger

/// Writes timestamped log lines to a file. Used for retroactive debugging.
final class FileLogger: Sendable {
    private let handle: FileHandle?

    init(path: String) {
        FileManager.default.createFile(atPath: path, contents: nil)
        self.handle = FileHandle(forWritingAtPath: path)
        self.handle?.seekToEndOfFile()
    }

    deinit {
        try? handle?.close()
    }

    func write(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] \(message)\n"
        handle?.seekToEndOfFile()
        if let data = line.data(using: .utf8) {
            handle?.write(data)
        }
    }
}

// MARK: - Compile-time file logging

#if VERBOSE_LOGGING
/// File logger instance — writes to ~/Library/Logs/GatherWindows.log in debug builds
@MainActor
private var _fileLogger: FileLogger? = FileLogger(
    path: NSHomeDirectory() + "/Library/Logs/GatherWindows.log"
)

/// Replace the file logger (for testing)
@MainActor
func setFileLogger(_ logger: FileLogger?) {
    _fileLogger = logger
}

@MainActor
private func writeToFileLog(_ message: String) {
    _fileLogger?.write(message)
}
#else
/// No-op in release builds
@MainActor
func setFileLogger(_ logger: FileLogger?) {}
#endif

// MARK: - Public logging functions

/// Log a message to stdout
@MainActor
func log(_ message: String) {
    print(message)
}

/// Log a verbose message — writes to file in debug builds, stdout if --verbose
@MainActor
func logVerbose(_ message: String) {
    #if VERBOSE_LOGGING
    writeToFileLog(message)
    #endif
    if VERBOSE {
        print(message)
    }
}

/// Log display information
@MainActor
func logDisplayInfo(_ allDisplays: [DisplayInfo], _ targetDisplay: DisplayInfo) {
    #if VERBOSE_LOGGING
    let shouldLog = true
    #else
    let shouldLog = VERBOSE
    #endif
    guard shouldLog else { return }

    logVerbose("\nDisplays detected:")
    for display in allDisplays {
        let isTarget = display.index == targetDisplay.index
        let marker = isTarget ? " [TARGET]" : ""
        logVerbose("  [\(display.index)] \(display.name)\(marker)")
        logVerbose(String(format: "      Bounds: {x: %.0f, y: %.0f, width: %.0f, height: %.0f}",
                   display.x, display.y, display.width, display.height))

        if isTarget {
            let safeArea = display.safeArea
            logVerbose(String(format: "      Safe area: {x: %.0f, y: %.0f, width: %.0f, height: %.0f}",
                       safeArea.origin.x, safeArea.origin.y, safeArea.width, safeArea.height))
        }
    }
    logVerbose("")
}

/// Format window bounds for logging
func formatBounds(_ bounds: CGRect) -> String {
    String(format: "pos=(%.0f, %.0f) size=(%.0f, %.0f)",
           bounds.origin.x, bounds.origin.y, bounds.width, bounds.height)
}

/// Get display location label relative to the target display
func getDisplayLocation(_ bounds: CGRect, _ targetDisplay: DisplayInfo) -> String {
    let centerX = bounds.origin.x + (bounds.width / 2)
    let centerY = bounds.origin.y + (bounds.height / 2)

    let onTarget = (
        centerX >= targetDisplay.x &&
        centerX <= targetDisplay.x + targetDisplay.width &&
        centerY >= targetDisplay.y &&
        centerY <= targetDisplay.y + targetDisplay.height
    )

    return onTarget ? "[ON TARGET]" : "[WILL MOVE]"
}
