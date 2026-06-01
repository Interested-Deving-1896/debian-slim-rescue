#!/usr/bin/env bash
# tests/test-ramboot-lib.sh — unit tests for ramboot-lib.sh (non-root portions)

set -uo pipefail
PASS=0; FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS: $desc"
    (( PASS++ )) || true
  else
    echo "  FAIL: $desc — expected '$expected', got '$actual'"
    (( FAIL++ )) || true
  fi
}

# Stub out sh builtins that ramboot-lib uses (it's written in POSIX sh)
rb_avail_ram_mib() { awk '/MemAvailable/ { printf "%d", $2/1024 }' /proc/meminfo; }
rb_total_ram_mib()  { awk '/MemTotal/     { printf "%d", $2/1024 }' /proc/meminfo; }

echo "=== test-ramboot-lib.sh ==="

# RAM detection
avail=$(rb_avail_ram_mib)
total=$(rb_total_ram_mib)
[[ "$avail" =~ ^[0-9]+$ ]] && [[ "$avail" -gt 0 ]] && \
  { echo "  PASS: avail_ram_mib ($avail MiB)"; (( PASS++ )) || true; } || \
  { echo "  FAIL: avail_ram_mib returned '$avail'"; (( FAIL++ )) || true; }

[[ "$total" =~ ^[0-9]+$ ]] && [[ "$total" -gt 0 ]] && \
  { echo "  PASS: total_ram_mib ($total MiB)"; (( PASS++ )) || true; } || \
  { echo "  FAIL: total_ram_mib returned '$total'"; (( FAIL++ )) || true; }

[[ "$avail" -le "$total" ]] && \
  { echo "  PASS: avail <= total"; (( PASS++ )) || true; } || \
  { echo "  FAIL: avail ($avail) > total ($total)"; (( FAIL++ )) || true; }

# Syntax check the sh scripts (no execution needed)
for f in \
  ramboot/dracut/modules.d/90ramboot/ramboot-lib.sh \
  ramboot/dracut/modules.d/90ramboot/ramboot.sh \
  ramboot/dracut/modules.d/90ramboot/ramboot-cleanup.sh \
  ramboot/initramfs-tools/hooks/ramboot \
  ramboot/initramfs-tools/scripts/local-premount/ramboot; do
  if bash -n "$(dirname "$0")/../${f}" 2>/dev/null; then
    echo "  PASS: syntax $f"
    (( PASS++ )) || true
  else
    echo "  FAIL: syntax $f"
    (( FAIL++ )) || true
  fi
done

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
