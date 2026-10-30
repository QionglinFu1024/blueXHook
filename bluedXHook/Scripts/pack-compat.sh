#!/bin/bash
# Project-local compatibility adapter for a pre-injected Blued IPA.
# Do not modify /opt/MonkeyDev or disable signing / architecture checks globally.
set -euo pipefail

[[ -n "${SRCROOT:-}" ]] || { echo "Missing SRCROOT" >&2; exit 1; }
export MONKEYDEV_MONKEYPARSER="${SRCROOT}/bluedXHook/Scripts/monkeyparser-compat.sh"
exec /bin/bash /opt/MonkeyDev/Tools/pack.sh "$@"
