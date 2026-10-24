#!/usr/bin/env bash
#
# Builds the ValantiaOS live ISO. Runs inside a Debian trixie container; see
# .github/workflows/build-iso.yml for the invocation.
#
# This lives in its own file rather than being inlined into the workflow so
# that the shell is never nested inside another shell's quoting.

set -Eeuo pipefail

VERSION="${VALANTIA_VERSION:?VALANTIA_VERSION must be set by the build workflow}"
ISO_NAME="ValantiaOS-${VERSION}-amd64.iso"

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
# Enable the in-kernel graphics/input drivers needed for QEMU's std VGA,
# UEFI GOP/simpledrm, and common physical framebuffers. Keep overlay and live
# media support built in so early live-boot does not depend on module loading.
scripts/config --enable DRM
scripts/config --enable DRM_BOCHS
scripts/config --enable DRM_VIRTIO_GPU
scripts/config --enable DRM_SIMPLEDRM
scripts/config --enable FB
scripts/config --enable FB_EFI
scripts/config --enable FB_VESA
scripts/config --enable FB_VGA16
scripts/config --enable INPUT_EVDEV
scripts/config --enable OVERLAY_FS
scripts/config --enable SQUASHFS
scripts/config --enable SQUASHFS_XZ
scripts/config --enable BLK_DEV_LOOP
make olddefconfig
for option in DRM DRM_BOCHS DRM_VIRTIO_GPU DRM_SIMPLEDRM FB INPUT_EVDEV OVERLAY_FS SQUASHFS BLK_DEV_LOOP; do
  grep -Eq "^CONFIG_${option}=y$" .config || { echo "Required kernel option CONFIG_${option}=y was not enabled" >&2; exit 1; }
done
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

chmod 0755 config/hooks/normal/0030-ensure-live-kernels.hook.chroot
chmod 0755 config/hooks/normal/0100-enable-graphical-session.hook.chroot

# Embed the unique build version in ValantiaOS metadata and OS release metadata.
cat > config/includes.chroot/etc/valantiaos-release <<EOF
NAME="ValantiaOS"
VERSION="${VERSION}"
VERSION_ID="${VERSION}"
BASE="Debian GNU/Linux 13 (Trixie)"
EDITION="Gaming"
ARCHITECTURE="amd64"
EOF
cat > config/hooks/normal/0050-set-os-release-version.hook.chroot <<HOOK
#!/bin/sh
set -eu
sed -i '/^VERSION=/d; /^VERSION_ID=/d' /etc/os-release
printf 'VERSION="%s"\\nVERSION_ID="%s"\\n' '${VERSION}' '${VERSION}' >> /etc/os-release
HOOK
chmod 0755 config/hooks/normal/0050-set-os-release-version.hook.chroot

# Configure Flathub as a system-wide Flatpak remote in the live image.
mkdir -p config/hooks/normal
cat > config/hooks/normal/0200-flathub.hook.chroot <<'HOOK'
#!/bin/sh
set -e
flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
HOOK
chmod 0755 config/hooks/normal/0200-flathub.hook.chroot

# Render branded GRUB assets and embed the per-build version in the theme.
python3 "${ROOT_DIR}/branding/grub/make-splash.py"
mkdir -p config/bootloaders/grub-pc/live-theme config/bootloaders/isolinux config/includes.chroot/usr/share/pixmaps
cp config/bootloaders/grub-pc/grub.cfg config/bootloaders/grub-pc/grub.cfg.in
sed -i "s/ValantiaOS V.alpha.placeholder/ValantiaOS ${VERSION}/g" config/bootloaders/grub-pc/grub.cfg.in
cp config/bootloaders/grub-pc/grub.cfg.in config/bootloaders/grub-pc/grub.cfg
cp config/bootloaders/isolinux/live.cfg config/bootloaders/isolinux/live.cfg.in
sed -i "s/ValantiaOS V.alpha.placeholder/ValantiaOS ${VERSION}/g" config/bootloaders/isolinux/live.cfg.in
cp config/bootloaders/isolinux/live.cfg.in config/bootloaders/isolinux/live.cfg
cp config/bootloaders/grub-pc/splash.png config/includes.chroot/usr/share/pixmaps/valantiaos-logo.png
sed -i "s/^set timeout=.*/set timeout=10/" config/bootloaders/grub-pc/grub.cfg

cd "${ROOT_DIR}"
lb config \
  --distribution trixie \
  --architectures amd64 \
  --binary-image iso-hybrid \
  --iso-application "ValantiaOS ${VERSION}" \
  --iso-publisher "ZiumOS" \
  --iso-volume "${VERSION}" \
  --archive-areas \
    "main contrib non-free non-free-firmware" \
  --apt-recommends false

lb build

test -s "${ROOT_DIR}/live-image-amd64.hybrid.iso"

mkdir -p "${ROOT_DIR}/output"

cp "${ROOT_DIR}/live-image-amd64.hybrid.iso" "${ROOT_DIR}/output/${ISO_NAME}"
cp "${ROOT_DIR}/output/${ISO_NAME}" "${ROOT_DIR}/output/ValantiaOS.iso"
(cd "${ROOT_DIR}/output" && sha256sum "${ISO_NAME}" > SHA256SUMS)
printf '%s\n' "${VERSION}" > "${ROOT_DIR}/output/VERSION"
