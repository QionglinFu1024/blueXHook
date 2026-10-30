#!/bin/bash
# Work around only two known pre-existing dylibs in Blued X 7.50.8.
# MonkeyDev's verify accepts thin arm64; the supplied legacy IPA also has
# BluedEnhancer (arm64e) and libsubstrate (armv7+arm64).
#
# During *verification only*, temporarily relocate those two from the
# staging App and restore them in EXIT trap before packing/signing proceeds.
# All other app images, including the main executable, still receive the
# original MonkeyDev verification. No source IPA or installed tool changes.
set -euo pipefail

real_parser=/opt/MonkeyDev/bin/monkeyparser
if [[ "${1:-}" != "verify" || "$#" -ne 5 || "${2:-}" != "-t" || "${4:-}" != "-o" ]]; then
    exec "$real_parser" "$@"
fi

target="$3"
expected="${TARGET_BUILD_DIR:-}/${FULL_PRODUCT_NAME:-}"
if [[ -z "${TARGET_BUILD_DIR:-}" || -z "${FULL_PRODUCT_NAME:-}" || "$target" != "$expected" || ! -f "$target/Blued" ]]; then
    exec "$real_parser" "$@"
fi

enhancer="$target/BluedEnhancer.2.8.9_Finala_arm64e.dylib"
substrate="$target/libsubstrate.dylib"
if [[ ! -f "$enhancer" || ! -f "$substrate" || -L "$enhancer" || -L "$substrate" ]]; then
    echo "[BluedCompat] Expected original libraries missing or invalid; aborting." >&2
    exit 1
fi

if [[ "$(/usr/bin/lipo -archs "$enhancer")" != "arm64e" ||
      "$(/usr/bin/lipo -archs "$substrate")" != "armv7 arm64" ]]; then
    echo "[BluedCompat] Original dylib architectures changed; refusing compatibility exception." >&2
    exit 1
fi

parent="${TARGET_TEMP_DIR:-${TMPDIR:-/tmp}}"
stash=$(/usr/bin/mktemp -d "$parent/.blued-verify.XXXXXXXX")
moved_enhancer=NO
moved_substrate=NO
restore() {
    local code=$?
    trap - EXIT
    if [[ "$moved_substrate" == YES && -e "$stash/libsubstrate.dylib" ]]; then
        /bin/mv "$stash/libsubstrate.dylib" "$substrate" || code=1
    fi
    if [[ "$moved_enhancer" == YES && -e "$stash/BluedEnhancer.2.8.9_Finala_arm64e.dylib" ]]; then
        /bin/mv "$stash/BluedEnhancer.2.8.9_Finala_arm64e.dylib" "$enhancer" || code=1
    fi
    /bin/rmdir "$stash" || code=1
    exit "$code"
}
trap restore EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

/bin/mv "$enhancer" "$stash/"
moved_enhancer=YES
/bin/mv "$substrate" "$stash/"
moved_substrate=YES

echo "[BluedCompat] Verifying all other images with original monkeyparser (two known libraries stashed temporarily)."
"$real_parser" "$@"
