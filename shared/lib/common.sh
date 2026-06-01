#!/usr/bin/env bash
# shared/lib/common.sh — common bootstrap utilities for debian-slim-rescue
#
# Sourced by minbian/main.sh and minidebian/main.sh.
# Provides: arch detection, RAM detection, logging, apt helpers.

set -uo pipefail

# ── Logging ───────────────────────────────────────────────────────────────────

DSR_RED='\033[0;31m'; DSR_GRN='\033[0;32m'; DSR_YLW='\033[0;33m'
DSR_BLU='\033[0;34m'; DSR_RST='\033[0m'; DSR_BLD='\033[1m'

dsr_info()  { echo -e "${DSR_BLU}[dsr]${DSR_RST} $*"; }
dsr_ok()    { echo -e "${DSR_GRN}[dsr]${DSR_RST} $*"; }
dsr_warn()  { echo -e "${DSR_YLW}[dsr]${DSR_RST} $*" >&2; }
dsr_error() { echo -e "${DSR_RED}[dsr] ERROR:${DSR_RST} $*" >&2; }
dsr_die()   { dsr_error "$*"; exit 1; }

dsr_banner() {
  echo -e "${DSR_BLD}"
  echo "  ┌─────────────────────────────────────────┐"
  echo "  │         debian-slim-rescue (dsr)         │"
  echo "  │  slim setup · rescue initramfs · ramboot │"
  echo "  └─────────────────────────────────────────┘"
  echo -e "${DSR_RST}"
}

# ── Architecture detection ────────────────────────────────────────────────────

# Returns: amd64 | i386 | arm64 | armhf | riscv64 | unknown
dsr_detect_arch() {
  local machine
  machine=$(uname -m)
  case "$machine" in
    x86_64)          echo "amd64" ;;
    i686|i386)       echo "i386"  ;;
    aarch64)         echo "arm64" ;;
    armv7l|armv6l)   echo "armhf" ;;
    riscv64)         echo "riscv64" ;;
    *)               echo "unknown" ;;
  esac
}

# Returns the GNU triple for the current arch (used by minidebian)
dsr_arch_triple() {
  local arch="${1:-$(dsr_detect_arch)}"
  case "$arch" in
    amd64)   echo "x86_64-linux-gnu"    ;;
    i386)    echo "i386-linux-gnu"      ;;
    arm64)   echo "aarch64-linux-gnu"   ;;
    armhf)   echo "arm-linux-gnueabihf" ;;
    riscv64) echo "riscv64-linux-gnu"   ;;
    *)       echo "unknown-linux-gnu"   ;;
  esac
}

# ── RAM detection ─────────────────────────────────────────────────────────────

# Returns total RAM in MiB
dsr_total_ram_mib() {
  awk '/MemTotal/ { printf "%d", $2/1024 }' /proc/meminfo
}

# Returns available RAM in MiB
dsr_avail_ram_mib() {
  awk '/MemAvailable/ { printf "%d", $2/1024 }' /proc/meminfo
}

# ── Apt helpers ───────────────────────────────────────────────────────────────

dsr_apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

dsr_apt_update() {
  DEBIAN_FRONTEND=noninteractive apt-get update -qq
}

dsr_apt_purge() {
  DEBIAN_FRONTEND=noninteractive apt-get purge -y "$@"
  apt-get autoremove -y --purge
}

# ── Privilege check ───────────────────────────────────────────────────────────

dsr_require_root() {
  [[ "$(id -u)" -eq 0 ]] || dsr_die "This command must be run as root."
}

dsr_require_sudo() {
  groups | grep -qw sudo || dsr_die "Your user must be in the sudo group."
}

# ── Distro detection ──────────────────────────────────────────────────────────

# Returns: debian | ubuntu | raspbian | unknown
dsr_detect_distro() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    case "${ID:-}" in
      debian)   echo "debian"   ;;
      ubuntu)   echo "ubuntu"   ;;
      raspbian) echo "raspbian" ;;
      *)        echo "${ID:-unknown}" ;;
    esac
  else
    echo "unknown"
  fi
}

# Returns Debian codename (bookworm, bullseye, etc.)
dsr_debian_codename() {
  if command -v lsb_release &>/dev/null; then
    lsb_release -cs
  elif [[ -f /etc/debian_version ]]; then
    cat /etc/debian_version
  else
    echo "unknown"
  fi
}
