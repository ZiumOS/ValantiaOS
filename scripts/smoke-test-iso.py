#!/usr/bin/env python3
"""Validate the graphical boot configuration in the ISO's live rootfs."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(f"SMOKE TEST FAILED: {message}")


def check(root: Path, expected_version: str | None = None) -> None:
    status_path = root / "var/lib/dpkg/status"
    if not status_path.is_file():
        fail("rootfs has no dpkg status database")
    installed = set()
    for paragraph in status_path.read_text(errors="replace").split("\n\n"):
        fields = dict(line.split(": ", 1) for line in paragraph.splitlines() if ": " in line)
        if fields.get("Status") == "install ok installed":
            installed.add(fields.get("Package", ""))
    required = {
        "lightdm", "lightdm-gtk-greeter", "xorg", "xserver-xorg-core",
        "xserver-xorg-input-libinput", "xfce4-session", "xfce4-panel",
        "xfdesktop4", "xfwm4", "thunar", "xfce4-settings", "dbus-x11",
        "adwaita-icon-theme", "gnome-themes-extra", "fonts-dejavu-core",
    }
    missing = required - installed
    if missing:
        fail("packages not installed: " + ", ".join(sorted(missing)))
    if "xfce4-panel" not in installed or "xfdesktop4" not in installed:
        fail("XFCE panel/desktop packages are not installed")


    system_dir = root / "etc/systemd/system"
    default_target = system_dir / "default.target"
    if not default_target.is_symlink() or os.readlink(default_target) != "/lib/systemd/system/graphical.target":
        fail("default.target does not point to graphical.target")
    lightdm_wants = system_dir / "graphical.target.wants/lightdm.service"
    if not lightdm_wants.is_symlink() or os.readlink(lightdm_wants) != "/lib/systemd/system/lightdm.service":
        fail("LightDM is not enabled for graphical.target")
    manager = system_dir / "display-manager.service"
    if not manager.is_symlink() or os.readlink(manager) != "/lib/systemd/system/lightdm.service":
        fail("display-manager.service does not resolve to LightDM")
    print("PASS: graphical.target default and LightDM enablement are correct")

    conf = root / "etc/lightdm/lightdm.conf.d/50-valantia-autologin.conf"
    if not conf.is_file():
        fail("LightDM autologin configuration is missing")
    contents = conf.read_text()
    for setting in ("autologin-user=user", "autologin-session=xfce", "autologin-user-timeout=0"):
        if setting not in contents:
            fail(f"LightDM autologin missing {setting}")
    if not (root / "usr/share/xsessions/xfce.desktop").is_file():
        fail("XFCE X session file is missing")
    xinitrc = root / "etc/skel/.xinitrc"
    if not xinitrc.is_file() or "exec startxfce4" not in xinitrc.read_text():
        fail("skel .xinitrc does not exec startxfce4")
    greeter = root / "etc/lightdm/lightdm-gtk-greeter.conf"
    if not greeter.is_file():
        fail("LightDM GTK greeter theme configuration is missing")
    greeter_config = greeter.read_text()
    for setting in ("background=/usr/share/backgrounds/valantiaos/wall1.jpg", "theme-name=Zukitre-dark", "icon-theme-name=Adwaita"):
        if setting not in greeter_config:
            fail(f"LightDM greeter configuration missing {setting}")
    panel_config = root / "etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
    desktop_config = root / "etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
    settings_config = root / "etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
    wm_config = root / "etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"
    if not all(path.is_file() for path in (panel_config, desktop_config, settings_config, wm_config)):
        fail("XFCE default panel, wallpaper, theme, or window-manager config missing from /etc/skel")
    if "clock" not in panel_config.read_text() or "tasklist" not in panel_config.read_text() or "wall1.jpg" not in desktop_config.read_text():
        fail("XFCE panel or Valantia wallpaper configuration is incomplete")
    if 'value="Zukitre-dark"' not in settings_config.read_text():
        fail("XFCE settings do not select the Zukitre-dark theme")
    if 'value="Zukitre-dark"' not in wm_config.read_text():
        fail("XFCE window manager is not configured for the Zukitre-dark theme")
    if not (root / "usr/share/themes/Zukitre-dark/gtk-3.0/gtk.css").exists():
        fail("Zukitre-dark GTK theme is missing from the live rootfs")
    if not (root / "usr/share/themes/Zukitre-dark/xfwm4/themerc").is_file():
        fail("Zukitre-dark XFWM4 theme is missing from the live rootfs")
    print("PASS: LightDM autologin, greeter theme, and XFCE skel configuration are present")

    marker = root / "var/lib/valantiaos/graphical-session-hook-ran"
    if not marker.is_file():
        fail("graphical-session chroot hook did not leave its completion marker")
    guest_check = root / "usr/local/bin/valantiaos-graphical-check"
    autostart = root / "etc/xdg/autostart/valantiaos-graphical-check.desktop"
    if not guest_check.is_file() or not autostart.is_file() or "Exec=/usr/local/bin/valantiaos-graphical-check" not in autostart.read_text():
        fail("live graphical-session checker is missing or not autostarted")
    print("PASS: graphical-session hook and live guest checks are configured")

    release = root / "etc/os-release"
    valantia_release = root / "etc/valantiaos-release"
    if not release.is_file() or not valantia_release.is_file():
        fail("OS release metadata is missing")
    release_contents = release.read_text()
    version_id = next((line.split('=', 1)[1].strip('"') for line in release_contents.splitlines() if line.startswith("VERSION_ID=")), None)
    version = next((line.split('=', 1)[1].strip('"') for line in release_contents.splitlines() if line.startswith("VERSION=")), None)
    if not version or not version_id or not version.startswith("V.alpha.") or version_id != version:
        fail("versioned VERSION/VERSION_ID missing or inconsistent in /etc/os-release")
    if expected_version and (version != expected_version or f'VERSION="{expected_version}"' not in valantia_release.read_text()):
        fail("build version does not match /etc/os-release and /etc/valantiaos-release")
    print("PASS: unique build version is present in OS release metadata")


def extract_and_check(iso: Path, expected_version: str | None = None) -> None:
    if shutil.which("7z") is None or shutil.which("unsquashfs") is None:
        fail("requires 7z and unsquashfs")
    with tempfile.TemporaryDirectory(prefix="valantia-iso-check-") as temp:
        temp_path = Path(temp)
        iso_tree = temp_path / "iso"
        iso_tree.mkdir()
        subprocess.run(["7z", "x", "-y", f"-o{iso_tree}", str(iso)], check=True, stdout=subprocess.DEVNULL)
        grub_text = (iso_tree / "boot/grub/grub.cfg").read_text(errors="replace")
        required_boot_files = (
            "live/vmlinuz-7.2.12-valantia-kern",
            "live/initrd.img-7.2.12-valantia-kern",
            "live/vmlinuz",
            "live/initrd.img",
        )
        for boot_file in required_boot_files:
            if not any(path.name == Path(boot_file).name for path in (iso_tree / "live").glob("*") if path.is_file()):
                fail(f"ISO /live is missing {Path(boot_file).name}")
            if boot_file not in grub_text:
                fail(f"GRUB configuration does not reference {boot_file}")
        if "--id 'ValantiaOS custom kernel'" not in grub_text or "--id 'ValantiaOS Debian fallback'" not in grub_text:
            fail("ValantiaOS custom and Debian fallback menu entries are missing")
        if "live-theme/theme.txt" not in grub_text and "set theme" not in grub_text:
            fail("GRUB theme is not referenced by grub.cfg")
        print("PASS: ISO contains matching custom/fallback kernel and initrd files, GRUB entries and theme")
        squashfs = next(iso_tree.rglob("filesystem.squashfs"), None)
        if squashfs is None:
            fail("ISO does not contain filesystem.squashfs")
        rootfs = temp_path / "rootfs"
        subprocess.run(["sudo", "unsquashfs", "-f", "-d", str(rootfs), str(squashfs)], check=True)
        subprocess.run(["sudo", "chown", "-R", f"{os.getuid()}:{os.getgid()}", str(rootfs)], check=True)
        check(rootfs, expected_version)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("iso", type=Path)
    parser.add_argument("--root", type=Path)
    parser.add_argument("--version", help="expected V.alpha build version")
    args = parser.parse_args()
    if args.root:
        check(args.root.resolve(), args.version)
    else:
        if not args.iso.is_file():
            fail(f"ISO missing: {args.iso}")
        extract_and_check(args.iso.resolve(), args.version)
    print("SMOKE TEST PASSED")


if __name__ == "__main__":
    main()
