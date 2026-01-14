#!/bin/bash

# Sales Calculator UI Test Runner
# Runs XCUITests and generates results

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Sales Calculator UI Test Runner"
echo "=================================="
echo ""

# Configuration
WORKSPACE="CardShowPro.xcworkspace"
SCHEME="CardShowPro"
SIMULATOR="iPhone 16"
RESULT_BUNDLE="TestResults.xcresult"

# Check if simulator is available
echo "📱 Checking simulator..."
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 16 (" | grep -v "unavailable" | head -1 | sed 's/.*(\(.*\)).*/\1/')

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${RED}❌ iPhone 16 simulator not found${NC}"
    echo "Available simulators:"
    xcrun simctl list devices | grep "iPhone"
    exit 1
fi

echo -e "${GREEN}✅ Found simulator: $SIMULATOR_ID${NC}"

# Boot simulator if not booted
SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -o "Booted\|Shutdown")
if [ "$SIMULATOR_STATE" = "Shutdown" ]; then
    echo "🚀 Booting simulator..."
    xcrun simctl boot "$SIMULATOR_ID"
    sleep 3
else
    echo -e "${GREEN}✅ Simulator already booted${NC}"
fi

# Clean previous test results
if [ -d "$RESULT_BUNDLE" ]; then
    echo "🧹 Cleaning previous test results..."
    rm -rf "$RESULT_BUNDLE"
fi

# Run tests
echo ""
echo "🧪 Running tests..."
echo "Workspace: $WORKSPACE"
echo "Scheme: $SCHEME"
echo "Destination: iPhone 16"
echo ""

xcodebuild test \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    -resultBundlePath "$RESULT_BUNDLE" \
    -enableCodeCoverage YES \
    2>&1 | tee test_output.log | xcpretty --color --simple || true

# Check if tests passed
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""

    # Parse results
    echo "📊 Test Results:"
    xcrun xcresulttool get --format json --path "$RESULT_BUNDLE" > test_results.json 2>/dev/null || true

    if [ -f test_results.json ]; then
        # Count pass/fail (simple approach)
        PASSED=$(grep -o '"testStatus":"Success"' test_results.json | wc -l | tr -d ' ')
        FAILED=$(grep -o '"testStatus":"Failure"' test_results.json | wc -l | tr -d ' ')

        echo -e "${GREEN}✅ Passed: $PASSED${NC}"
        if [ "$FAILED" -gt 0 ]; then
            echo -e "${RED}❌ Failed: $FAILED${NC}"
        fi

        rm test_results.json
    fi

    echo ""
    echo "📸 Screenshots saved in: $RESULT_BUNDLE"
    echo ""
    echo "To view results:"
    echo "  open $RESULT_BUNDLE"
    echo ""

    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed${NC}"
    echo ""
    echo "📋 View detailed results:"
    echo "  open $RESULT_BUNDLE"
    echo ""
    echo "📄 Or check the log:"
    echo "  cat test_output.log"
    echo ""

    exit 1
fi
