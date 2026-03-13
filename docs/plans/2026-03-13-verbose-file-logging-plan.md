# Verbose File Logging — Implementation Plan

## Steps

### 1. Add VERBOSE_LOGGING flag to Package.swift
- Add `.define("VERBOSE_LOGGING", .when(configuration: .debug))` to the `gather-windows` target's `swiftSettings`
- Verify: `swift build` succeeds

### 2. Write failing tests for file logging
- New test file or suite: verify `logVerbose()` writes to a log file
- Test: calling `logVerbose("test message")` creates/appends to log file with timestamp
- Test: log line format is `[ISO8601] message`
- Verify: tests fail (file logging not yet implemented)

### 3. Implement file logging in Logger.swift
- Add `#if VERBOSE_LOGGING` block with `logFileHandle` lazy init and `writeToLog()` helper
- Update `logVerbose()` to call `writeToLog()` under `#if VERBOSE_LOGGING`
- Keep existing `VERBOSE` stdout path unchanged
- Verify: tests pass

### 4. Add logVerbose calls to overlay mode path
- Currently only CLI path uses `logVerbose()`. Add key events to overlay mode:
  - App launch (overlay mode started, screen count)
  - Key press received (which key)
  - Window gather triggered (target screen)
  - Window gather result (count moved)
- Verify: `make build && make run` writes to `~/Library/Logs/GatherWindows.log`

### 5. Final verification
- `make` succeeds (build + test)
- `make release` succeeds and release binary does NOT write to log file
- Debug binary writes timestamped log lines on every run
