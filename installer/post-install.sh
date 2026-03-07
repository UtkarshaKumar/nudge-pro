#!/bin/bash
#
# Nudge Pro - Post-Install Script
#
# This script runs after the DMG is mounted to set up the application.
# It can be customized for additional setup tasks.
#

set -e

APP_NAME="Nudge Pro"
APP_DIR="/Applications/${APP_NAME}.app"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Setting up Nudge Pro...${NC}"

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Python 3 not found. Please install Python 3.11+.${NC}"
    exit 1
fi

# Check for ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${YELLOW}ffmpeg not found. Installing...${NC}"
    if command -v brew &> /dev/null; then
        brew install ffmpeg
    else
        echo -e "${YELLOW}Homebrew not found. Please install ffmpeg manually.${NC}"
    fi
fi

# Check for BlackHole (for audio capture)
if ! command -v BlackHole &> /dev/null && [ ! -d "/Library/Audio/Plug-Ins/HAL/BlackHole.driver" ]; then
    echo -e "${YELLOW}BlackHole not found. It's recommended for audio capture.${NC}"
    echo "Install from: https://github.com/ExistentialAudio/BlackHole"
fi

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "To get started:"
echo "  1. Open Nudge Pro from Applications"
echo "  2. Follow the onboarding wizard"
echo "  3. Grant necessary permissions when prompted"
echo ""
