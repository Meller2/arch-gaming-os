# AGENTS.md – Arch Gaming OS

## Goal
Custom Arch Linux gaming ISO (AMD-optimized, Hyprland Wayland compositor) built via GitHub Actions in `archlinux:latest --privileged` on `ubuntu-latest`.

## Build Commands
- **Local** (Arch Linux host): `sudo ./build.sh`
- **Clean build**: `sudo ./build.sh --clean`
- **CI**: push to `main` or `workflow_dispatch` — triggers `.github/workflows/build.yml`
- **Skip CI**: include `[skip ci]` in commit message

## Windows ↔ WSL Sync
Dev environment is Windows + WSL2 Arch. The WSL project is at `/root/arch-gaming-os`. After editing files on the Windows side, sync to WSL before building or deploying:
```
wsl -d Arch -u root bash -c "cp -r /mnt/c/Users/Ilzat/Documents/'qwen 3.5'/Linux-distibution/* /root/arch-gaming-os/"
```
After editing in WSL, sync back:
```
wsl -d Arch -u root bash -c "cp /root/arch-gaming-os/<file> /mnt/c/Users/Ilzat/Documents/'qwen 3.5'/Linux-distibution/<file>"
```
**Git commits happen from the Windows working directory** — always verify the Windows-side files are current before committing.

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

### Obsolete packages
`libva-mesa-driver` / `lib32-libva-mesa-driver` → pulled as deps of `mesa`/`lib32-mesa`; explicit listing causes provider conflict prompts with Chaotic-AUR's `mesa-tkg-git`

### Wallpaper file missing at runtime
`hyprpaper.conf` references `/usr/share/backgrounds/gaming-wallpaper.png` which is NOT shipped in the overlay. Hyprpaper will log errors but Hyprland still starts. Add the file to `airootfs/usr/share/backgrounds/` to fix.

### Bootmodes: use current format
`profiledef.sh` uses `('bios.syslinux' 'uefi.grub')`. Old formats like `bios.syslinux.mbr`, `uefi-x64.grub.esp` etc. are deprecated and mkarchiso converts them with warnings.

## Hyprland 0.53+ / 0.55+ Syntax

### Use .conf format (Lua parser bug in 0.55)
The Lua parser cannot handle hyphenated identifiers like `exec-once` (treated as subtraction). Use traditional hyprland.conf format — fully functional, just shows a deprecation warning.

### Boolean flags require explicit values
`float 1`, `blur on` — standalone `float`, `blur` cause `invalid field float: missing a value`.

### Window matchers require `match:` prefix with SPACE separator
- Correct: `windowrule = float 1, match:class ^(pavucontrol)$`
- Wrong: `windowrule = float 1, class:^(pavucontrol)$` (no `match:`, colon instead of space)

### Properties renamed to snake_case
- `idleinhibit` → `idle_inhibit` (e.g. `windowrule = idle_inhibit focus, match:class ^(steam)$`)
- `ignorezero` removed → use `ignore_alpha` with value 0–1

### layerrule requires `match:namespace`
- Correct: `layerrule = blur on, match:namespace wofi`
- Correct: `layerrule = ignore_alpha 1, match:namespace wofi`
- Wrong: `layerrule = blur 1, wofi`
- Wrong: `layerrule = ignorezero 1, wofi`

