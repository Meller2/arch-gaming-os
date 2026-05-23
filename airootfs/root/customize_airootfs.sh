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

groupadd -r autologin
useradd -m -G wheel,autologin,audio,video,optical,storage,games,power -s /usr/bin/bash liveuser
echo "liveuser:liveuser" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

systemctl enable sshd NetworkManager avahi-daemon bluetooth

sudo -u liveuser xdg-user-dirs-update
