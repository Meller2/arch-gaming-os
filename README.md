# Arch Gaming OS

A custom Arch Linux live ISO optimized for AMD gaming, built with the Hyprland Wayland compositor. Automated via GitHub Actions.

## Features

- **Linux-zen kernel** — low-latency, gaming-optimized
- **AMD-optimized drivers** — Vulkan, Mesa (64-bit + 32-bit)
- **Hyprland Wayland compositor** — with SDDM, Waybar, wofi, mako, kitty
- **Gaming tools** — Steam, Lutris, Heroic Games Launcher, Wine, Protonup-qt
- **Performance overlays** — MangoHud, GameMode, GOverlay
- **Chaotic-AUR** — prebuilt packages (heroic-games-launcher-bin, etc.)
- **PipeWire** — modern audio stack
- **Fastfetch** — system info on terminal launch

## Download

Grab the latest ISO from [GitHub Actions Artifacts](https://github.com/Meller2/arch-gaming-os/actions).

## Build Locally

Requires an Arch Linux system with `archiso` installed:

```bash
sudo ./build.sh
```

Clean build:

```bash
sudo ./build.sh --clean
```

The resulting ISO will be in `out/`.

## CI/CD

Every push to `main` triggers a GitHub Actions build using `archlinux:latest` in privileged Docker mode. The workflow:

1. Installs dependencies (archiso, grub, syslinux, dos2unix)
2. Converts all text files to LF line endings
3. Runs `build.sh --clean`
4. Uploads the ISO as a GitHub artifact (7-day retention)

## Project Structure

```
.
├── .github/workflows/build.yml   # CI pipeline
├── .gitattributes                # Force LF line endings
├── .gitignore                    # Exclude build artifacts
├── AGENTS.md                     # Project documentation & gotchas
├── build.sh                      # Main build script
├── profiledef.sh                 # archiso profile definition
├── packages.x86_64               # Package list for the ISO
├── pacman.conf                   # pacman config with Chaotic-AUR
├── grub/                         # GRUB bootloader configs (linux-zen)
├── syslinux/                     # Syslinux bootloader configs (linux-zen)
└── airootfs/                     # Root filesystem overlay
    ├── etc/
    │   ├── hostname
    │   ├── locale.conf
    │   ├── passwd / shadow       # liveuser account
    │   ├── sddm.conf.d/          # Autologin config
    │   ├── skel/.config/         # User configs (Hyprland, waybar, wofi, MangoHud, fastfetch)
    │   ├── polkit-1/rules.d/
    │   └── sudoers.d/
    └── root/
        └── customize_airootfs.sh # Post-install: mkinitcpio + user setup
```

## Boot Modes

- BIOS: Syslinux (MBR)
- UEFI: GRUB

## Live User

The ISO boots into a `liveuser` account (no password) with:
- Autologin via SDDM into Hyprland
- Passwordless sudo (wheel group)
- Preconfigured Hyprland desktop, Waybar panel, wofi launcher, MangoHud, Fastfetch

## License

This project is provided as-is. Individual packages retain their respective licenses.
