#!/bin/bash
# Apply 遇见pro branding to the REPACKED app, never the original IPA/dylib.
# This phase runs after MonkeyDev's pack phase and before codesigning.
set -euo pipefail

: "${SRCROOT:?SRCROOT is missing}"
: "${BUILT_PRODUCTS_DIR:?BUILT_PRODUCTS_DIR is missing}"
: "${FULL_PRODUCT_NAME:?FULL_PRODUCT_NAME is missing}"

APP="${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}"
BRAND="${SRCROOT}/资源"
STORYBOARD="${SRCROOT}/branding/LaunchScreen.storyboard"
PLIST="${APP}/Info.plist"
ICON="${BRAND}/AppIcon_1024.png"
SPLASH="${BRAND}/splash海报.png"
PB=/usr/libexec/PlistBuddy

for required in "$PLIST" "$ICON" "$SPLASH" "$STORYBOARD"; do
  [[ -f "$required" ]] || { echo "Branding: missing file: $required" >&2; exit 1; }
done

# Launch storyboard references MeetProLaunch.png; preserve the original IPA's
# unrelated compiled assets and storyboards. Use aspect-fit to avoid cutting off
# the logo on tall iPhones, with a dark background for letterboxed space.
/bin/cp -f "$SPLASH" "${APP}/MeetProLaunch.png"
rm -rf "${APP}/LaunchScreen.storyboardc"
/usr/bin/xcrun ibtool --compile "${APP}/LaunchScreen.storyboardc" "$STORYBOARD"
"$PB" -c "Set :UILaunchStoryboardName LaunchScreen" "$PLIST"

# Filesystem icon fallback avoids replacing the original Assets.car (used by
# thousands of application images). The named AppIcon asset must be disabled in
# Info.plist, otherwise iOS keeps using the original compiled catalog icon.
/usr/bin/sips -s format png -z 120 120 "$ICON" --out "${APP}/MeetProIcon60x60@2x.png" >/dev/null
/usr/bin/sips -s format png -z 180 180 "$ICON" --out "${APP}/MeetProIcon60x60@3x.png" >/dev/null
# Also cover the older, non-Retina icon filename lookup.
/usr/bin/sips -s format png -z 60 60 "$ICON" --out "${APP}/MeetProIcon60x60.png" >/dev/null

"$PB" -c "Delete :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconName" "$PLIST" 2>/dev/null || true
"$PB" -c "Delete :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles" "$PLIST" 2>/dev/null || true
"$PB" -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles array" "$PLIST"
"$PB" -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:0 string MeetProIcon60x60" "$PLIST"

"$PB" -c "Delete :CFBundleIconName" "$PLIST" 2>/dev/null || true
"$PB" -c "Delete :CFBundleIconFiles" "$PLIST" 2>/dev/null || true
"$PB" -c "Add :CFBundleIconFiles array" "$PLIST"
"$PB" -c "Add :CFBundleIconFiles:0 string MeetProIcon60x60" "$PLIST"

echo "Branding: MeetPro splash and app icon installed in ${APP}"
