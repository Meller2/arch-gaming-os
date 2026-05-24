#!/usr/bin/env bash
#
# Arch Gaming OS — local & CI build entry-point.
#
# Usage:
#   sudo ./build.sh             # incremental build
#   sudo ./build.sh --clean     # wipe work/ and out/ before building
#
# Must run on Arch Linux (or an Arch container) with `archiso` installed.

set -euo pipefail

# ---------- paths ----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/work"
OUT_DIR="${SCRIPT_DIR}/out"
AIROOTFS_DIR="${SCRIPT_DIR}/airootfs"

# ---------- pretty logging -------------------------------------------------
info()  { printf '\e[1;34m[INFO]\e[0m  %s\n' "$*"; }
warn()  { printf '\e[1;33m[WARN]\e[0m  %s\n' "$*" >&2; }
error() { printf '\e[1;31m[ERROR]\e[0m %s\n' "$*" >&2; exit 1; }

# ---------- preconditions --------------------------------------------------
[[ $EUID -eq 0 ]] || error "This script must be run as root (use sudo)."

command -v mkarchiso >/dev/null \
    || error "archiso is not installed. Install with: pacman -S archiso"

# ---------- argument parsing ----------------------------------------------
CLEAN=false
while (( $# )); do
    case "$1" in
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -h|--help)
            sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            error "Unknown argument: $1 (try --help)"
            ;;
    esac
done

if [[ "${CLEAN}" == true ]]; then
    info "Cleaning previous build directories..."
    rm -rf "${WORK_DIR}" "${OUT_DIR}"
fi

# ---------- Chaotic-AUR keyring (host) ------------------------------------
# The build pulls packages from Chaotic-AUR, so the host's pacman needs to
# trust their signing key. Idempotent.
info "Verifying Chaotic-AUR keyring on host..."
if ! pacman-key --list-keys 3056513887B78AEB >/dev/null 2>&1; then
    warn "Chaotic-AUR key missing; importing..."
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com \
        || pacman-key --recv-key 3056513887B78AEB --keyserver hkps://keys.openpgp.org
    pacman-key --lsign-key 3056513887B78AEB

    info "Installing chaotic-keyring and chaotic-mirrorlist on host..."
    pacman -U --noconfirm --needed \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
else
    info "Chaotic-AUR keyring is already trusted."
fi

# ---------- runtime overlay tweaks ----------------------------------------
# Symlinks aren't preserved well on NTFS / Git-for-Windows checkouts, so we
# create the SDDM display-manager.service symlink dynamically.
info "Wiring display-manager.service -> sddm.service..."
install -d "${AIROOTFS_DIR}/etc/systemd/system"
ln -sf "/usr/lib/systemd/system/sddm.service" \
    "${AIROOTFS_DIR}/etc/systemd/system/display-manager.service"

# Pull the syslinux splash from the system profile when missing.
if [[ ! -f "${SCRIPT_DIR}/syslinux/splash.png" ]]; then
    if [[ -f /usr/share/archiso/configs/releng/syslinux/splash.png ]]; then
        info "Importing syslinux splash.png from system archiso profile..."
        cp /usr/share/archiso/configs/releng/syslinux/splash.png \
            "${SCRIPT_DIR}/syslinux/"
    else
        warn "splash.png not found; syslinux menu will be text-only."
    fi
fi

# Normalise permissions before pacstrap reads the overlay.
info "Normalising overlay permissions..."
chmod 0755 "${SCRIPT_DIR}/profiledef.sh" "${SCRIPT_DIR}/build.sh"
if [[ -d "${AIROOTFS_DIR}/etc/skel" ]]; then
    find "${AIROOTFS_DIR}/etc/skel" -type d -exec chmod 0755 {} +
    find "${AIROOTFS_DIR}/etc/skel" -type f -exec chmod 0644 {} +
fi
if [[ -d "${AIROOTFS_DIR}/etc/skel/.local/bin" ]]; then
    find "${AIROOTFS_DIR}/etc/skel/.local/bin" -type f -exec chmod 0755 {} +
fi
if [[ -d "${AIROOTFS_DIR}/etc/profile.d" ]]; then
    find "${AIROOTFS_DIR}/etc/profile.d" -type f -exec chmod 0755 {} +
fi

# ---------- build ----------------------------------------------------------
info "Starting archiso build..."
install -d "${OUT_DIR}"
mkarchiso -v -w "${WORK_DIR}" -o "${OUT_DIR}" "${SCRIPT_DIR}"

info "Build finished. ISO is in: ${OUT_DIR}"
