#!/bin/bash

set -euo pipefail

# CONFIGURATION
FRAMEWORK_NAME="CrowdinSDK"
SCHEME_NAME="CrowdinSDK"
CONFIGURATION="Release"
BUILD_DIR="build"
OUTPUT_DIR="output"
XCFRAMEWORK_NAME="${FRAMEWORK_NAME}.xcframework"

# Clean previous builds
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Build for iOS Devices
xcodebuild archive \
  -scheme "$SCHEME_NAME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -archivePath "$BUILD_DIR/ios_devices.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build for iOS Simulator
xcodebuild archive \
  -scheme "$SCHEME_NAME" \
  -configuration "$CONFIGURATION" \
  -sdk iphonesimulator \
  -archivePath "$BUILD_DIR/ios_simulator.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Create XCFramework
xcodebuild -create-xcframework \
  -framework "$BUILD_DIR/ios_devices.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -framework "$BUILD_DIR/ios_simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -output "$OUTPUT_DIR/$XCFRAMEWORK_NAME"

echo "✅ XCFramework created at $OUTPUT_DIR/$XCFRAMEWORK_NAME"
