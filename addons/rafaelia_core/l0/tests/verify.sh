#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../../.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
cc -std=c11 -O2 -Wall -Wextra -Werror -pedantic \
    -I"$ROOT/addons/rafaelia_core/l0" \
    "$ROOT/addons/rafaelia_core/l0/tests/raf_l0_gate_test.c" -o "$TMP/host"
"$TMP/host"
for target in x86_64-unknown-none i386-unknown-none armv7-none-eabi \
              aarch64-none-elf riscv32-unknown-elf riscv64-unknown-elf; do
    clang --target="$target" -std=c11 -O2 -Wall -Wextra -Werror \
        -ffreestanding -fno-builtin -fno-stack-protector -nostdinc \
        -I"$ROOT/addons/rafaelia_core/l0" \
        -c "$ROOT/addons/rafaelia_core/l0/tests/raf_l0_gate_test.c" -o "$TMP/$target.o"
    if [ -n "$(nm -u "$TMP/$target.o")" ]; then
        echo "FAIL: undefined symbols in $target" >&2
        nm -u "$TMP/$target.o" >&2
        exit 1
    fi
done
clang --target=aarch64-none-elf -c \
    "$ROOT/addons/rafaelia_core/asm/arm64/vectra_pulse.S" -o "$TMP/vectra.o"
[ -z "$(nm -u "$TMP/vectra.o")" ] || { echo 'FAIL: undefined ASM references' >&2; exit 1; }
echo 'RAFAELIA TinyGPT L0: host adversarial properties + six-target codegen + AArch64 ASM PASS'
