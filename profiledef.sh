#!/usr/bin/env bash
# shellcheck disable=SC2034

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
file_permissions=(
  ["/etc/shadow"]="0:0:0400"
  ["/etc/gshadow"]="0:0:0400"
  ["/root"]="0:0:0700"
  ["/root/.gnupg"]="0:0:0700"
  ["/etc/polkit-1/rules.d"]="0:0:0750"
  ["/etc/sudoers.d"]="0:0:0750"
  ["/etc/sudoers.d/10-liveuser"]="0:0:0440"
)
