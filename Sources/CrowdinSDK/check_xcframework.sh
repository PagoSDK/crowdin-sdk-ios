#!/bin/bash

# Fails when an xcframework's Swift interfaces cannot be read by Xcode 26.x.
#
# Swift 6.4 (Xcode 27) writes module selectors such as `Foundation::Bundle` into
# .swiftinterface files. Swift 6.2 and 6.3 reject them ("expected dictionary value type"),
# so every Xcode 26.x consumer of PagoCoreSDK stops compiling. CrowdinSDK 1.2.0 shipped
# like that; 1.2.1 is the same source rebuilt with Xcode 26.3.
#
# Usage: ./check_xcframework.sh path/to/CrowdinSDK.xcframework

set -euo pipefail

XCFRAMEWORK="${1:?usage: $0 path/to/CrowdinSDK.xcframework}"
if [[ ! -d "$XCFRAMEWORK" ]]; then
  echo "error: $XCFRAMEWORK is not a directory" >&2
  exit 1
fi

INTERFACES=()
while IFS= read -r -d '' interface; do
  INTERFACES+=("$interface")
done < <(find "$XCFRAMEWORK" -name '*.swiftinterface' -print0 | sort -z)

if (( ${#INTERFACES[@]} == 0 )); then
  echo "error: no .swiftinterface files in $XCFRAMEWORK; build with BUILD_LIBRARY_FOR_DISTRIBUTION=YES" >&2
  exit 1
fi

FAILED=0
for interface in "${INTERFACES[@]}"; do
  compiler=$(grep -m1 '^// swift-compiler-version:' "$interface" | sed 's|^// swift-compiler-version: ||' || true)
  echo "${interface#"$XCFRAMEWORK"/}: ${compiler:-unknown compiler}"
  if grep -qE '[[:alnum:]_]::[[:alpha:]_]' "$interface"; then
    echo "error: ${interface#"$XCFRAMEWORK"/} uses '::' module selectors, which Xcode 26.x cannot parse. Rebuild with Xcode 26." >&2
    FAILED=1
  fi
done

if (( FAILED )); then
  exit 1
fi
echo "✅ ${#INTERFACES[@]} Swift interfaces are readable by Xcode 26.x"
