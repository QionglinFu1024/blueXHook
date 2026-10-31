#!/bin/bash
# Release → Ad Hoc IPA → 蒲公英 → 飞书
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "${SCRIPT_DIR}/package_adhoc.py" "$@"
