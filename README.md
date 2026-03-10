# Gather Windows

macOS app that shows numbered overlays on each screen, letting you pick a target display to gather all windows to. Also supports CLI mode when invoked with arguments.

## Prerequisites

**Accessibility permission** is required. Grant access in **System Settings > Privacy & Security > Accessibility** before using the app. Without it, window moves will silently fail.

## Install

```
make install
```

Builds a universal release binary and copies `Gather Windows.app` to `/Applications/`.

## Usage

**App mode** (double-click or `open`): Shows numbered overlays on each screen. Press a number key to gather all windows to that display. Press Escape to cancel.

**CLI mode**:

```
gather-windows <target-display-number>
gather-windows --list
```

## Development

```
make build    # Debug build
make test     # Run tests
make dev      # Install debug build to /Applications
make run      # Build and launch
```
