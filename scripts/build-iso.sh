#!/usr/bin/env bash
#
# Builds the ValantiaOS live ISO. Runs inside a Debian trixie container; see
# .github/workflows/build-iso.yml for the invocation.
#
# This lives in its own file rather than being inlined into the workflow so
# that the shell is never nested inside another shell's quoting.

set -Eeuo pipefail

ISO_NAME="ValantiaOS-0.1.0-amd64.iso"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"
KERNEL_VERSION="7.2.12"
KERNEL_JOBS="$(nproc)"
KERNEL_BUILD_DIR="${ROOT_DIR}/.cache/linux-${KERNEL_VERSION}"

apt-get update

DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
    live-build ca-certificates python3-pil fonts-dejavu-core \
    xfce4-terminal python3-gi gir1.2-gtk-3.0 polkitd pkexec \
    power-profiles-daemon pavucontrol pciutils flatpak \
    git wget build-essential bc bison flex libelf-dev libssl-dev \
    libncurses-dev gawk openssl libudev-dev libpci-dev libiberty-dev \
    autoconf llvm gcc dwarves rsync cpio kmod fakeroot \
    debhelper-compat libdw-dev lsb-release

# Build the current stable upstream Linux 7.2 kernel without third-party
# patches, then package it for inclusion in the live filesystem.
# Keep the extracted upstream source tree across Actions runs. The build tree is
# intentionally not cached because generated kernel artifacts are runner-specific.
mkdir -p "${KERNEL_BUILD_DIR}/src" /tmp/valantia-kernel-debs
if [[ ! -f "${KERNEL_BUILD_DIR}/src/linux-${KERNEL_VERSION}/Makefile" ]]; then
  mkdir -p "${KERNEL_BUILD_DIR}/src"
  wget -q "https://www.kernel.org/pub/linux/kernel/v7.x/linux-${KERNEL_VERSION}.tar.xz" -O "${KERNEL_BUILD_DIR}/linux-${KERNEL_VERSION}.tar.xz"
  tar -xf "${KERNEL_BUILD_DIR}/linux-${KERNEL_VERSION}.tar.xz" -C "${KERNEL_BUILD_DIR}/src"
fi
cd "${KERNEL_BUILD_DIR}/src/linux-${KERNEL_VERSION}"
make defconfig
scripts/config --set-str LOCALVERSION "-valantia-kern"
make olddefconfig
make CC=gcc bindeb-pkg -j"${KERNEL_JOBS}" KDEB_PKGVERSION="${KERNEL_VERSION}-1" KDEB_CHANGELOG_DIST=trixie

mkdir -p /tmp/valantia-kernel-debs
find "${KERNEL_BUILD_DIR}" -type f -name '*.deb' -exec cp {} /tmp/valantia-kernel-debs/ \;
test -n "$(find /tmp/valantia-kernel-debs -maxdepth 1 -type f -name 'linux-image-*.deb' -print -quit)"
cd "${ROOT_DIR}"
rm -f config/packages.chroot/*.deb
mkdir -p config/packages.chroot
cp /tmp/valantia-kernel-debs/*.deb config/packages.chroot/

for executable in \
  config/includes.chroot/usr/bin/valantia-control-center \
  config/includes.chroot/usr/bin/valantia-control-helper \
  config/includes.chroot/usr/bin/valantia-store \
  config/includes.chroot/usr/bin/valantia-store-helper \
  config/includes.chroot/usr/bin/valantia-welcome; do
  if [[ ! -f "${executable}" ]]; then
    printf 'Error: required Valantia app is missing: %s\\n' "${executable}" >&2
    exit 1
  fi
  chmod 0755 "${executable}"
done

# Configure Flathub as a system-wide Flatpak remote in the live image.
mkdir -p config/hooks/normal
cat > config/hooks/normal/0200-flathub.hook.chroot <<'HOOK'
#!/bin/sh
set -e
flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
HOOK
chmod 0755 config/hooks/normal/0200-flathub.hook.chroot

# Render the branded GRUB background.
#
# live-build's binary_grub_cfg stage copies the distribution's default
# bootloader files into binary/boot/grub/ and then overlays
# config/bootloaders/grub-pc/ on top of them, so the override tree only needs
# the files we actually want to change: the background image and the theme.
# There is no need to seed it from /usr/share/live/build.
if [[ ! -f "${ROOT_DIR}/branding/grub/make-splash.py" ]]; then
  printf 'Error: GRUB splash generator is missing under %s\\n' "${ROOT_DIR}" >&2
  exit 1
fi
python3 "${ROOT_DIR}/branding/grub/make-splash.py"

cd "${ROOT_DIR}"
lb config \
  --distribution trixie \
  --architectures amd64 \
  --binary-image iso-hybrid \
  --archive-areas \
    "main contrib non-free non-free-firmware" \
  --apt-recommends false

lb build

test -s "${ROOT_DIR}/live-image-amd64.hybrid.iso"

mkdir -p "${ROOT_DIR}/output"

cp "${ROOT_DIR}/live-image-amd64.hybrid.iso" "${ROOT_DIR}/output/${ISO_NAME}"

(cd "${ROOT_DIR}/output" && sha256sum "${ISO_NAME}" > SHA256SUMS)
