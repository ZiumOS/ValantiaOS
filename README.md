<div align="center">

# ValantiaOS

**Your System. Your Rules.**

![ValantiaOS banner](https://i.ibb.co.com/rK2BSV8v/Gemini-Generated-Image-hydhszhydhszhydh-1.jpg)

An experimental Debian-based live Linux distribution for a lightweight desktop and PC gaming.

[Features](#what-is-valantiaos) · [Build](#build-the-iso) · [Roadmap](#roadmap) · [Contribute](#contributing)

</div>

> **Project status: experimental.** ValantiaOS is under active development. The ISO, hardware support, desktop applications, and gaming experience have not yet been validated across a broad range of machines. Back up important data and test from a virtual machine or removable media before relying on it.

## What is ValantiaOS?

ValantiaOS is a custom live operating system built on Debian GNU/Linux 13 (Trixie), using Debian Live (`live-build`) and the XFCE desktop. The project aims to provide a straightforward desktop with gaming-related tools and a branded environment, while keeping the build reproducible through a script and GitHub Actions.

| Item | Current configuration |
| --- | --- |
| Project version | Per-build: `ValantiaOS V.alpha.<month>.<year>.<hour>.<run>.<attempt>` (UTC) |
| Debian base | Debian GNU/Linux 13 (Trixie) |
| Target architecture | AMD64 (`x86_64`) |
| Desktop | XFCE with ValantiaOS settings and wallpapers |
| Kernel build target | Linux `7.2.12`, local version `-valantia-kern` (see build script) |
| Image type | Hybrid live ISO |
| Build tooling | Debian Live (`live-build`) |
| Automated build and test | GitHub Actions build followed by separate ISO test workflow |
| Installer | No configured disk installer in the current image |

## What is included?

- **XFCE desktop** with LightDM, terminal, branded wallpapers, and GRUB theme.
- **Live session** configured through Debian Live components, with a default `user` account (`live` password) and passwordless `sudo` as currently documented by the project. Change or remove these defaults before any persistent or publicly deployed use.
- **Graphics and Vulkan utilities:** Mesa Vulkan drivers and `vulkan-tools`.
- **Selected firmware:** AMD and Intel graphics firmware, plus the Debian firmware bundle listed in the package manifest. Actual device support depends on hardware and firmware availability.
- **Gaming utilities:** GameMode and MangoHud. These are included tools, not a promise of compatibility or performance for every game.
- **Flatpak:** system-wide Flatpak support, with Flathub configured by a build hook.
- **ValantiaOS utilities:** Welcome, Store, and Control Center applications are bundled. Their scope is experimental and should not be considered a complete software center or settings suite.
- **Networking and everyday tools:** NetworkManager, Firefox ESR, `curl`, and `vim-tiny`.
- **Custom kernel package** built by the ISO script, with overlay filesystem, SquashFS, and loop-device kernel options enabled for the live system.

## Download and verify

The **Build ValantiaOS** workflow uploads each ISO as a uniquely versioned artifact named `ValantiaOS-<version>-amd64`. Each artifact contains the versioned ISO, a stable `ValantiaOS.iso` alias, a `VERSION` file, and `SHA256SUMS`. The separate **Test ValantiaOS ISO** workflow checks the checksum and image, inspects the root filesystem, and boots the ISO in QEMU. Only a build whose tests pass is linked in the status below; the Actions artifact is retained for seven days.

## Test status

<!-- TEST-STATUS:START -->
Tests have not yet been recorded as passing for a build.
<!-- TEST-STATUS:END -->

To verify a downloaded ISO locally, place `SHA256SUMS` beside the ISO and run:

```sh
sha256sum --check SHA256SUMS
```

A checksum detects accidental corruption; it does not by itself establish who produced the image.

## Build the ISO

The project build script is `scripts/build-iso.sh`. It is designed to run as root inside a Debian Trixie container. The GitHub Actions workflow generates a unique version using UTC time plus the GitHub run number and attempt, then passes it into the script. Building the custom kernel can take a while and requires substantial disk space, memory, and CPU.

### GitHub Actions

1. Open the repository's **Actions** tab.
2. Select **Build ValantiaOS** and run the workflow (or push a change to the configured paths on `main`).
3. When it succeeds, **Test ValantiaOS ISO** starts automatically against that exact run's artifact.
4. Download the ISO from the build run only after its associated test workflow succeeds.

### Local build with Docker

Set a unique version string and run from the repository root on a machine with Docker and network access:

```sh
export VALANTIA_VERSION="V.alpha.$(date -u +'%m.%Y.%H').local.$(date -u +'%M%S')"
docker run --privileged --rm \
  -e VALANTIA_VERSION \
  -v "$PWD:/work" \
  -w /work \
  debian:trixie \
  bash -euxo pipefail scripts/build-iso.sh
```

The ISO and checksum are written to `output/`. The container needs elevated privileges because `live-build` uses system-level build operations.

### Kernel and live-boot notes

The kernel version is pinned in `scripts/build-iso.sh`; update it deliberately and test the resulting ISO before treating it as a release. The build enables `OVERLAY_FS`, `SQUASHFS`, `SQUASHFS_XZ`, and `BLK_DEV_LOOP` because a live system needs these facilities to assemble its writable root filesystem. These build settings are not proof that every machine boots correctly.

### Build cache note

The workflow caches the downloaded kernel source archive rather than the generated kernel build tree. Kernel builds create root-owned and runner-specific artifacts; trying to archive those artifacts during cache cleanup can fail with `Permission denied`. The Node.js `punycode` deprecation warning is separate and is not, by itself, the cause of a tar failure.

## Trying the live system

Use a virtual machine first when possible. For physical hardware, write the ISO to a USB drive with an imaging tool, then boot from that drive. **Writing an image erases the selected drive**; double-check the target device. Secure Boot behavior and device-specific compatibility have not been established.

The current image is a live environment, not an installer. Do not assume it provides a safe guided installation to disk. The live account credentials are intended only for testing and should not be reused for a persistent installation or exposed service.

## Known limitations

- The project is experimental; no broad hardware compatibility matrix or performance benchmark is published.
- The live-boot path needs real boot testing, including the overlay-backed writable root, on target hardware and in virtual machines.
- There is no configured disk installer in the current ISO.
- The ValantiaOS Welcome, Store, and Control Center utilities are early project components; feature coverage and reliability may be limited.
- Gaming support depends on GPU drivers, firmware, game requirements, and upstream compatibility layers; inclusion of gaming packages does not guarantee that a title will run.
- Secure Boot, persistence, upgrade behavior, accessibility, localization, and recovery workflows need further validation.

## Roadmap

This roadmap describes **proposed development priorities**, not features already delivered or release commitments. Priorities and order may change as testing and contributors reveal the most important work.

### 1. Boot reliability and release hygiene

- Reproduce live-boot failures in both virtual machines and representative physical hardware.
- Verify that the ISO contains a matching kernel and initramfs and that overlayfs, SquashFS, and loop devices are usable at boot.
- Expand automated checks for ISO creation, artifact presence, checksum generation, QEMU boot, and desktop startup.
- Keep Actions cache contents limited to portable source downloads; make cache failures distinguishable from build failures.
- Document tested firmware, boot modes, and known hardware-specific issues.

### 2. Live-session usability

- Review live account creation, credentials, sudo policy, and security implications; make defaults explicit and suitable only for temporary testing.
- Validate networking, audio, display, suspend/resume, and shutdown flows.
- Improve first-boot guidance and clearly identify live-only behavior and data persistence limits.
- Test the default desktop layout and settings at common resolutions and with different input devices.

### 3. Installer and storage story

- Decide whether the project will support a disk installer, persistence, or remain live-only before implementing a workflow.
- If an installer is chosen, design a clear, tested partitioning and bootloader flow with explicit destructive-operation warnings.
- Define encryption, filesystem, rollback/recovery, and supported firmware/UEFI expectations before presenting installation as stable.
- Validate install and recovery paths in virtual machines before recommending physical installation.

### 4. Hardware and gaming compatibility

- Establish a documented test matrix for AMD, Intel, and (where feasible) NVIDIA graphics, common network adapters, audio devices, and UEFI systems.
- Verify Vulkan availability and report driver/device information in a user-friendly way.
- Test GameMode and MangoHud integration with representative games and launchers.
- Evaluate kernel update cadence and configuration against stability, security, and hardware coverage.
- Publish measured results and known limitations rather than implying universal gaming compatibility.

### 5. Desktop apps and system experience

- Define and document the supported scope of Welcome, Store, and Control Center.
- Improve error handling, privilege prompts, package-operation feedback, and safe cancellation for system changes.
- Test APT and Flatpak workflows, including updates, failures, and offline or interrupted operations.
- Review accessibility, keyboard navigation, translations, and consistent visual behavior.

### 6. Documentation, community, and releases

- Add contribution and issue-reporting guidance, including the logs and hardware details needed for useful bug reports.
- Publish release notes, known issues, checksums, and a clear distinction between experimental snapshots and stable releases.
- Document reproducible build prerequisites, resource requirements, and the process for changing the base or kernel.
- Define release criteria only after boot, upgrade, security, and hardware testing are repeatable.

## Contributing

Bug reports, testing notes, and code contributions are welcome. When reporting a boot or hardware issue, include the ISO/workflow run used, machine or VM details, boot mode (UEFI/legacy), graphics and network hardware where relevant, the exact error, and steps to reproduce. Remove passwords, tokens, serial numbers, and other private information from logs before posting.

For code changes, keep pull requests focused and describe how you tested them. Do not claim a hardware fix or successful boot path without testing it on the relevant setup.

## License and attribution

ValantiaOS is an independent project based on Debian and is not an official Debian release. Debian components and other included software remain subject to their respective licenses and trademarks. See [`LICENSE`](LICENSE) and the upstream projects for details.
