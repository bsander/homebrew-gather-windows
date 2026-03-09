PREFIX ?= /usr/local
BINARY_NAME = gather-windows
BUILD_DIR = .build/universal

.PHONY: build test release install dev uninstall clean help

build: ## Build debug binary
	swift build --disable-sandbox

test: ## Run tests
	swift test --disable-sandbox

release: ## Build universal release binary (CI)
	swift build -c release --disable-sandbox --arch arm64
	swift build -c release --disable-sandbox --arch x86_64
	mkdir -p .build/universal
	lipo -create \
		.build/arm64-apple-macosx/release/gather-windows \
		.build/x86_64-apple-macosx/release/gather-windows \
		-output .build/universal/gather-windows

install: release ## Copy binary to PREFIX/bin (used by Homebrew)
	install -d $(PREFIX)/bin
	install $(BUILD_DIR)/$(BINARY_NAME) $(PREFIX)/bin/$(BINARY_NAME)

dev: build ## Symlink binary to PREFIX/bin (for local development)
	install -d $(PREFIX)/bin
	ln -sf $(realpath .build/debug/$(BINARY_NAME)) $(PREFIX)/bin/$(BINARY_NAME)

uninstall: ## Remove binary from PREFIX/bin
	rm -f $(PREFIX)/bin/$(BINARY_NAME)

clean: ## Remove build artifacts
	swift package clean
	rm -rf .build

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
