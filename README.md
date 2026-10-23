# ValantiaOS

**Your System. Your Rules.**

ValantiaOS Gaming is an experimental Debian-based live Linux distribution focused on lightweight desktop computing and PC gaming.

## Current Release

- Version: `0.1.0`
- Base: Debian GNU/Linux 13 (Trixie)
- Architecture: AMD64
- Desktop: XFCE
- Kernel: Debian-provided Linux kernel
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

The ISO is built in a Debian Trixie environment using `live-build`.

To build through GitHub Actions:

1. Open the repository's Actions tab.
2. Select **Build ValantiaOS Gaming**.
3. Click **Run workflow**.
4. Download the ISO artifact when the job succeeds.

## Testing Status

This project is experimental. Hardware compatibility, gaming performance, installation workflows, and power management must be tested before a stable release.

## Disclaimer

ValantiaOS is an independent project based on Debian. It is not an official Debian release.
