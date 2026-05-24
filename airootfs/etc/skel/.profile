#!/usr/bin/env bash
# ~/.profile — sourced by login shells (kept for non-systemd contexts).
#
# The canonical VM-detection happens in /etc/profile.d/vm-detect.sh, which is
# picked up by /etc/profile and therefore propagates to the Wayland session.
# This block is a defensive fallback for the rare case /etc/profile.d isn't
# sourced (e.g. plain `bash -l` over SSH on misconfigured systems).
if command -v systemd-detect-virt >/dev/null 2>&1; then
    case "$(systemd-detect-virt 2>/dev/null)" in
        vmware|oracle|qemu|kvm|microsoft)
            export LIBGL_ALWAYS_SOFTWARE=1
            export WLR_NO_HARDWARE_CURSORS=1
            ;;
    esac
fi
