#!/bin/bash
#
# Nudge Pro - DMG Creation Script
# 
# This script creates a distributable DMG file for Nudge Pro.
# It packages the built app with necessary resources.
#

set -e

# Configuration
APP_NAME="Nudge Pro"
APP_BUNDLE="NudgePro.app"
DMG_NAME="NudgePro-${VERSION:-1.0.0}.dmg"
VOL_NAME="Nudge Pro"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SOURCE_DIR}/build"
DMG_DIR="${SOURCE_DIR}/dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check for Xcode build
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode not found. Please install Xcode."
        exit 1
    fi
    
    # Check for create-dmg
    if ! command -v create-dmg &> /dev/null; then
        log_warn "create-dmg not found. Installing..."
        brew install create-dmg
    fi
    
    log_info "Prerequisites check passed."
}

# Clean previous builds
clean() {
    log_info "Cleaning previous builds..."
    rm -rf "${BUILD_DIR}"
    rm -rf "${DMG_DIR}"
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${DMG_DIR}"
}

# Build the app
build_app() {
    log_info "Building Nudge Pro..."
    
    cd "${SOURCE_DIR}"
    
    # Generate xcodeproj if needed
    if [ ! -f "NudgePro.xcodeproj/project.pbxproj" ]; then
        log_info "Generating Xcode project..."
        xcodegen generate
    fi
    
    # Build for release
    xcodebuild -project NudgePro.xcodeproj \
               -scheme NudgePro \
               -configuration Release \
               -destination 'generic/platform=macOS' \
               build
    
    log_info "Build completed."
}

# Create DMG
create_dmg() {
    log_info "Creating DMG..."
    
    # Find the built app
    APP_PATH=""
    SEARCH_PATHS=(
        "${SOURCE_DIR}/build/Release/${APP_BUNDLE}"
        "${HOME}/Library/Developer/Xcode/DerivedData/"*/Build/Products/Release/${APP_BUNDLE}
    )
    
    for path in "${SEARCH_PATHS[@]}"; do
        if [ -e "$path" ]; then
            APP_PATH="$path"
            break
        fi
    done
    
    if [ -z "$APP_PATH" ]; then
        # Try default xcodebuild location
        APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${APP_BUNDLE}" -type d 2>/dev/null | head -1)
    fi
    
    if [ -z "$APP_PATH" ] || [ ! -e "$APP_PATH" ]; then
        log_error "Built app not found. Please build first."
        exit 1
    fi
    
    log_info "Using app at: ${APP_PATH}"
    
    # Copy to build directory
    cp -R "${APP_PATH}" "${BUILD_DIR}/"
    
    # Create DMG
    create-dmg \
        --volname "${VOL_NAME}" \
        --window-pos 200 200 \
        --window-size 600 400 \
        --icon-size 100 \
        --app-drop-link 425 175 \
        --vol-icon "${SOURCE_DIR}/NudgePro/Resources/app-icon.icns" \
        "${DMG_DIR}/${DMG_NAME}" \
        "${BUILD_DIR}/${APP_BUNDLE}"
    
    log_info "DMG created: ${DMG_DIR}/${DMG_NAME}"
}

# Sign and notarize (optional)
sign_and_notarize() {
    if [ -z "${APPLE_ID}" ]; then
        log_warn "APPLE_ID not set. Skipping signing."
        return
    fi
    
    log_info "Signing and notarizing..."
    
    # Sign the app
    codesign --force --deep --sign "Developer ID Application" "${BUILD_DIR}/${APP_BUNDLE}"
    
    # Create zip for notarization
    cd "${BUILD_DIR}"
    zip -r "${APP_BUNDLE}.zip" "${APP_BUNDLE}"
    
    # Upload for notarization
    xcrun altool --notarize-app \
        --primary-bundle-id "com.nudge.pro" \
        --username "${APPLE_ID}" \
        --password "@keychain:AC_PASSWORD" \
        --file "${APP_BUNDLE}.zip"
    
    log_info "Notarization submitted. Check status with:"
    echo "  xcrun altool --notarization-info <UUID> -u ${APPLE_ID}"
}

# Main
main() {
    VERSION="${1:-1.0.0}"
    
    log_info "Creating Nudge Pro DMG v${VERSION}"
    log_info "Source: ${SOURCE_DIR}"
    
    check_prerequisites
    clean
    build_app
    create_dmg
    
    log_info "Done!"
    echo ""
    echo "Output: ${DMG_DIR}/${DMG_NAME}"
}

# Run
main "$@"
