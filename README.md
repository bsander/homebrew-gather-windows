> **Note:** This is the Homebrew tap branch. Source code and development happens on the [`main` branch](https://github.com/bsander/homebrew-gather-windows/tree/main).

# gather-windows

A macOS app that shows numbered overlays on each screen, letting you pick a target display to gather all windows to. Also supports CLI mode when invoked with arguments.

## Installation

### Homebrew (recommended)

```bash
brew install bsander/gather-windows/gather-windows
```

### From source

```bash
git clone https://github.com/bsander/homebrew-gather-windows.git
cd homebrew-gather-windows
make install
```

## Prerequisites

**Accessibility permission** is required. On first launch the app will prompt you to grant access in **System Settings > Privacy & Security > Accessibility**. Relaunch after granting permission.

## Usage

### App mode

Double-click the app or run `open "/Applications/Gather Windows.app"`. Numbered overlays appear on each screen — press a number key to gather all windows to that display. Press Escape to cancel.

### CLI mode

```
gather-windows <target-display-number>
gather-windows --list
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `<number>` | Target display number to gather all windows to |
| `--list` | List all displays with their numbers |

## Development

```bash
make build    # Debug build
make test     # Run tests
make dev      # Install debug build to /Applications
make run      # Build and launch
make release  # Build universal release binary
make install  # Install release build to /Applications
```

## License

MIT
