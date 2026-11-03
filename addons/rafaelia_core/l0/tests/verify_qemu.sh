#!/bin/sh
# Scoped AArch64 ABI/behavior smoke under qemu-user; never a physical receipt.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../../.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
command -v qemu-aarch64 >/dev/null 2>&1 || { echo 'qemu-aarch64 unavailable: NOT_RUN' >&2; exit 127; }
command -v ld.lld >/dev/null 2>&1 || { echo 'ld.lld unavailable: NOT_RUN' >&2; exit 127; }
clang --target=aarch64-linux-gnu -c \
  "$ROOT/addons/rafaelia_core/asm/arm64/vectra_pulse.S" -o "$TMP/vectra.o"
clang --target=aarch64-linux-gnu -c \
  "$ROOT/addons/rafaelia_core/l0/tests/vectra_inject_smoke.S" -o "$TMP/smoke.o"
ld.lld -m aarch64elf -static -nostdlib -e _start \
  "$TMP/smoke.o" "$TMP/vectra.o" -o "$TMP/vectra-smoke.elf"
qemu-aarch64 "$TMP/vectra-smoke.elf"
echo 'RAFAELIA vectra AArch64 QEMU: NULL guard + phase modulo42 PASS (EMULATED)'
