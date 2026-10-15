#!/bin/bash

# Builds CrowdinSDK.xcframework and packages it for a GitHub release.
#
#   ./build.sh                 build, check and package (signed by Xcode's automatic signing)
#   ./build.sh --package-only  check and package an existing output/CrowdinSDK.xcframework
#
# Partners build on Xcode 26.x, and a newer Xcode writes Swift interfaces they cannot
# parse, so the build refuses any other Xcode major. Pick the toolchain per command:
#   DEVELOPER_DIR=/Applications/Xcode_26.3.0.app/Contents/Developer ./build.sh
# ALLOW_XCODE_MAJOR=<n> lets another major build; check_xcframework.sh still has to pass.
#
# EXTRA_XCODEBUILD_SETTINGS adds settings to both archives. Over SSH the login keychain is
# locked and codesign fails with errSecInternalComponent, so build unsigned there:
#   EXTRA_XCODEBUILD_SETTINGS="CODE_SIGNING_ALLOWED=NO" ./build.sh
# then copy output/CrowdinSDK.xcframework to a Mac with the signing identity, sign each
# slice and repackage:
#   codesign --force --sign <identity> --timestamp=none --generate-entitlement-der \
#     output/CrowdinSDK.xcframework/<slice>/CrowdinSDK.framework
#   ./build.sh --package-only
#
# Upload output/CrowdinSDK.xcframework.zip to the release and use the printed checksum
# in every binaryTarget pin.

set -euo pipefail

cd "$(dirname "$0")"

# CONFIGURATION
FRAMEWORK_NAME="CrowdinSDK"
SCHEME_NAME="CrowdinSDK"
CONFIGURATION="Release"
BUILD_DIR="build"
OUTPUT_DIR="output"
XCFRAMEWORK_NAME="${FRAMEWORK_NAME}.xcframework"
REQUIRED_XCODE_MAJOR="26"

require_supported_xcode() {
  local xcode_version xcode_major
  xcode_version=$(xcodebuild -version | awk 'NR == 1 { print $2 }')
  xcode_major="${xcode_version%%.*}"
  if [[ "$xcode_major" != "$REQUIRED_XCODE_MAJOR" && "$xcode_major" != "${ALLOW_XCODE_MAJOR:-}" ]]; then
    echo "error: Xcode $xcode_version is selected; CrowdinSDK releases are built with Xcode $REQUIRED_XCODE_MAJOR.x." >&2
    echo "Run with DEVELOPER_DIR=/Applications/Xcode_26.3.0.app/Contents/Developer, or set ALLOW_XCODE_MAJOR=$xcode_major to override." >&2
    exit 1
  fi
  echo "Building with Xcode $xcode_version"
}

archive() {
  local sdk="$1" archive_path="$2"
  local extra_settings=()
  read -r -a extra_settings <<< "${EXTRA_XCODEBUILD_SETTINGS:-}"
  xcodebuild archive \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION" \
    -sdk "$sdk" \
    -archivePath "$archive_path" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ${extra_settings[@]+"${extra_settings[@]}"}
}

build() {
  require_supported_xcode

  # Clean previous builds
  rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"

  archive iphoneos "$BUILD_DIR/ios_devices.xcarchive"
  archive iphonesimulator "$BUILD_DIR/ios_simulator.xcarchive"

  xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/ios_devices.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "$BUILD_DIR/ios_simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "$OUTPUT_DIR/$XCFRAMEWORK_NAME"

  echo "✅ XCFramework created at $OUTPUT_DIR/$XCFRAMEWORK_NAME"
}

warn_unsigned_slices() {
  local framework
  for framework in "$OUTPUT_DIR/$XCFRAMEWORK_NAME"/*/"$FRAMEWORK_NAME.framework"; do
    if ! codesign --verify --strict "$framework" 2>/dev/null; then
      echo "⚠️  ${framework#"$OUTPUT_DIR/"} is not signed: sign it, then run ./build.sh --package-only before publishing." >&2
    fi
  done
}

package() {
  local zip_name="$XCFRAMEWORK_NAME.zip" checksum
  # Extended attributes would land in the zip as __MACOSX entries.
  xattr -cr "$OUTPUT_DIR/$XCFRAMEWORK_NAME"
  rm -f "$OUTPUT_DIR/$zip_name"
  (cd "$OUTPUT_DIR" && ditto -c -k --norsrc --keepParent "$XCFRAMEWORK_NAME" "$zip_name")
  checksum=$(shasum -a 256 "$OUTPUT_DIR/$zip_name" | awk '{ print $1 }')
  echo "✅ $OUTPUT_DIR/$zip_name"
  echo "   checksum: $checksum"
  warn_unsigned_slices
}

case "${1:-}" in
  "") build ;;
  --package-only)
    if [[ ! -d "$OUTPUT_DIR/$XCFRAMEWORK_NAME" ]]; then
      echo "error: $OUTPUT_DIR/$XCFRAMEWORK_NAME not found; run ./build.sh first" >&2
      exit 1
    fi
    ;;
  *)
    echo "usage: $0 [--package-only]" >&2
    exit 2
    ;;
esac

bash ./check_xcframework.sh "$OUTPUT_DIR/$XCFRAMEWORK_NAME"
package
