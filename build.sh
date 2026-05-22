#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/work"
OUT_DIR="${SCRIPT_DIR}/out"
AIROOTFS_DIR="${SCRIPT_DIR}/airootfs"

# Helper function for colored output
info() {
    echo -e "\e[1;34m[INFO]\e[0m $1"
}

warn() {
    echo -e "\e[1;33m[WARN]\e[0m $1"
}

error() {
    echo -e "\e[1;31m[ERROR]\e[0m $1"
    exit 1
}

# 1. Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (sudo)."
fi

# 2. Check if archiso is installed
if ! command -v mkarchiso &> /dev/null; then
    error "archiso is not installed. Please install it using: pacman -S archiso"
fi

# Parse arguments
CLEAN_ONLY=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--clean)
            info "Cleaning up previous build directories..."
            rm -rf "${WORK_DIR}" "${OUT_DIR}"
            info "Cleanup complete."
            if [[ "$2" == "--clean-only" ]]; then
                exit 0
            fi
            shift
            ;;
        *)
            error "Unknown parameter passed: $1. Use -c or --clean to clean previous builds."
            ;;
    esac
done

# 3. Handle Chaotic-AUR Keyring on Host
info "Checking Chaotic-AUR keyring on host..."
if ! pacman-key -l "fusi739@gmail.com" &>/dev/null && ! pacman-key -l "chaotic-aur" &>/dev/null; then
    warn "Chaotic-AUR keys not found on host. Attempting to initialize them..."
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || \
        pacman-key --recv-key 3056513887B78AEB --keyserver hkps://keys.openpgp.org
    pacman-key --lsign-key 3056513887B78AEB
    
    info "Installing chaotic-keyring and chaotic-mirrorlist..."
    pacman -U --noconfirm --needed \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
else
    info "Chaotic-AUR keyring is already trusted on host."
fi

# 4. Dynamically create the systemd symlink inside airootfs
# This avoids host OS limitations (like building on NTFS/Windows or Git symlink issues)
info "Configuring display manager symlink..."
mkdir -p "${AIROOTFS_DIR}/etc/systemd/system"
ln -sf "/usr/lib/systemd/system/sddm.service" "${AIROOTFS_DIR}/etc/systemd/system/display-manager.service"

# Copy grub and syslinux bootloader configurations from the system profile if missing
info "Checking bootloader configurations..."
if [ ! -d "${SCRIPT_DIR}/grub" ]; then
    if [ -d "/usr/share/archiso/configs/releng/grub" ]; then
        info "Copying default GRUB configuration from system..."
        cp -r "/usr/share/archiso/configs/releng/grub" "${SCRIPT_DIR}/"
    else
        warn "Default GRUB configuration not found in /usr/share/archiso/configs/releng/grub"
    fi
fi

if [ ! -d "${SCRIPT_DIR}/syslinux" ]; then
    if [ -d "/usr/share/archiso/configs/releng/syslinux" ]; then
        info "Copying default Syslinux configuration from system..."
        cp -r "/usr/share/archiso/configs/releng/syslinux" "${SCRIPT_DIR}/"
    else
        warn "Default Syslinux configuration not found in /usr/share/archiso/configs/releng/syslinux"
    fi
fi

# Ensure correct permissions for critical files in airootfs
info "Setting permissions on configuration files..."
chmod 755 "${SCRIPT_DIR}/profiledef.sh"
if [ -d "${AIROOTFS_DIR}/etc/skel" ]; then
    find "${AIROOTFS_DIR}/etc/skel" -type d -exec chmod 755 {} +
    find "${AIROOTFS_DIR}/etc/skel" -type f -exec chmod 644 {} +
fi

# 5. Execute build
info "Starting archiso build process..."
mkdir -p "${OUT_DIR}"
mkarchiso -v -w "${WORK_DIR}" -o "${OUT_DIR}" "${SCRIPT_DIR}"

info "Build finished successfully! Your ISO is located in: ${OUT_DIR}"
