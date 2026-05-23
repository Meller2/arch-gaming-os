if [ "$(systemd-detect-virt)" = "vmware" ] || [ "$(systemd-detect-virt)" = "oracle" ] || [ "$(systemd-detect-virt)" = "qemu" ]; then
    export LIBGL_ALWAYS_SOFTWARE=1
    export WLR_NO_HARDWARE_CURSORS=1
fi
