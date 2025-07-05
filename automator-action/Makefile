# Makefile for Remove Image Background Automator Action
# Uses calendar-based versioning (YYYY.MM.DD)

# Get current date in YYYY.MM.DD format
VERSION := $(shell date +%Y.%m.%d)

# Directories
ACTION_NAME = Remove Image Backgrounds.action
ACTION_DIR = $(ACTION_NAME)/Contents
BG_REMOVER_PATH := ../bg-remover-rollup/bg-remover

# Default target
all: build

# Build the action
build: $(ACTION_DIR)/Info.plist executable check-bg-remover copy-bg-remover
	@echo "Built $(ACTION_NAME) version $(VERSION)"

# Generate Info.plist from template
$(ACTION_DIR)/Info.plist: Info.plist.template
	@mkdir -p "$(ACTION_DIR)"
	@sed 's/{{VERSION}}/$(VERSION)/g' Info.plist.template > "$(ACTION_DIR)/Info.plist"
	@echo "Generated Info.plist with version $(VERSION)"

# Build the executable
executable: RemoveImageBackground.m
	@mkdir -p "$(ACTION_DIR)/MacOS"
	@mkdir -p "$(ACTION_DIR)/Resources"
	@gcc -framework Foundation -framework Automator -bundle \
		-o "$(ACTION_DIR)/MacOS/Remove Image Backgrounds" \
		RemoveImageBackground.m
	@cp main.sh "$(ACTION_DIR)/Resources/main.sh"
	@chmod +x "$(ACTION_DIR)/Resources/main.sh"
	@echo "Built executable"

# Check if bg-remover exists
check-bg-remover:
	@if [ ! -f "$(BG_REMOVER_PATH)" ]; then \
		echo "Error: bg-remover not found at $(BG_REMOVER_PATH)"; \
		echo "Please build bg-remover first"; \
		exit 1; \
	fi

# Copy bg-remover bundle into the action
copy-bg-remover: check-bg-remover
	@echo "Copying bg-remover bundle..."
	@mkdir -p "$(ACTION_DIR)/Resources"
	@cp -R ../bg-remover-rollup/* "$(ACTION_DIR)/Resources/"
	@echo "Copied bg-remover bundle to action"

# Install to user's Automator actions folder
install: build
	@mkdir -p ~/Library/Automator
	@cp -R "$(ACTION_NAME)" ~/Library/Automator/
	@echo "Installed $(ACTION_NAME) to ~/Library/Automator/"

# Uninstall from user's Automator actions folder
uninstall:
	@rm -rf "~/Library/Automator/$(ACTION_NAME)"
	@echo "Uninstalled $(ACTION_NAME)"

# Clean build artifacts
clean:
	@rm -f "$(ACTION_DIR)/Info.plist"
	@echo "Cleaned build artifacts"

# Show current version
version:
	@echo "Current version: $(VERSION)"


# Package the action for distribution
package: build
	@zip -r "RemoveImageBackground-$(VERSION).zip" "$(ACTION_NAME)"
	@echo "Created RemoveImageBackground-$(VERSION).zip"

.PHONY: all build executable check-bg-remover copy-bg-remover install uninstall clean version package