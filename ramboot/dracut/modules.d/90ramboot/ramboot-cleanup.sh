#!/bin/sh
# ramboot-cleanup.sh — dracut cleanup hook
# Releases the original disk root mount after root has been copied to zram.

. /lib/ramboot-lib.sh

[ -f /run/ramboot-device ] || return 0

rb_info "ramboot: releasing disk root mount"
# The real root is now zram — unmount disk root if still mounted
umount /run/ramboot-src 2>/dev/null || true
