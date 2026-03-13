# Compile-Time Verbose File Logging

## Goal
Add a compile-time switch that makes debug builds always log verbosely to `~/Library/Logs/GatherWindows.log` for retroactive debugging. Release builds strip all file-logging code for zero overhead.

## Compile-Time Flag

**Package.swift** — add to `gather-windows` target's `swiftSettings`:
```swift
.define("VERBOSE_LOGGING", .when(configuration: .debug))
```

## Logger.swift Changes

### File logging infrastructure (compiled out in release)

```swift
#if VERBOSE_LOGGING
import Foundation

private let logFileHandle: FileHandle? = {
    let path = NSHomeDirectory() + "/Library/Logs/GatherWindows.log"
    FileManager.default.createFile(atPath: path, contents: nil)
    return FileHandle(forWritingAtPath: path)
}()

private func writeToLog(_ message: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let line = "[\(timestamp)] \(message)\n"
    logFileHandle?.seekToEndOfFile()
    logFileHandle?.write(line.data(using: .utf8)!)
}
#endif
```

### Updated logVerbose

```swift
@MainActor
func logVerbose(_ message: String) {
    #if VERBOSE_LOGGING
    writeToLog(message)
    #endif
    if VERBOSE {
        print(message)
    }
}
```

## Behavior Matrix

| Build   | File logging | Stdout (--verbose) |
|---------|--------------|--------------------|
| Debug   | Always on    | Runtime flag       |
| Release | Stripped     | Runtime flag       |

## What stays the same
- Runtime `--verbose` / `-v` CLI flag for stdout
- `log()` function (user-facing output)
- `logDisplayInfo()`, `formatBounds()`, `getDisplayLocation()` (delegate to logVerbose)
- All existing tests

## Testing
- Test that `logVerbose()` writes timestamped lines to the log file path
- Tests compile in debug mode → `VERBOSE_LOGGING` is defined → file-writing path is testable

## Not included (YAGNI)
- Log rotation
- Log level filtering
- os_log integration
