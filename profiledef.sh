#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# Arch Gaming OS — archiso profile definition.
# See https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/docs/README.profile.rst
#
# NOTE: file_permissions[] entries only apply to files present in the overlay
# BEFORE pacstrap runs. Entries for files installed by packages (e.g. /etc/shadow)
# emit a harmless warning and are no-ops, so we keep this list overlay-only.

iso_name="archgaming"
iso_label="ARCH_GAMING_$(date +%Y%m)"
iso_publisher="Arch Gaming OS <https://github.com/arch-gaming-os/arch-gaming-os>"
iso_application="Arch Gaming OS Live/Rescue Medium"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.grub')
arch="x86_64"
pacman_conf="pacman.conf"
preserve_container="gnu-tar"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/root"]="0:0:0700"
  ["/root/.gnupg"]="0:0:0700"
  ["/etc/polkit-1/rules.d"]="0:0:0750"
  ["/etc/sudoers.d"]="0:0:0750"
  ["/etc/sudoers.d/10-liveuser"]="0:0:0440"
)
