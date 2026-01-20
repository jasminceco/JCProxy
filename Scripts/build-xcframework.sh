#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="${1:-""}"
if [[ -z "$SRC_DIR" ]]; then
  SRC_DIR="$(cd "$(dirname "$0")/../../JCRequestRecorder" && pwd)"
fi

OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$OUT_DIR/Build"
DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"
XCFRAMEWORK_PATH="$OUT_DIR/Sources/JCProxyBinary/JCProxy.xcframework"

mkdir -p "$BUILD_DIR"

rm -rf "$BUILD_DIR/JCProxy-iOS.xcarchive" "$BUILD_DIR/JCProxy-iOS-Sim.xcarchive" "$XCFRAMEWORK_PATH"

pushd "$SRC_DIR" >/dev/null

xcodebuild archive \
  -scheme JCProxy \
  -destination "generic/platform=iOS" \
  -archivePath "$BUILD_DIR/JCProxy-iOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  INSTALL_SWIFT_MODULES=YES \
  SWIFT_EMIT_MODULE_INTERFACE=YES \
  SWIFT_EMIT_PRIVATE_MODULE_INTERFACE=YES \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  -quiet

# Ensure device swiftmodule artifacts exist in derived data.
xcodebuild build \
  -scheme JCProxy \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -configuration Release \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SWIFT_EMIT_MODULE_INTERFACE=YES \
  SWIFT_EMIT_PRIVATE_MODULE_INTERFACE=YES \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  -quiet

xcodebuild archive \
  -scheme JCProxy \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$BUILD_DIR/JCProxy-iOS-Sim" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  INSTALL_SWIFT_MODULES=YES \
  SWIFT_EMIT_MODULE_INTERFACE=YES \
  SWIFT_EMIT_PRIVATE_MODULE_INTERFACE=YES \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  -quiet

install_modules() {
  local platform="$1"
  local archive_path="$2"
  local framework_path="$archive_path/Products/usr/local/lib/JCProxy.framework"
  local module_src="$DERIVED_DATA_PATH/Build/Intermediates.noindex/ArchiveIntermediates/JCProxy/BuildProductsPath/$platform/JCProxy.swiftmodule"

  if [[ ! -d "$module_src" ]]; then
    module_src="$(find "$DERIVED_DATA_PATH" -type d -name "JCProxy.swiftmodule" | rg -i "$platform" || true)"
    module_src="$(printf "%s\n" "$module_src" | head -n 1)"
  fi

  if [[ -d "$module_src" ]]; then
    mkdir -p "$framework_path/Modules/JCProxy.swiftmodule"
    cp -R "$module_src/"* "$framework_path/Modules/JCProxy.swiftmodule/"
    return
  fi

  local interface_dir
  interface_dir="$(find "$DERIVED_DATA_PATH" -type f -name "JCProxy*.swiftinterface" | rg -i "$platform" || true)"
  interface_dir="$(printf "%s\n" "$interface_dir" | head -n 1)"
  if [[ -n "$interface_dir" ]]; then
    interface_dir="$(dirname "$interface_dir")"
  fi
  if [[ -n "$interface_dir" && -d "$interface_dir" ]]; then
    mkdir -p "$framework_path/Modules/JCProxy.swiftmodule"
    cp -R "$interface_dir/"* "$framework_path/Modules/JCProxy.swiftmodule/"
    return
  fi

  echo "warning: no swiftmodule found for $platform"
}

install_modules "Release-iphoneos" "$BUILD_DIR/JCProxy-iOS.xcarchive"
install_modules "Release-iphonesimulator" "$BUILD_DIR/JCProxy-iOS-Sim.xcarchive"
normalize_info_plist() {
  local framework_path="$1"
  local plist="$framework_path/Info.plist"

  if [[ ! -f "$plist" ]]; then
    echo "warning: framework Info.plist not found"
    return
  fi

  plutil -convert xml1 "$plist" || true

  if ! /usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string JCProxy" "$plist" || true
  fi
  if ! /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string jcrequestrecorder.JCProxy" "$plist" || true
  fi
  if ! /usr/libexec/PlistBuddy -c "Print :CFBundleName" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :CFBundleName string JCProxy" "$plist" || true
  fi
  if ! /usr/libexec/PlistBuddy -c "Print :CFBundlePackageType" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string FMWK" "$plist" || true
  fi
  if ! /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1" "$plist" || true
  fi
  if ! /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0" "$plist" || true
  fi
}

normalize_info_plist "$BUILD_DIR/JCProxy-iOS.xcarchive/Products/usr/local/lib/JCProxy.framework"
normalize_info_plist "$BUILD_DIR/JCProxy-iOS-Sim.xcarchive/Products/usr/local/lib/JCProxy.framework"

popd >/dev/null

xcodebuild -create-xcframework \
  -framework "$BUILD_DIR/JCProxy-iOS.xcarchive/Products/usr/local/lib/JCProxy.framework" \
  -framework "$BUILD_DIR/JCProxy-iOS-Sim.xcarchive/Products/usr/local/lib/JCProxy.framework" \
  -output "$XCFRAMEWORK_PATH"

echo "XCFramework created at: $XCFRAMEWORK_PATH"
if [[ "${KEEP_BUILD:-0}" != "1" ]]; then
  rm -rf "$BUILD_DIR"
fi
