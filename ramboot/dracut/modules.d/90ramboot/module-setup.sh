#!/usr/bin/bash
# ramboot dracut module — distro-agnostic RAM-root via zram
#
# Works on any distro using dracut (Debian, Fedora, openSUSE, Arch, etc.)
# and any architecture supported by the kernel's zram driver.
#
# Ported from arcmags/ramroot (Arch mkinitcpio hook) to dracut.
# Original: https://github.com/arcmags/ramroot
# License: GPL-3.0

check() {
    # Only include if explicitly requested
    return 255
}

depends() {
    echo "fs-lib"
}

install() {
    inst_multiple \
        zramctl \
        mkfs.ext4 \
        cp \
        dd \
        awk \
        grep \
        sleep \
        printf

    inst_hook initqueue/settled 90 "$moddir/ramboot.sh"
    inst_hook cleanup 10 "$moddir/ramboot-cleanup.sh"

    inst_simple "$moddir/ramboot-lib.sh" /lib/ramboot-lib.sh
    inst_simple /etc/ramboot.conf 2>/dev/null || \
        inst_simple "$moddir/ramboot.conf.default" /etc/ramboot.conf

    dracut_need_initqueue
}

installkernel() {
    instmods zram ext4 lzo lz4 zstd
}
