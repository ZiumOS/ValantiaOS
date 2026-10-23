#!/usr/bin/env bash
#
# Builds the ValantiaOS live ISO. Runs inside a Debian trixie container; see
# .github/workflows/build-iso.yml for the invocation.
#
# This lives in its own file rather than being inlined into the workflow so
# that the shell is never nested inside another shell's quoting.

set -Eeuo pipefail

ISO_NAME="ValantiaOS-0.1.0-amd64.iso"

KERNEL_VERSION="7.2.12"
KERNEL_JOBS="$(($(nproc) > 2 ? $(nproc) - 2 : 1))"
KERNEL_BUILD_DIR="${PWD}/.cache/linux-${KERNEL_VERSION}"

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
mkdir -p "${KERNEL_BUILD_DIR}/src"
cd "${KERNEL_BUILD_DIR}"
wget -q "https://www.kernel.org/pub/linux/kernel/v7.x/linux-${KERNEL_VERSION}.tar.xz"
tar -xf "linux-${KERNEL_VERSION}.tar.xz" -C src
cd "src/linux-${KERNEL_VERSION}"
make defconfig
scripts/config --set-str LOCALVERSION "-valantia-kern"
make olddefconfig
make CC=gcc bindeb-pkg -j"${KERNEL_JOBS}" LOCALVERSION=-valantia-kern KDEB_PKGVERSION="${KERNEL_VERSION}-1" KDEB_CHANGELOG_DIST=trixie

mkdir -p /tmp/valantia-kernel-debs
find "${KERNEL_BUILD_DIR}" -type f -name '*.deb' -exec cp {} /tmp/valantia-kernel-debs/ \;
test -n "$(find /tmp/valantia-kernel-debs -maxdepth 1 -type f -name 'linux-image-*.deb' -print -quit)"
cd -
rm -f config/packages.chroot/*.deb
mkdir -p config/packages.chroot
cp /tmp/valantia-kernel-debs/*.deb config/packages.chroot/

chmod 0755 config/includes.chroot/usr/bin/valantia-control-center
chmod 0755 config/includes.chroot/usr/bin/valantia-control-helper
chmod 0755 config/includes.chroot/usr/bin/valantia-store
chmod 0755 config/includes.chroot/usr/bin/valantia-store-helper
chmod 0755 config/includes.chroot/usr/bin/valantia-welcome

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
