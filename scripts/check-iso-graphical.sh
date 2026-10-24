#!/usr/bin/env bash
# Extract the live rootfs and validate graphical-session setup from the built ISO.
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO_PATH="${1:?usage: check-iso-graphical.sh ISO_PATH}"
if ! command -v unsquashfs >/dev/null 2>&1 || ! command -v 7z >/dev/null 2>&1; then
  echo "Smoke test requires unsquashfs and 7z" >&2
  exit 1
fi
python3 "${ROOT_DIR}/scripts/smoke-test-iso.py" "${ISO_PATH}"
