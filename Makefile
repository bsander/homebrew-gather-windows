APP_NAME = Gather Windows
BINARY_NAME = Gather Windows
BUILD_DIR = .build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR = /Applications
CLI_LINK = /usr/local/bin/gather-windows
CODESIGN_IDENTITY = Gather Windows Dev

.PHONY: build test run release install dev uninstall clean help setup-codesign icon

build: ## Build debug .app bundle
	swift build --disable-sandbox
	$(MAKE) _bundle CONFIG=debug

test: ## Run tests
	swift test --disable-sandbox

run: build ## Build and launch the app
	open "$(APP_BUNDLE)"

release: ## Build universal release .app bundle
	swift build -c release --disable-sandbox --arch arm64
	swift build -c release --disable-sandbox --arch x86_64
	mkdir -p $(BUILD_DIR)/universal
	lipo -create \
		"$(BUILD_DIR)/arm64-apple-macosx/release/$(BINARY_NAME)" \
		"$(BUILD_DIR)/x86_64-apple-macosx/release/$(BINARY_NAME)" \
		-output "$(BUILD_DIR)/universal/$(BINARY_NAME)"
	$(MAKE) _bundle CONFIG=universal

dev: build ## Copy debug .app into /Applications (run after each build)
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/$(APP_NAME).app"

install: release ## Install release .app to /Applications
	cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/"

uninstall: ## Remove .app from /Applications and CLI symlink
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	rm -f "$(CLI_LINK)"

clean: ## Remove build artifacts
	swift package clean
	rm -rf .build

icon: ## Regenerate AppIcon.icns from appicon.png
	mkdir -p AppIcon.iconset
	@for size in 16 32 128 256 512; do \
		sips -z $$size $$size assets/appicon.png --out "AppIcon.iconset/icon_$${size}x$${size}.png" >/dev/null 2>&1; \
		double=$$((size * 2)); \
		sips -z $$double $$double assets/appicon.png --out "AppIcon.iconset/icon_$${size}x$${size}@2x.png" >/dev/null 2>&1; \
	done
	iconutil -c icns AppIcon.iconset -o AppIcon.icns
	rm -rf AppIcon.iconset
	sips -z 128 128 assets/appicon.png --out assets/appicon-128.png >/dev/null 2>&1
	@echo "AppIcon.icns and assets/appicon-128.png regenerated from appicon.png"

setup-codesign: ## Create self-signed cert for persistent TCC permissions
	@bash scripts/create-codesign-cert.sh "$(CODESIGN_IDENTITY)"

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Internal: create .app bundle from built binary
_bundle:
	rm -rf "$(APP_BUNDLE)"
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS" "$(APP_BUNDLE)/Contents/Resources"
	cp Info.plist "$(APP_BUNDLE)/Contents/"
	cp AppIcon.icns "$(APP_BUNDLE)/Contents/Resources/"
	@if [ "$(CONFIG)" = "universal" ]; then \
		cp "$(BUILD_DIR)/universal/$(BINARY_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"; \
	else \
		cp "$(BUILD_DIR)/$(CONFIG)/$(BINARY_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"; \
	fi
	@if security find-identity -v -p codesigning 2>/dev/null | grep -q "$(CODESIGN_IDENTITY)"; then \
		echo "Signing with '$(CODESIGN_IDENTITY)'..."; \
		codesign --force --sign "$(CODESIGN_IDENTITY)" "$(APP_BUNDLE)"; \
	else \
		echo "\033[33mWarning: Certificate '$(CODESIGN_IDENTITY)' not found. Using ad-hoc signing.\033[0m"; \
		echo "\033[33mTCC permissions will reset each build. Run 'make setup-codesign' to fix.\033[0m"; \
		codesign --force --sign - "$(APP_BUNDLE)"; \
	fi
