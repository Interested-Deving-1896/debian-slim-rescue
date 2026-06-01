#!/bin/sh
# ramboot-lib.sh — shared functions for the ramboot dracut module
#
# Sourced by ramboot.sh (initqueue hook) and ramboot-cleanup.sh.
# Written in POSIX sh — no bashisms, runs in early initramfs environment.

# ── Logging ───────────────────────────────────────────────────────────────────

rb_info()  { printf '\033[1;32m==> \033[1;37m%s\033[0m\n' "$*"; }
rb_warn()  { printf '\033[1;33m==> WARN: \033[1;37m%s\033[0m\n' "$*" >&2; }
rb_error() { printf '\033[1;31m==> FAIL: \033[1;37m%s\033[0m\n' "$*" >&2; }

# ── RAM detection ─────────────────────────────────────────────────────────────

# Returns total RAM in MiB
rb_total_ram_mib() {
    awk '/MemTotal/ { printf "%d", $2/1024 }' /proc/meminfo
}

# Returns available RAM in MiB
rb_avail_ram_mib() {
    awk '/MemAvailable/ { printf "%d", $2/1024 }' /proc/meminfo
}

# ── zram helpers ──────────────────────────────────────────────────────────────

# Create and format a zram device of the given size (MiB) and compression algo
# Usage: rb_create_zram <size_mib> [algo]
# Returns: zram device path (e.g. /dev/zram0)
rb_create_zram() {
    local size_mib="${1:-1024}"
    local algo="${2:-lz4}"
    local size_bytes=$(( size_mib * 1024 * 1024 ))

    # Load zram module if not already loaded
    modprobe zram 2>/dev/null || true

    local dev
    dev=$(zramctl --find --size "${size_bytes}" --algorithm "${algo}" 2>/dev/null)
    if [ -z "$dev" ]; then
        rb_error "zramctl failed to allocate zram device"
        return 1
    fi

    mkfs.ext4 -q -L ramboot-root "$dev" || {
        rb_error "mkfs.ext4 failed on $dev"
        zramctl --reset "$dev" 2>/dev/null
        return 1
    }

    echo "$dev"
}

# ── Prompt ────────────────────────────────────────────────────────────────────

# Interactive y/n prompt with timeout and default
# Usage: rb_prompt <question> <default_y_or_n> <timeout_sec>
# Returns: 0=yes 1=no
rb_prompt() {
    local question="$1"
    local default="${2:-n}"
    local timeout="${3:-8}"

    local prompt_str
    if [ "$default" = "y" ]; then
        prompt_str="[Y/n]"
    else
        prompt_str="[y/N]"
    fi

    printf '%s %s (auto: %s in %ds): ' "$question" "$prompt_str" "$default" "$timeout"

    local answer=""
    if read -t "$timeout" -r answer 2>/dev/null; then
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    else
        echo ""
        answer="$default"
    fi

    case "$answer" in
        y|yes) return 0 ;;
        n|no)  return 1 ;;
        "")    [ "$default" = "y" ] && return 0 || return 1 ;;
        *)     [ "$default" = "y" ] && return 0 || return 1 ;;
    esac
}

# ── Root copy ─────────────────────────────────────────────────────────────────

# Copy root filesystem to zram device
# Usage: rb_copy_root <src_dev> <zram_dev> <fs_type>
rb_copy_root() {
    local src_dev="$1"
    local zram_dev="$2"
    local fs_type="${3:-ext4}"

    local src_mnt="/run/ramboot-src"
    local dst_mnt="/run/ramboot-dst"
    mkdir -p "$src_mnt" "$dst_mnt"

    mount -t "$fs_type" -o ro "$src_dev" "$src_mnt" || {
        rb_error "Failed to mount source $src_dev"
        return 1
    }
    mount "$zram_dev" "$dst_mnt" || {
        rb_error "Failed to mount zram $zram_dev"
        umount "$src_mnt"
        return 1
    }

    rb_info "Copying root filesystem to zram (this may take a moment)..."
    cp -a "$src_mnt/." "$dst_mnt/" || {
        rb_error "Copy failed"
        umount "$dst_mnt" "$src_mnt"
        return 1
    }

    umount "$dst_mnt" "$src_mnt"
    rmdir "$src_mnt" "$dst_mnt" 2>/dev/null || true
    return 0
}
