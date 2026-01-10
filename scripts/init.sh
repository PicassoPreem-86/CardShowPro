#!/bin/bash

# CardShowPro - Project Baseline Verification Script
# This script verifies the project builds and tests pass

set -e

WORKSPACE_PATH="/Users/preem/Desktop/CardshowPro/CardShowPro.xcworkspace"
SCHEME="CardShowPro"
SIMULATOR_NAME="iPhone 16"

echo "🔍 Verifying CardShowPro baseline..."
echo ""

# Check workspace exists
if [ ! -d "$WORKSPACE_PATH" ]; then
    echo "❌ Error: Workspace not found at $WORKSPACE_PATH"
    exit 1
fi

echo "✅ Workspace found"

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found. Install Xcode Command Line Tools."
    exit 1
fi

echo "✅ Xcode Command Line Tools installed"

# List available simulators to find iPhone 16
echo ""
echo "📱 Finding iPhone 16 simulator..."
# Use xcodebuild to get the exact destination
DESTINATION="platform=iOS Simulator,name=iPhone 16"

# Verify simulator exists
if ! xcrun simctl list devices available | grep -q "iPhone 16 ("; then
    echo "⚠️  Warning: iPhone 16 not found, using any available iPhone..."
    FIRST_IPHONE=$(xcrun simctl list devices available | grep "iPhone" | head -n 1 | sed -E 's/^[[:space:]]+(.+) \([0-9A-F-]+\) \(.+\)$/\1/')
    DESTINATION="platform=iOS Simulator,name=$FIRST_IPHONE"
fi

echo "✅ Using destination: $DESTINATION"

# Clean build folder
echo ""
echo "🧹 Cleaning build artifacts..."
xcodebuild clean \
    -workspace "$WORKSPACE_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    > /dev/null 2>&1

echo "✅ Clean complete"

# Build for simulator
echo ""
echo "🔨 Building project for simulator..."
xcodebuild build \
    -workspace "$WORKSPACE_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "$DESTINATION" \
    -quiet

echo "✅ Build succeeded"

# Run tests
echo ""
echo "🧪 Running tests..."
xcodebuild test \
    -workspace "$WORKSPACE_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "$DESTINATION" \
    -quiet

echo "✅ Tests passed"

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Baseline verification complete!"
echo ""
echo "Project: CardShowPro"
echo "Status: ✅ Ready for development"
echo "Workspace: $WORKSPACE_PATH"
echo "Scheme: $SCHEME"
echo "Destination: $DESTINATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Review ai/FEATURES.json for planned features"
echo "  2. Choose ONE feature marked 'passes': false"
echo "  3. Implement smallest complete solution"
echo "  4. Test like a real user"
echo "  5. Mark feature passing only after end-to-end testing"
echo "  6. Update ai/PROGRESS.md"
echo "  7. Commit changes"
echo ""
