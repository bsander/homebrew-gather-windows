APP_NAME = Gather Windows
BINARY_NAME = Gather Windows
BUILD_DIR = .build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR = /Applications
CLI_LINK = /usr/local/bin/gather-windows

.PHONY: build test run release install dev uninstall clean help

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

dev: build ## Symlink debug .app into /Applications (always runs latest build)
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	ln -sf "$(CURDIR)/$(APP_BUNDLE)" "$(INSTALL_DIR)/$(APP_NAME).app"

install: release ## Install release .app to /Applications and CLI symlink
	cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/"
	mkdir -p $(dir $(CLI_LINK))
	ln -sf "$(INSTALL_DIR)/$(APP_NAME).app/Contents/MacOS/$(BINARY_NAME)" "$(CLI_LINK)"

uninstall: ## Remove .app from /Applications and CLI symlink
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	rm -f "$(CLI_LINK)"

clean: ## Remove build artifacts
	swift package clean
	rm -rf .build

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Internal: create .app bundle from built binary
_bundle:
	rm -rf "$(APP_BUNDLE)"
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	cp Info.plist "$(APP_BUNDLE)/Contents/"
	@if [ "$(CONFIG)" = "universal" ]; then \
		cp "$(BUILD_DIR)/universal/$(BINARY_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"; \
	else \
		cp "$(BUILD_DIR)/$(CONFIG)/$(BINARY_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"; \
	fi
