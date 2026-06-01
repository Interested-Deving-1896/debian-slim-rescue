#!/usr/bin/env bash
# tests/test-common.sh — unit tests for shared/lib/common.sh

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

# Source without running anything
source "$(dirname "$0")/../shared/lib/common.sh"

echo "=== test-common.sh ==="

# dsr_detect_arch
case "$(uname -m)" in
  x86_64)  assert_eq "detect_arch x86_64" "amd64"  "$(dsr_detect_arch)" ;;
  aarch64) assert_eq "detect_arch arm64"  "arm64"  "$(dsr_detect_arch)" ;;
  *)       echo "  SKIP: detect_arch (unknown machine $(uname -m))" ;;
esac

# dsr_arch_triple
assert_eq "arch_triple amd64"  "x86_64-linux-gnu"    "$(dsr_arch_triple amd64)"
assert_eq "arch_triple i386"   "i386-linux-gnu"       "$(dsr_arch_triple i386)"
assert_eq "arch_triple arm64"  "aarch64-linux-gnu"    "$(dsr_arch_triple arm64)"
assert_eq "arch_triple armhf"  "arm-linux-gnueabihf"  "$(dsr_arch_triple armhf)"

# dsr_total_ram_mib — just check it's a positive integer
ram=$(dsr_total_ram_mib)
[[ "$ram" =~ ^[0-9]+$ ]] && [[ "$ram" -gt 0 ]] && \
  { echo "  PASS: total_ram_mib ($ram MiB)"; (( PASS++ )) || true; } || \
  { echo "  FAIL: total_ram_mib returned '$ram'"; (( FAIL++ )) || true; }

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
