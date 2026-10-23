#!/usr/bin/env bash
#
# Builds the ValantiaOS live ISO. Runs inside a Debian trixie container; see
# .github/workflows/build-iso.yml for the invocation.
#
# This lives in its own file rather than being inlined into the workflow so
# that the shell is never nested inside another shell's quoting.

set -Eeuo pipefail

ISO_NAME="ValantiaOS-0.1.0-amd64.iso"

# The upstream builder's checked-in config is tied to Linux 6.17.13. Keep the
# source version explicit so archived upstream changes cannot silently alter it.
PSYCACHY_VERSION="6.17.13"
PSYCACHY_REVISION="0b8d38af9a08ce7dfbe1990a2e850a136cfe40d9"
PSYCACHY_DIR="${PWD}/.cache/linux-psycachy"
KERNEL_JOBS="$(($(nproc) > 2 ? $(nproc) - 2 : 1))"

apt-get update

DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
    live-build ca-certificates python3-pil fonts-dejavu-core \
    xfce4-terminal python3-gi gir1.2-gtk-3.0 policykit-1 \
    power-profiles-daemon pavucontrol pciutils flatpak \
    git wget build-essential bc bison flex libelf-dev libssl-dev \
    libncurses-dev gawk openssl libudev-dev libpci-dev libiberty-dev \
    autoconf llvm gcc dwarves rsync cpio kmod fakeroot

# Fetch pinned PsyCachy sources and build a Debian kernel package before
# live-build resolves the image package list.
mkdir -p "$(dirname "${PSYCACHY_DIR}")"
git clone --no-checkout https://github.com/psygreg/linux-psycachy.git "${PSYCACHY_DIR}"
git -C "${PSYCACHY_DIR}" checkout --detach "${PSYCACHY_REVISION}"

work_dir="${PSYCACHY_DIR}/build"
mkdir -p "${work_dir}/src"
cp "${PSYCACHY_DIR}/src/"*.patch "${work_dir}/src/"
cp "${PSYCACHY_DIR}/src/config" "${work_dir}/src/config"

# Reuse the upstream kernel config and patches, but package the image with the
# ValantiaOS kernel name. Build Debian packages with a bounded job count.
cd "${work_dir}"
wget -q "https://www.kernel.org/pub/linux/kernel/v6.x/linux-${PSYCACHY_VERSION}.tar.gz"
tar -xzf "linux-${PSYCACHY_VERSION}.tar.gz" -C src
cd "src/linux-${PSYCACHY_VERSION}"
for patch_file in ../*.patch; do
  patch -Np1 < "${patch_file}"
done
cp ../config .config
scripts/config --set-str LOCALVERSION "-valantia-kern"
make olddefconfig
make CC=gcc bindeb-pkg -j"${KERNEL_JOBS}" \
  LOCALVERSION=-valantia-kern \
  KDEB_PKGVERSION="${PSYCACHY_VERSION}-1"

mkdir -p /tmp/valantia-kernel-debs
find "${work_dir}" -type f -name '*.deb' \
  -exec cp {} /tmp/valantia-kernel-debs/ \
  \;
test -n "$(find /tmp/valantia-kernel-debs -maxdepth 1 -type f -name 'linux-image-*.deb' -print -quit)"
cd -
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
