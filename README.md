# Arch Gaming OS

A custom Arch Linux live ISO tuned for AMD gaming, running the Hyprland
Wayland compositor. Builds are produced reproducibly through GitHub Actions.

## Features

- **linux-zen kernel** with `mkinitcpio-archiso` for live boot
- **AMD-optimised graphics stack** — Mesa, Vulkan-radeon, 32-bit multilib
- **Hyprland (0.55+)** desktop with SDDM autologin
- **Gaming toolkit** — Steam, Lutris, Heroic, Wine-staging, Protonup-qt
- **Performance overlays** — MangoHud, GameMode, GOverlay
- **Chaotic-AUR** — prebuilt AUR packages (e.g. `heroic-games-launcher-bin`)
- **PipeWire** audio stack and **Bluetooth** out of the box
- **Live debugging** — SSH + Avahi mDNS (`archgaming.local`)

## Download

The latest ISO is published as a GitHub Actions artifact:
<https://github.com/Meller2/arch-gaming-os/actions> (look for
`Arch-Gaming-ISO`, 7-day retention).

## Build Locally

Requires an Arch Linux host (or `archlinux:latest` container) with `archiso`:

```bash
sudo ./build.sh           # incremental build
sudo ./build.sh --clean   # wipe work/ and out/ first
```

The resulting ISO lands in `out/`.

## CI/CD

`.github/workflows/build.yml` runs on every push to `main` and on manual
`workflow_dispatch`:

1. Spins up an `archlinux:latest --privileged` container on `ubuntu-latest`
2. Installs build dependencies (`archiso`, `grub`, `syslinux`, `dos2unix`)
3. Normalises line endings to LF (Windows contributors)
4. Runs `./build.sh --clean`
5. Uploads `out/*.iso` as the `Arch-Gaming-ISO` artifact

Include `[skip ci]` in a commit message to bypass the workflow.

## Project Structure

```
.
├── .github/workflows/build.yml   CI pipeline
├── .gitattributes                Force LF line endings
├── .gitignore                    Exclude build artifacts
├── AGENTS.md                     Maintainer notes and gotchas
├── README.md                     This file
├── build.sh                      Build entry point
├── profiledef.sh                 archiso profile definition
├── packages.x86_64               Package list installed into the ISO
├── pacman.conf                   pacman config with Chaotic-AUR
├── grub/                         UEFI bootloader configs (linux-zen)
├── syslinux/                     BIOS bootloader configs (linux-zen)
└── airootfs/                     Root filesystem overlay
    ├── etc/
    │   ├── hostname              "archgaming"
    │   ├── locale.conf
    │   ├── profile.d/
    │   │   └── vm-detect.sh      Software-GL fallback when in a VM
    │   ├── sddm.conf.d/          Autologin into Hyprland
    │   ├── skel/                 Default user dotfiles (Hyprland, waybar,
    │   │                         wofi, MangoHud, fastfetch, ...)
    │   ├── polkit-1/rules.d/
    │   └── sudoers.d/            Passwordless sudo for liveuser
    ├── root/
    │   └── customize_airootfs.sh Post-install: mkinitcpio + user setup
    └── usr/share/backgrounds/    Wallpapers shipped with the ISO
```

## Boot Modes

- **BIOS** — Syslinux (MBR)
- **UEFI** — GRUB

## Live User

The ISO boots straight into a `liveuser` account:

- Password: `liveuser` (also for sudo)
- Autologin to Hyprland via SDDM (`hyprland.desktop` session)
- Member of `wheel`, `autologin`, `audio`, `video`, `optical`, `storage`,
  `games`, `power`
- Passwordless sudo (both via `%wheel` and `/etc/sudoers.d/10-liveuser`)

Root autologin is available on **TTY3** (`Ctrl+Alt+F3`) for recovery work.

## VM-Friendly Defaults

`/etc/profile.d/vm-detect.sh` exports `LIBGL_ALWAYS_SOFTWARE=1` and
`WLR_NO_HARDWARE_CURSORS=1` only when `systemd-detect-virt` reports a
hypervisor (`vmware`, `oracle`, `qemu`, `kvm`, `microsoft`). On bare metal it
is a no-op, so AMD hardware acceleration stays enabled.

## License

Code in this repository is provided as-is. Individual packages installed by
the ISO retain their own licenses.
