# shellcheck shell=sh
# Arch Gaming OS — VM graphics workaround
#
# When running inside a virtual machine, hardware-accelerated rendering is
# usually broken or unstable for Wayland compositors. Force software GL and
# disable hardware cursors so kitty, Hyprland, etc. start reliably.
#
# On bare metal this file does nothing, so AMD HW acceleration stays enabled.

if command -v systemd-detect-virt >/dev/null 2>&1; then
    case "$(systemd-detect-virt 2>/dev/null)" in
        vmware|oracle|qemu|kvm|microsoft)
            export LIBGL_ALWAYS_SOFTWARE=1
            export WLR_NO_HARDWARE_CURSORS=1
            ;;
    esac
fi
