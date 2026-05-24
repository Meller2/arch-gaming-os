#!/usr/bin/env bash
#
# Arch Gaming OS — in-chroot customisation.
#
# mkarchiso runs this script inside the pacstrap'd root AFTER packages are
# installed. Anything written here wins over package post-install scripts.
#
# Responsibilities:
#   1. Re-generate mkinitcpio.conf with the archiso hooks and rebuild the
#      initramfs so the live system can mount its SquashFS root.
#   2. Create the unprivileged `liveuser` account used by SDDM autologin.
#   3. Grant the wheel group passwordless sudo.
#   4. Enable the services required at boot (network, ssh, mDNS, bluetooth).
#   5. Initialise per-user XDG directories.

set -euo pipefail

# 1. Rewrite mkinitcpio.conf and rebuild the initramfs for linux-zen.
#    The linux-zen pacman hook installs a default config without archiso
#    hooks, so we must overwrite it AFTER packages are installed.
cat > /etc/mkinitcpio.conf <<'EOF'
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev microcode modconf kms memdisk archiso archiso_loop_mnt block filesystems keyboard)
COMPRESSION="xz"
COMPRESSION_OPTIONS=(-9e)
EOF

mkinitcpio -p linux-zen

# 2. Create the live user. `useradd` is idempotent-safe via the existence check
#    so a re-run of this script (e.g. local debugging) doesn't bail out.
if ! getent group autologin >/dev/null; then
    groupadd -r autologin
fi

if ! id -u liveuser >/dev/null 2>&1; then
    useradd -m \
        -G wheel,autologin,audio,video,optical,storage,games,power \
        -s /usr/bin/bash \
        liveuser
fi

echo "liveuser:liveuser" | chpasswd

# Disable password expiry so xdg-user-dirs-update / sddm autologin don't refuse
# the account because of the default chage policy in the live environment.
chage -d -1 -M -1 liveuser

# 3. Passwordless sudo for the wheel group (in addition to the explicit
#    /etc/sudoers.d/10-liveuser drop-in shipped by the overlay).
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# 4. Services required at boot. `systemctl enable` is idempotent.
systemctl enable sshd.service
systemctl enable NetworkManager.service
systemctl enable avahi-daemon.service
systemctl enable bluetooth.service

# 5. Populate XDG user dirs (Documents, Downloads, ...) for liveuser.
runuser -u liveuser -- xdg-user-dirs-update
