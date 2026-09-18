#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${SHORTCUT_BUILD_DIR:-$PROJECT_DIR/.build-local}"
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$BUILD_DIR/module-cache"
swift test --package-path "$PROJECT_DIR" --scratch-path "$BUILD_DIR/build" --cache-path "$BUILD_DIR/cache" --disable-sandbox
