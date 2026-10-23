#!/usr/bin/env bash
#
# Builds the ValantiaOS live ISO. Runs inside a Debian trixie container; see
# .github/workflows/build-iso.yml for the invocation.
#
# This lives in its own file rather than being inlined into the workflow so
# that the shell is never nested inside another shell's quoting.

set -Eeuo pipefail

ISO_NAME="ValantiaOS-Gaming-0.1.0-amd64.iso"

apt-get update

DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
    live-build ca-certificates python3-pil fonts-dejavu-core

# Render the branded GRUB background.
#
# live-build's binary_grub_cfg stage copies the distribution's default
# bootloader files into binary/boot/grub/ and then overlays
# config/bootloaders/grub-pc/ on top of them, so the override tree only needs
# the files we actually want to change: the background image and the theme.
# There is no need to seed it from /usr/share/live/build.
python3 branding/grub/make-splash.py

lb config \
  --distribution trixie \
  --architectures amd64 \
  --binary-image iso-hybrid \
  --archive-areas \
    "main contrib non-free non-free-firmware" \
  --apt-recommends false

lb build

test -s live-image-amd64.hybrid.iso

mkdir -p output

cp live-image-amd64.hybrid.iso "output/${ISO_NAME}"

(cd output && sha256sum "${ISO_NAME}" > SHA256SUMS)
