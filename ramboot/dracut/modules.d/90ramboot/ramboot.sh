#!/bin/sh
# ramboot.sh — dracut initqueue/settled hook
#
# Runs during early boot after devices are settled. Checks RAM availability,
# prompts the user, copies root to zram, and redirects the root mount.

. /lib/ramboot-lib.sh
. /etc/ramboot.conf

# Defaults for config values
: "${RAMBOOT_ENABLE:=auto}"
: "${RAMBOOT_DEFAULT:=n}"
: "${RAMBOOT_TIMEOUT:=8}"
: "${RAMBOOT_RAM_MIN:=750}"
: "${RAMBOOT_RAM_PREF:=4000}"
: "${RAMBOOT_ZRAM_SIZE:=0}"
: "${RAMBOOT_ALGO:=lz4}"

# Skip if explicitly disabled
[ "$RAMBOOT_ENABLE" = "no" ] && return 0

# Check available RAM
avail=$(rb_avail_ram_mib)
total=$(rb_total_ram_mib)

rb_info "RAM: ${avail} MiB available / ${total} MiB total"

if [ "$avail" -lt "$RAMBOOT_RAM_MIN" ]; then
    rb_warn "Insufficient RAM for ramboot (${avail} MiB < ${RAMBOOT_RAM_MIN} MiB minimum)"
    return 0
fi

# Determine zram size: explicit config, or half of available RAM
if [ "$RAMBOOT_ZRAM_SIZE" -gt 0 ] 2>/dev/null; then
    zram_size="$RAMBOOT_ZRAM_SIZE"
else
    zram_size=$(( avail / 2 ))
fi

rb_info "Proposed zram size: ${zram_size} MiB (algo: ${RAMBOOT_ALGO})"

# Skip prompt if auto-enabled and RAM is plentiful
if [ "$RAMBOOT_ENABLE" = "yes" ] || \
   ( [ "$RAMBOOT_ENABLE" = "auto" ] && [ "$avail" -ge "$RAMBOOT_RAM_PREF" ] ); then
    do_ramboot=0
elif [ "$RAMBOOT_ENABLE" = "auto" ]; then
    rb_prompt "Load root filesystem to RAM?" "$RAMBOOT_DEFAULT" "$RAMBOOT_TIMEOUT"
    do_ramboot=$?
else
    return 0
fi

[ "$do_ramboot" -ne 0 ] && { rb_info "Skipping ramboot."; return 0; }

rb_info "Allocating zram device (${zram_size} MiB, ${RAMBOOT_ALGO})..."
zram_dev=$(rb_create_zram "$zram_size" "$RAMBOOT_ALGO") || return 1
rb_info "zram device: $zram_dev"

# Determine root device from dracut's $root variable
root_dev=$(findmnt -n -o SOURCE / 2>/dev/null || echo "$root")

rb_copy_root "$root_dev" "$zram_dev" || {
    rb_error "ramboot failed — booting from disk"
    zramctl --reset "$zram_dev" 2>/dev/null
    return 0
}

# Redirect root to zram
echo "$zram_dev" > /run/ramboot-device
export root="$zram_dev"
rootok=1

rb_info "ramboot active — root is now in RAM"
