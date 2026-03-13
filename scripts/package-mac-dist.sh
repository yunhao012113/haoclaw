#!/usr/bin/env bash
set -euo pipefail

# Build the mac app bundle, then create a zip, styled DMG, and optional PKG installer.
#
# Output:
# - dist/Haoclaw.app
# - dist/Haoclaw-<version>.zip
# - dist/Haoclaw-<version>.dmg
# - dist/Haoclaw-<version>.pkg

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$ROOT_DIR/apps/macos/.build"
PRODUCT="Haoclaw"
BUILD_CONFIG="${BUILD_CONFIG:-release}"
export BUILD_CONFIG

# Default to universal binary for distribution builds (supports both Apple Silicon and Intel Macs)
export BUILD_ARCHS="${BUILD_ARCHS:-all}"

# Use release bundle ID (not .debug) so Sparkle auto-update works.
# The .debug suffix in package-mac-app.sh blanks SUFeedURL intentionally for dev builds.
export BUNDLE_ID="${BUNDLE_ID:-ai.haoclaw.mac}"

"$ROOT_DIR/scripts/package-mac-app.sh"

APP="$ROOT_DIR/dist/Haoclaw.app"
if [[ ! -d "$APP" ]]; then
  echo "Error: missing app bundle at $APP" >&2
  exit 1
fi

PKG_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/haoclaw-pkg-stage.XXXXXX")"
cleanup() {
  rm -rf "$PKG_STAGE"
}
trap cleanup EXIT

mkdir -p "$PKG_STAGE/Applications"
ditto "$APP" "$PKG_STAGE/Applications/Haoclaw.app"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist" 2>/dev/null || echo "0.0.0")
ZIP="$ROOT_DIR/dist/Haoclaw-$VERSION.zip"
DMG="$ROOT_DIR/dist/Haoclaw-$VERSION.dmg"
PKG="$ROOT_DIR/dist/Haoclaw-$VERSION.pkg"
NOTARY_ZIP="$ROOT_DIR/dist/Haoclaw-$VERSION.notary.zip"
DSYM_ZIP="$ROOT_DIR/dist/Haoclaw-$VERSION.dSYM.zip"
COMPONENT_PLIST="$ROOT_DIR/scripts/macos-installer/component.plist"
SKIP_NOTARIZE="${SKIP_NOTARIZE:-0}"
NOTARIZE=1
SKIP_DSYM="${SKIP_DSYM:-0}"
INSTALLER_SIGN_IDENTITY="${INSTALLER_SIGN_IDENTITY:-}"

if [[ "$SKIP_NOTARIZE" == "1" ]]; then
  NOTARIZE=0
fi

if [[ "$NOTARIZE" == "1" ]]; then
  echo "📦 Notary zip: $NOTARY_ZIP"
  rm -f "$NOTARY_ZIP"
  ditto -c -k --sequesterRsrc --keepParent "$APP" "$NOTARY_ZIP"
  STAPLE_APP_PATH="$APP" "$ROOT_DIR/scripts/notarize-mac-artifact.sh" "$NOTARY_ZIP"
  rm -f "$NOTARY_ZIP"
fi

echo "📦 Zip: $ZIP"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "💿 DMG: $DMG"
"$ROOT_DIR/scripts/create-dmg.sh" "$APP" "$DMG"

echo "📦 PKG: $PKG"
rm -f "$PKG"
pkg_args=(
  --root "$PKG_STAGE"
  --component-plist "$COMPONENT_PLIST"
  --identifier "$BUNDLE_ID"
  --version "$VERSION"
  --install-location /
  --scripts "$ROOT_DIR/scripts/macos-installer"
  "$PKG"
)
if [[ -n "$INSTALLER_SIGN_IDENTITY" ]]; then
  pkg_args=(--sign "$INSTALLER_SIGN_IDENTITY" "${pkg_args[@]}")
fi
pkgbuild "${pkg_args[@]}"

if [[ "$NOTARIZE" == "1" ]]; then
  if [[ -n "${SIGN_IDENTITY:-}" ]]; then
    echo "🔏 Signing DMG: $DMG"
    /usr/bin/codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG"
  fi
  "$ROOT_DIR/scripts/notarize-mac-artifact.sh" "$DMG"
  if [[ -n "$INSTALLER_SIGN_IDENTITY" ]]; then
    "$ROOT_DIR/scripts/notarize-mac-artifact.sh" "$PKG"
  else
    echo "WARN: INSTALLER_SIGN_IDENTITY missing; skipping PKG notarization" >&2
  fi
fi

if [[ "$SKIP_DSYM" != "1" ]]; then
  DSYM_ARM64=""
  DSYM_X86=""
  if [[ -d "$BUILD_ROOT/arm64" ]]; then
    DSYM_ARM64="$(find "$BUILD_ROOT/arm64" -type d -path "*/$BUILD_CONFIG/$PRODUCT.dSYM" -print -quit)"
  fi
  if [[ -d "$BUILD_ROOT/x86_64" ]]; then
    DSYM_X86="$(find "$BUILD_ROOT/x86_64" -type d -path "*/$BUILD_CONFIG/$PRODUCT.dSYM" -print -quit)"
  fi
  if [[ -n "$DSYM_ARM64" || -n "$DSYM_X86" ]]; then
    TMP_DSYM="$ROOT_DIR/dist/$PRODUCT.dSYM"
    rm -rf "$TMP_DSYM"
    if [[ -n "$DSYM_ARM64" && -n "$DSYM_X86" ]]; then
      cp -R "$DSYM_ARM64" "$TMP_DSYM"
      DWARF_OUT="$TMP_DSYM/Contents/Resources/DWARF/$PRODUCT"
      DWARF_ARM="$DSYM_ARM64/Contents/Resources/DWARF/$PRODUCT"
      DWARF_X86="$DSYM_X86/Contents/Resources/DWARF/$PRODUCT"
      if [[ -f "$DWARF_ARM" && -f "$DWARF_X86" ]]; then
        /usr/bin/lipo -create "$DWARF_ARM" "$DWARF_X86" -output "$DWARF_OUT"
      else
        echo "WARN: Missing DWARF binaries for dSYM merge (continuing)" >&2
      fi
    else
      cp -R "${DSYM_ARM64:-$DSYM_X86}" "$TMP_DSYM"
    fi
    echo "🧩 dSYM: $DSYM_ZIP"
    rm -f "$DSYM_ZIP"
    ditto -c -k --keepParent "$TMP_DSYM" "$DSYM_ZIP"
    rm -rf "$TMP_DSYM"
  else
    echo "WARN: dSYM not found; skipping zip (set SKIP_DSYM=1 to silence)" >&2
  fi
fi
