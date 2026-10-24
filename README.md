# ValantiaOS V.(alpha.<month>.<year>.<hour>.<run>.<attempt>)

![ValantiaOS banner](https://i.ibb.co.com/rK2BSV8v/Gemini-Generated-Image-hydhszhydhszhydh-1.jpg)

<!-- TEST-STATUS:START -->
Tests have not yet been recorded as passing for a build.
<!-- TEST-STATUS:END -->

## Current image

ValantiaOS is an experimental Debian GNU/Linux 13 (Trixie) AMD64 live image using XFCE and LightDM. Build versions use UTC and include the GitHub run number and attempt so simultaneous or retried builds remain unique. The build workflow creates the versioned ISO and checksum; the separate test workflow inspects the ISO contents and boots it under QEMU/OVMF. A passing status is written here only after the required checks succeed.

## Build and test

Start **Build ValantiaOS** from the GitHub Actions tab. After a successful build, **Test ValantiaOS ISO** downloads that run's artifact and checks its checksum, root filesystem configuration, kernel/initrd names, GRUB menu, and UEFI boot screenshot. Artifacts are retained for seven days. Do not treat an untested ISO as a release.

For local builds, provide a unique `VALANTIA_VERSION` and run `scripts/build-iso.sh` inside a privileged Debian Trixie container. The script builds the custom Linux kernel and hybrid live ISO; this requires network access, substantial disk, memory, and CPU.

## Current components

- Debian 13 Trixie, amd64, live-build hybrid ISO.
- XFCE desktop with LightDM autologin, Adwaita theme/icons, a configured panel, and ValantiaOS wallpaper.
- Custom Linux `7.2.12-valantia-kern` intended as the default boot kernel, plus Debian's standard kernel as fallback.
- Kernel configuration explicitly checks overlayfs, SquashFS, loop, DRM/framebuffer and input options.
- QEMU/OVMF test evidence (serial log, screenshot and OCR text) is uploaded for each test run.

## Known limitations

The ISO is experimental and is not a disk installer. Passing CI checks cover the tested QEMU/OVMF configuration only; they do not establish compatibility with all UEFI/BIOS implementations or physical hardware. Secure Boot, persistence, broad device support, upgrade and recovery behavior need separate validation.

## Roadmap

1. **Boot and release quality:** validate both BIOS and UEFI boot paths; retain matching kernel/initrd artifacts; check GRUB theme and menu on real hardware; test fallback behavior; publish checksums and release notes.
2. **Desktop usability:** verify panel, wallpaper, themes, icons, login, networking, audio, display scaling, suspend/resume and shutdown across common hardware and resolutions.
3. **Hardware coverage:** maintain a test matrix for AMD/Intel/NVIDIA graphics, networking, audio, UEFI and legacy BIOS; document known limitations rather than promise universal compatibility.
4. **Live session security:** review default account, credentials, sudo policy, and data persistence; make test-only defaults explicit.
5. **Installer decision:** determine whether ValantiaOS remains live-only or gains a disk installer; design destructive partitioning, encryption and recovery flows only after that decision.
6. **Applications and community:** improve Welcome, Store and Control Center reliability, accessibility and localization; document contribution, bug reports and supported build prerequisites.

These are development priorities, not delivered features or release commitments.

## License and attribution

ValantiaOS is an independent Debian-based project and is not an official Debian release. Included components remain subject to their respective licenses and trademarks; see [`LICENSE`](LICENSE).
