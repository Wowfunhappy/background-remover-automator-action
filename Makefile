# Main Makefile for bg-remover-cli and Automator Action
# Builds both the bg-remover bundle and the macOS Automator action

# Directories
BUNDLE_DIR = bg-remover-rollup
ACTION_DIR = automator-action
ACTION_NAME = Remove Image Backgrounds.action

# CC shim for OS X compatibility
SHIM_LIB = libccshim.dylib

# Default target
all: bundle action

# Build the CC shim for OS X compatibility
$(SHIM_LIB): cc_shim.c
	@echo "Building CC shim for OS X compatibility..."
	@gcc -shared -fPIC -o $(SHIM_LIB) cc_shim.c
	@echo "CC shim built successfully"

# Build the bg-remover bundle using Rollup
bundle: check-deps
	@echo "Building bg-remover bundle..."
	# Run Rollup to create bundle
	@if [ ! -f "$(BUNDLE_DIR)/bundle.js" ]; then \
		echo "Creating Rollup bundle..."; \
		$(MAKE) $(SHIM_LIB); \
		DYLD_FORCE_FLAT_NAMESPACE=1 DYLD_INSERT_LIBRARIES="$(PWD)/$(SHIM_LIB)" npm run build:rollup; \
	fi
	# Copy node binary
	@if [ ! -f "$(BUNDLE_DIR)/node" ]; then \
		echo "Copying node binary..."; \
		cp "$$(which node)" "$(BUNDLE_DIR)/node"; \
	fi
	# Copy ONNX runtime files
	@if [ ! -f "$(BUNDLE_DIR)/ort-wasm-simd-threaded.wasm" ]; then \
		echo "Copying ONNX runtime files..."; \
		cp node_modules/onnxruntime-web/dist/*.wasm "$(BUNDLE_DIR)/" 2>/dev/null || true; \
		cp node_modules/onnxruntime-web/dist/*.mjs "$(BUNDLE_DIR)/" 2>/dev/null || true; \
	fi
	# Copy resources
	@if [ ! -d "$(BUNDLE_DIR)/resources" ]; then \
		echo "Copying model resources..."; \
		mkdir -p "$(BUNDLE_DIR)/resources/@imgly/background-removal-node/dist"; \
		cp -r node_modules/@imgly/background-removal-node/dist/* "$(BUNDLE_DIR)/resources/@imgly/background-removal-node/dist/" 2>/dev/null || true; \
	fi
	# Copy only required external modules (jimp and its dependencies)
	@if [ ! -d "$(BUNDLE_DIR)/node_modules" ]; then \
		echo "Copying required external modules..."; \
		mkdir -p "$(BUNDLE_DIR)/node_modules"; \
		echo "Copying jimp and all its dependencies..."; \
		rm -rf temp_jimp && mkdir -p temp_jimp; \
		cd temp_jimp && npm init -y --silent >/dev/null 2>&1; \
		npm install jimp@0.16.13 --silent >/dev/null 2>&1; \
		cd ..; \
		cp -r temp_jimp/node_modules/* "$(BUNDLE_DIR)/node_modules/" 2>/dev/null || true; \
		rm -rf temp_jimp; \
		echo "External modules copied"; \
	fi
	# Create launcher script
	@echo "Creating launcher script..."
	@echo '#!/bin/bash' > "$(BUNDLE_DIR)/bg-remover"
	@echo 'DIR="$$(cd "$$(dirname "$${BASH_SOURCE[0]}")" && pwd)"' >> "$(BUNDLE_DIR)/bg-remover"
	@echo 'export NODE_PATH="$$DIR/node_modules:$$NODE_PATH"' >> "$(BUNDLE_DIR)/bg-remover"
	@echo 'export ONNX_WASM_PATHS="$$DIR"' >> "$(BUNDLE_DIR)/bg-remover"
	@echo 'export IMGLY_PUBLIC_PATH="file://$$DIR/resources/@imgly/background-removal-node/dist/"' >> "$(BUNDLE_DIR)/bg-remover"
	@echo 'export ONNXRUNTIME_WEB_BASE_PATH="$$DIR/"' >> "$(BUNDLE_DIR)/bg-remover"
	@echo '"$$DIR/node" "$$DIR/bundle.js" "$$@"' >> "$(BUNDLE_DIR)/bg-remover"
	@chmod +x "$(BUNDLE_DIR)/bg-remover"
	@echo "Bundle created in $(BUNDLE_DIR)/"

# Build the Automator action
action: bundle
	@echo "Building Automator action..."
	@$(MAKE) -C $(ACTION_DIR) build
	@echo "Action built successfully"

# Generate package.json if it doesn't exist
package.json:
	@echo "Initializing npm project..."
	@npm init -y
	@echo "Installing production dependencies..."
	@npm install @imgly/background-removal-node@^1.4.5 chalk@^4.1.2 commander@^11.1.0 jimp@^0.16.13 onnxruntime-web@^1.22.0 ora@^5.4.1
	@echo "Installing dev dependencies..."
	@npm install --save-dev @rollup/plugin-commonjs@^28.0.6 @rollup/plugin-json@^6.1.0 @rollup/plugin-node-resolve@^16.0.1 @vercel/ncc@^0.38.3 buffer@^6.0.3 path-browserify@^1.0.1 pkg@^5.8.1 rollup@^4.44.2 webpack@^5.99.9 webpack-cli@^6.0.1 webpack-node-externals@^3.0.0
	@echo "Adding build scripts..."
	@npm pkg set scripts.build="pkg . --targets node18-macos-x64 --output bg-remover"
	@npm pkg set scripts.build:rollup="rollup -c rollup-complete.config.js"
	@npm pkg set main="cli.js"
	@npm pkg set bin.bg-remover="./cli.js"
	@npm pkg set description="Command line tool for removing backgrounds from images"
	@npm pkg set keywords="background-removal image-processing cli"
	@echo "package.json generated successfully"

# Check dependencies
check-deps: package.json
	@if [ ! -d "node_modules" ]; then \
		echo "Installing dependencies..."; \
		npm install; \
	fi

# Install the Automator action
install: install-action

install-action: action
	@$(MAKE) -C $(ACTION_DIR) install

# Clean all build artifacts and dependencies
clean:
	@echo "Cleaning all build artifacts and dependencies..."
	# Clean bg-remover-rollup build artifacts
	@rm -f $(BUNDLE_DIR)/bg-remover
	@rm -f $(BUNDLE_DIR)/node
	@rm -f $(BUNDLE_DIR)/bundle.js
	@rm -f $(BUNDLE_DIR)/*.mjs
	@rm -f $(BUNDLE_DIR)/*.wasm
	@rm -rf $(BUNDLE_DIR)/node_modules
	@rm -rf $(BUNDLE_DIR)/resources
	# Clean automator-action
	@rm -rf "$(ACTION_DIR)/$(ACTION_NAME)"
	@rm -f $(ACTION_DIR)/RemoveImageBackground
	# Clean root directory
	@rm -rf node_modules
	@rm -rf node_modules_prod
	@rm -f package-lock.json
	@rm -f package.json
	@rm -f $(SHIM_LIB)
	@echo "Clean complete"

# Run the rollup build script
build-rollup: check-deps $(SHIM_LIB)
	@echo "Running Rollup build..."
	@DYLD_FORCE_FLAT_NAMESPACE=1 DYLD_INSERT_LIBRARIES="$(PWD)/$(SHIM_LIB)" npx rollup -c rollup-complete.config.js
	@echo "Rollup build complete"

# Create a distributable package
dist: action
	@echo "Creating distribution package..."
	@$(MAKE) -C $(ACTION_DIR) package
	@echo "Distribution package created"

# Show help
help:
	@echo "Available targets:"
	@echo "  make all          - Build both bundle and action (default)"
	@echo "  make bundle       - Build only the bg-remover bundle"
	@echo "  make action       - Build only the Automator action"
	@echo "  make install      - Build and install action to ~/Library/Automator"
	@echo "  make clean        - Remove all build artifacts and dependencies"
	@echo "  make dist         - Create distributable package"
	@echo "  make help         - Show this help message"

.PHONY: all bundle action check-deps install install-action clean build-rollup dist help