### Other 0.55+ changes
- `togglesplit` → `layoutmsg, togglesplit`
- Removed: `vfr`, `no_direct_scanout`, `explicit_sync`, `dwindle` section, `gestures:workspace_swipe`
- SDDM must be ≥0.20.0 (bug #1476: 90s shutdown with Wayland)
- `hyprpolkitagent` must run at `exec-once` or GUI auth dialogs hang
- `xorg-xwayland` replaces `xorg-server` — do NOT install `xorg-server`

## Live User
- Account: `liveuser` (UID 1000), password: `liveuser`, groups: wheel, autologin, audio, video, optical, storage, games, power
- Created in `customize_airootfs.sh` (not overlay passwd/shadow — those get overwritten by packages too, but mkarchiso reads them BEFORE pacstrap to copy `/etc/skel/` to user homes)
- SDDM autologin: `airootfs/etc/sddm.conf.d/autologin.conf` → `liveuser` / `hyprland.desktop`
- Wheel group has passwordless sudo (set in `customize_airootfs.sh` + `/etc/sudoers.d/10-liveuser` mode 0440)

## Live Debugging & mDNS (archgaming.local)
The live system includes NetworkManager, `sshd`, and `avahi-daemon` (mDNS) enabled by default. Default password: `liveuser`.

### Quick deploy without rebuilding ISO
```
sshpass -p 'liveuser' scp -o StrictHostKeyChecking=no airootfs/etc/skel/.config/hypr/hyprland.conf liveuser@172.16.115.128:~/.config/hypr/hyprland.conf
sshpass -p 'liveuser' ssh -o StrictHostKeyChecking=no liveuser@172.16.115.128 'export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/); hyprctl reload'
```
- `HYPRLAND_INSTANCE_SIGNATURE` is required over SSH — find it via `ls /run/user/1000/hypr/`
- mDNS hostname: `liveuser@archgaming.local` (once avahi resolves on network)

### VM graphics fix
`.profile` auto-detects VMs via `systemd-detect-virt`. If vmware/oracle/qemu, exports `LIBGL_ALWAYS_SOFTWARE=1` and `WLR_NO_HARDWARE_CURSORS=1`. On real hardware these are not set, preserving gaming performance.

### Root access on live ArchISO
Root autologins on TTY3 (Ctrl+Alt+F3) with no password. Use this when SSH lacks sudo/pkexec (e.g., first-time setup on a fresh ISO).

## Known Build Failures & Fixes
| Symptom | Root Cause | Fix |
|---|---|---|
| `Hook 'archiso' cannot be found` | `mkinitcpio-archiso` not installed in chroot | Add to `packages.x86_64` (NOT `archiso`) |
| `Switch Root` / `Failed to mount` | initramfs built without archiso hooks | `customize_airootfs.sh` writes mkinitcpio.conf and re-runs mkinitcpio AFTER packages |
| `wrong fs type` on boot | `block`/`filesystems` hooks missing from initramfs | Ensure full HOOKS array in `customize_airootfs.sh` |
| GRUB boots `vmlinuz-linux` (not found) | Default archiso configs reference `linux` kernel | Custom `grub/` and `syslinux/` dirs with `linux-zen` paths |
| Provider conflict on `libva-mesa-driver` | Chaotic-AUR provides `mesa-tkg-git` as alternative | Remove explicit `libva-mesa-driver` entries |
| Hyprland fails to start / black screen | SDDM < 0.20.0 | Ensure SDDM ≥0.20.0 via `extra` repo |
| `hyprland.desktop` session not found | `hyprland` package not installed or SDDM cache stale | Verify `hyprland` in packages list |
| GUI auth dialogs hang | No polkit agent running | Ensure `hyprpolkitagent` is in `exec-once` |
| `Outside of valid path` on file_permissions | Directory doesn't exist in airootfs | Add `.gitkeep` to empty dirs |
| `invalid field float: missing a value` | Boolean flag without value | Use `float 1` instead of `float` |
| `invalid field class:^(...): missing a value` | Matcher without `match:` prefix | Use `match:class ^(regex)$` instead of `class:^(...)$` |
| `invalid field idleinhibit` | Property renamed in 0.53+ | Use `idle_inhibit` instead of `idleinhibit` |
| `invalid field ignorezero` | Property removed in 0.53+ | Use `ignore_alpha 1` instead of `ignorezero 1` |
| `invalid layerrule: wofi` | Layer rules need `match:namespace` | Use `layerrule = blur on, match:namespace wofi` |
| Kitty crashes instantly in VMware | VMware GPU acceleration incompatible with Wayland | `LIBGL_ALWAYS_SOFTWARE=1` auto-set via `.profile` when `systemd-detect-virt` = vmware/oracle/qemu |

## Build Output
- ISO appears in `out/` directory after successful build
- CI uploads artifact named `Arch-Gaming-ISO` with 7-day retention
