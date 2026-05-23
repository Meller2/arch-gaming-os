# AGENTS.md – Arch Gaming OS

## Goal
Custom Arch Linux gaming ISO (AMD-optimized, KDE Plasma, Garuda-like) built via GitHub Actions in `archlinux:latest --privileged` on `ubuntu-latest`.

## Build Commands
- **Local** (Arch Linux host): `sudo ./build.sh`
- **Clean build**: `sudo ./build.sh --clean`
- **CI**: push to `main` or `workflow_dispatch` — triggers `.github/workflows/build.yml`
- **Skip CI**: include `[skip ci]` in commit message

## mkarchiso Execution Order (critical for understanding what gets overwritten)

1. `_make_custom_airootfs` — copies `airootfs/` overlay into pacstrap dir (your files win here)
2. `_make_packages` — pacstrap installs packages; **package post-install scripts overwrite your overlay files** (e.g. `linux-zen` replaces `mkinitcpio.d/linux-zen.preset`, then runs `mkinitcpio` with default hooks)
3. `_make_customize_airootfs` — runs `airootfs/root/customize_airootfs.sh` in chroot (your chance to fix what packages broke)
4. `_make_boot_on_iso9660` — copies `/boot/vmlinuz-*` and `/boot/initramfs-*` from pacstrap dir to ISO

**Implication**: Overlay files for `mkinitcpio.conf`, presets, or anything a package owns will be overwritten at step 2. Use `customize_airootfs.sh` to re-write configs and re-run commands AFTER packages are installed.

## Critical Gotchas

### `customize_airootfs.sh` is the only reliable post-install hook
It writes `mkinitcpio.conf` with archiso hooks and re-runs `mkinitcpio -p linux-zen`, then creates the `liveuser` account. Without this, initramfs builds with default desktop hooks (no `archiso`) and the live system cannot mount its SquashFS root.

### `archiso` ≠ `mkinitcpio-archiso`
- `archiso` = build tool (provides `mkarchiso`) — installed on the BUILD HOST via CI workflow
- `mkinitcpio-archiso` = initcpio hooks for live boot (`/usr/lib/initcpio/hooks/archiso`) — must be in `packages.x86_64` so it's installed INSIDE the airootfs chroot where mkinitcpio runs

### Kernel is `linux-zen`, not `linux`
All bootloader configs must reference `vmlinuz-linux-zen` and `initramfs-linux-zen.img`. The default archiso releng configs use `vmlinuz-linux` — our `grub/` and `syslinux/` directories contain custom configs with the correct paths. Do NOT delete them or let `build.sh` copy defaults.

### CRLF line endings break bash scripts in Arch container
Windows dev environment commits CRLF. CI has a `dos2unix` step, and `.gitattributes` enforces `* text=auto eol=lf`. Always `git add --renormalize .` after adding new text files.

### file_permissions paths must exist on disk
Every entry in `profiledef.sh` `file_permissions[]` must exist under `airootfs/` before `mkarchiso` runs, or `realpath` validation fails. Keep empty dirs with `.gitkeep`.

### No git symlinks on Windows
`display-manager.service` symlink is created at build time by `build.sh`, not stored in git.

### Chaotic-AUR: install keyring via `pacman -U <url>`, not `pacman -Sy`
`pacman -Sy` only syncs DBs. `build.sh` uses `pacman -U` with direct URLs for `chaotic-keyring` and `chaotic-mirrorlist`. The `pacman.conf` just adds the `[chaotic-aur]` server entry.

### PXE hooks removed from initramfs
`archiso_pxe_common`, `archiso_pxe_nbd`, `archiso_pxe_http`, `archiso_pxe_nfs` are excluded because they require `ipconfig`, `nbd-client`, `nfsmount` which aren't installed. PXE boot is irrelevant for a gaming ISO.

### Obsolete packages
- `plasma-wayland-session` → merged into `plasma-workspace`
- `latte-dock` → not in official repos or Chaotic-AUR
- `libva-mesa-driver` / `lib32-libva-mesa-driver` → pulled as deps of `mesa`/`lib32-mesa`; explicit listing causes provider conflict prompts with Chaotic-AUR's `mesa-tkg-git`

### Bootmodes: use current format
`profiledef.sh` uses `('bios.syslinux' 'uefi.grub')`. Old formats like `bios.syslinux.mbr`, `uefi-x64.grub.esp` etc. are deprecated and mkarchiso converts them with warnings.

## Live User
- Account: `liveuser` (UID 1000), no password, groups: wheel, autologin, audio, video, optical, storage, games, power
- Created in `customize_airootfs.sh` (not overlay passwd/shadow — those get overwritten by packages too, but mkarchiso reads them BEFORE pacstrap to copy `/etc/skel/` to user homes)
- SDDM autologin: `airootfs/etc/sddm.conf.d/autologin.conf` → `liveuser` / `plasma.desktop`
- Wheel group has passwordless sudo (set in `customize_airootfs.sh`)

## Theming (current state)
Stock KDE Breeze. Customization lives in `airootfs/etc/skel/.config/` and is copied to liveuser's home. Current configs:
- Plasma panel layout, wallpaper reference, MangoHud, fastfetch, Kvantum, kdeglobals
- To change: edit skel configs and/or add packages (icon themes, cursor themes, SDDM themes) to `packages.x86_64`

## Known Build Failures & Fixes
| Symptom | Root Cause | Fix |
|---|---|---|
| `Hook 'archiso' cannot be found` | `mkinitcpio-archiso` not installed in chroot | Add to `packages.x86_64` (NOT `archiso`) |
| `Switch Root` / `Failed to mount` | initramfs built without archiso hooks | `customize_airootfs.sh` writes mkinitcpio.conf and re-runs mkinitcpio AFTER packages |
| `wrong fs type` on boot | `block`/`filesystems` hooks missing from initramfs | Ensure full HOOKS array in `customize_airootfs.sh` |
| GRUB boots `vmlinuz-linux` (not found) | Default archiso configs reference `linux` kernel | Custom `grub/` and `syslinux/` dirs with `linux-zen` paths |
| `plasma-wayland-session: target not found` | Package merged into `plasma-workspace` | Use `plasma-workspace` instead |
| `latte-dock: target not found` | Not in repos | Remove from packages |
| Provider conflict on `libva-mesa-driver` | Chaotic-AUR provides `mesa-tkg-git` as alternative | Remove explicit `libva-mesa-driver` entries |
| `Outside of valid path` on file_permissions | Directory doesn't exist in airootfs | Add `.gitkeep` to empty dirs |
