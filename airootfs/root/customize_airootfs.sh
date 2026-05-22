#!/usr/bin/env bash

cat > /etc/mkinitcpio.conf << 'MKINITCPIOEOF'
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev microcode modconf kms memdisk archiso archiso_loop_mnt block filesystems keyboard)
COMPRESSION="xz"
COMPRESSION_OPTIONS=(-9e)
MKINITCPIOEOF

mkinitcpio -p linux-zen
