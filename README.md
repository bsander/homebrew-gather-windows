<p align="center">
  <img src="assets/appicon-128-rounded.png" width="128" height="128">
</p>

# Gather Windows

Gather all your windows onto a single display instantly.

## Installation

### Homebrew (recommended)

**App** (installs to /Applications):

```bash
brew install --cask bsander/gather-windows/gather-windows
```

**CLI only**:

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
gather-windows main
gather-windows --list
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `<number>` | Target display number to gather all windows to |
| `main` | Alias for screen 1 (the main display) |
| `--list` | List all displays with their numbers |

**Options:**

| Option | Description |
|--------|-------------|
| `--verbose`, `-v` | Show detailed logging |
| `--include-fullscreen` | Move fullscreen windows too |
| `--hide-during-move` | Hide windows before moving |

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
