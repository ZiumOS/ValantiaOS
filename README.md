# ValantiaOS

**Your System. Your Rules.**

ValantiaOS is an experimental Debian-based live Linux distribution focused on lightweight desktop computing and PC gaming.

## Current Release

- Version: `0.1.0`
- Base: Debian GNU/Linux 13 (Trixie)
- Architecture: AMD64
- Desktop: XFCE with ValantiaOS dark styling and bundled wallpapers
- Kernel: PsyCachy Linux `6.17.13`, packaged with the `valantia-kern` local version
- Build system: Debian Live (`live-build`)
- CI: GitHub Actions

## Features

- Lightweight XFCE desktop
- Mesa Vulkan support
- Selected firmware packages for supported hardware
- GameMode and MangoHud
- Automated ISO builds
- SHA-256 checksum generation

## Build

The XFCE desktop includes Valantia Welcome for first-run guidance, shortcuts to the Control Center and Store, and a safe installer availability check; Valantia Control Center and Valantia Store provide system and package management tools. The Store searches a curated set of Debian packages and Flatpak apps, with install/remove actions and separate update commands; package changes require administrator authorization. Flatpak uses the system Flathub remote. The current ISO does not yet include a configured disk installer, so Welcome will clearly report that rather than risk disk changes.

To build through GitHub Actions:

1. Open the repository's Actions tab.
2. Select **Build ValantiaOS**.
3. Click **Run workflow**.
4. Download the ISO artifact when the job succeeds.

To build locally, run the same build script in a Debian Trixie container from the repository root:

```sh
docker run --privileged --rm \\
  -v "$PWD:/work" \\
  -w /work \\
  debian:trixie \\
  bash -euxo pipefail scripts/build-iso.sh
```

The ISO and `SHA256SUMS` are written to `output/`.

## Live Session

The default live account is:

- Username: `user`
- Password: `live`
- Sudo: passwordless

The account is created at boot by `live-config`; the `user-setup` package is included explicitly because the build disables APT recommends.

## Testing Status

This project is experimental. Hardware compatibility, gaming performance, installation workflows, and power management must be tested before a stable release.

## Disclaimer

ValantiaOS is an independent project based on Debian. It is not an official Debian release.
