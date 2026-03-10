# Gather Windows — macOS App Design

## Overview

Transform the CLI tool into a macOS app ("Gather Windows") that detects all screens, shows a fullscreen numbered overlay on each, waits for the user to type a number to select the target screen, gathers all windows there, and quits. The binary also supports CLI mode when invoked with arguments.

## Architecture

**Single binary, dual mode** inside an `.app` bundle:
- **No args** (double-click / Spotlight): Overlay mode
- **With args** (`gather-windows 2` or `gather-windows main`): CLI mode, no UI

`LSUIElement = true` — no dock icon, no menu bar.

Users can symlink `Gather Windows.app/Contents/MacOS/Gather Windows` to `/usr/local/bin/gather-windows` for CLI access.

## Screen Numbering

- macOS main display = **1** (always)
- Remaining screens numbered **2, 3, ...** sorted left-to-right by `frame.origin.x`
- CLI accepts: number (`1`, `2`) or `main` (alias for `1`)

## Overlay Mode Flow

```
Launch → assignNumbers() → create OverlayWindow per screen
→ listen for keyDown (number keys + Escape)
→ valid number pressed → close overlays → gather windows to that screen → quit
→ Escape pressed → close overlays → quit
→ invalid number → ignore (no-op)
```

## Overlay Window Spec

- `NSWindow`, `styleMask: .borderless`, `level: .screenSaver`
- `backgroundColor: NSColor.black.withAlphaComponent(0.7)`
- `collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]`
- Frame = `screen.frame`
- Content: SwiftUI view with large white number (~200pt system font), centered
- `ignoresMouseEvents = true` on non-key windows

## CLI Mode Flow

```
Launch with args → parse number or "main"
→ resolve to screen → gather windows → exit(0)
→ invalid arg → print usage to stderr → exit(1)
```

## Error Handling

- **Single screen**: Show macOS toast notification ("Only one screen detected"), quit
- **No accessibility permission**: Prompt user (existing behavior), quit
- **Invalid CLI arg**: Print usage, exit(1)
- **Invalid keypress**: Ignore

## Project Structure

```
Sources/GatherWindows/
  App.swift                 — @main, routes CLI vs overlay
  OverlayWindow.swift       — NSWindow subclass per screen
  OverlayView.swift         — SwiftUI: big number on dark bg
  ScreenNumbering.swift     — Number assignment logic
  KeyboardHandler.swift     — NSEvent monitor

  # Modified existing:
  DisplayManager.swift      — Target display selection
  WindowManager.swift       — Accept arbitrary target
  CLI.swift                 — Parse number/main arg

  # Unchanged existing:
  Models.swift, Protocols.swift, BoundsCalculator.swift, Logger.swift
```

## Tech Choices

- SwiftUI App lifecycle + AppKit `NSWindow` for overlay placement
- `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` for keyboard
- `UNUserNotificationCenter` for toast on single-screen error
- swift-argument-parser removed (overkill for one optional positional arg)
