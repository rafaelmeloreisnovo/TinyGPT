#!/bin/sh
# SPDX-License-Identifier: MIT; run: sh addons/rafaelia_core/l0/microinfer/tests/verify.sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
for CC in cc clang; do
    command -v "$CC" >/dev/null 2>&1 || { echo "missing $CC" >&2; exit 1; }
    for UNROLL in 0 1; do
        "$CC" -std=c11 -O2 -Wall -Wextra -Werror -pedantic -fno-builtin \
            -DRAF_MICRO_UNROLL4="$UNROLL" -I"$ROOT" \
            "$ROOT/raf_microinfer.c" "$ROOT/tests/test.c" -o "$TMP/$CC-$UNROLL"
        "$TMP/$CC-$UNROLL"
    done
done
command -v nm >/dev/null 2>&1 || exit 1
for TARGET in x86_64-unknown-none i386-unknown-none armv7-none-eabi \
              aarch64-none-elf riscv32-unknown-elf riscv64-unknown-elf; do
    clang --target="$TARGET" -std=c11 -Os -Wall -Wextra -Werror \
        -ffreestanding -fno-builtin -fno-stack-protector -nostdinc \
        -I"$ROOT" -c "$ROOT/raf_microinfer.c" -o "$TMP/$TARGET.o"
    if [ -n "$(nm -u "$TMP/$TARGET.o")" ]; then
        echo "undefined symbols: $TARGET" >&2
        nm -u "$TMP/$TARGET.o" >&2
        exit 1
    fi
done
for TARGET in armv7-none-eabi aarch64-none-elf; do
    clang --target="$TARGET" -std=c11 -Os -Wall -Wextra -Werror \
        -ffreestanding -fno-builtin -fno-stack-protector -nostdinc \
        -DRAF_MICRO_ARM_ASM=1 -DRAF_MICRO_UNROLL4=1 \
        -I"$ROOT" -c "$ROOT/raf_microinfer.c" -o "$TMP/$TARGET-asm.o"
    if [ -n "$(nm -u "$TMP/$TARGET-asm.o")" ]; then
        echo "undefined ASM symbols: $TARGET" >&2
        exit 1
    fi
done
echo "PASS_SCOPED: C11 host parity/negatives + six ISA objects + ARMv7/AArch64 ASM codegen"
