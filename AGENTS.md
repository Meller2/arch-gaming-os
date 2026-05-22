# AGENTS.md – Arch Gaming OS

## Goal
Build a custom Arch Linux gaming ISO (AMD-optimized, KDE Plasma, Garuda-like) via GitHub Actions (`archlinux:latest --privileged` on `ubuntu-latest`).

## Key Architecture
- **archiso profile**: `profiledef.sh` + `packages.x86_64` + `pacman.conf` + `airootfs/` overlay
- **Chaotic-AUR** is the only AUR repo — prebuilt `heroic-games-launcher-bin`, etc.
- **Build**: `build.sh` (Chaotic key import, symlinks, bootloader copies, then `mkarchiso`)
- **CI**: `.github/workflows/build.yml` — push to `main` or `workflow_dispatch`

## Critical Gotchas

### 1. file_permissions paths must exist on disk
Every entry in `profiledef.sh` `file_permissions[]` must exist under `airootfs/` *before* `mkarchiso` runs, or mkarchiso's `realpath` validation fails with "Outside of valid path". Keep empty dirs with `.gitkeep` in git.

### 2. No git symlinks — create at build time
Windows/git cannot store the `display-manager.service` symlink. `build.sh` creates it at runtime: `ln -sf /usr/lib/systemd/system/sddm.service airootfs/etc/systemd/system/display-manager.service`

### 3. Chaotic-AUR: install keyring via URL, not pacman.conf
`build.sh` uses `pacman -U <url>` for `chaotic-keyring` and `chaotic-mirrorlist`. The `pacman.conf` just adds the `[chaotic-aur]` repository server.

### 4. pacman -Sy does NOT accept URLs
Use `pacman -U <url>` for any package URL install. `-Sy` only syncs DBs.

### 5. Bootloader configs
`grub/` and `syslinux/` dirs are copied from `/usr/share/archiso/configs/releng/` at build time if absent. Both `grub` and `syslinux` must be in `packages.x86_64` *and* installed via `pacman -S` in the CI workflow before checkout.

## Build Commands
- **Local** (inside Arch Linux): `sudo ./build.sh`
- **Clean**: `sudo ./build.sh --clean`
- **CI only**: push to `main` or trigger `workflow_dispatch` on GitHub

## Package List Notes
- `packages.x86_64` includes both x86_64 and lib32 gaming packages (steam, lutris, heroic-games-launcher-bin, wine-staging, mangohud, gamemode, protonup-qt)
- `chaotic-keyring` and `chaotic-mirrorlist` listed as packages for the ISO image (already installed on the build host via URL)

## Known Build Failures & Fixes
| Symptom | Root Cause | Fix |
|---|---|---|
| `Failed to set permissions on '...polkit-1/rules.d'. Outside of valid path` | file_permissions target dir missing | Add empty dir to `airootfs/etc/polkit-1/rules.d/` |
| `syslinux: command not found` | `syslinux` not in CI deps or packages.x86_64 | Add `syslinux` + `grub` to both |
