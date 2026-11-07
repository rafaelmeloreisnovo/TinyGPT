#!/bin/sh
# SPDX-License-Identifier: MIT. Host checks use toolchains; target kernel does not.
set -eu
D=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
L=$D/../microinfer
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT HUP INT TERM
for CC in cc clang; do
    command -v "$CC" >/dev/null 2>&1 || { echo "missing compiler $CC" >&2; exit 1; }
    for OPT in 0 2 s; do
        "$CC" -std=c11 -O"$OPT" -Wall -Wextra -Werror -pedantic \
            -fno-builtin -I"$D" "$D/raf_decoder_q8.c" \
            "$L/raf_microinfer.c" "$D/tests/test.c" -o "$T/host-$CC-$OPT"
        "$T/host-$CC-$OPT"
    done
done
clang -std=c11 -O1 -g -Wall -Wextra -Werror -fno-builtin \
    -fsanitize=address,undefined -fno-omit-frame-pointer \
    "$D/raf_decoder_q8.c" "$L/raf_microinfer.c" "$D/tests/test.c" -o "$T/sanitized"
"$T/sanitized"
for TARGET in x86_64-unknown-none i386-unknown-none armv7-none-eabi \
              aarch64-none-elf riscv32-unknown-elf riscv64-unknown-elf; do
    for SRC in "$D/raf_decoder_q8.c" "$L/raf_microinfer.c"; do
        B=$(basename "$SRC" .c)
        clang --target="$TARGET" -std=c11 -Os -Wall -Wextra -Werror \
            -ffreestanding -fno-builtin -fno-stack-protector -fno-pic -nostdinc \
            -c "$SRC" -o "$T/$TARGET-$B.o"
        nm -u "$T/$TARGET-$B.o" > "$T/undefined.txt" || exit 1
        if [ "$B" = raf_decoder_q8 ]; then
            UNDEF=$(awk '$NF != "raf_micro_q8_matvec" {print}' "$T/undefined.txt")
        else
            UNDEF=$(cat "$T/undefined.txt")
        fi
        if [ -n "$UNDEF" ]; then
            echo "Unexpected undefined symbols for $TARGET/$B: $UNDEF" >&2
            exit 1
        fi
    done
done
for TARGET in armv7-none-eabi aarch64-none-elf; do
    clang --target="$TARGET" -std=c11 -Os -Wall -Wextra -Werror \
        -ffreestanding -fno-builtin -fno-stack-protector -fno-pic -nostdinc \
        -nostdlib -fuse-ld=lld -Wl,--no-undefined -Wl,-T,"$D/tests/linker.ld" \
        "$D/raf_decoder_q8.c" "$L/raf_microinfer.c" "$D/tests/smoke.c" \
        -o "$T/$TARGET.elf"
    UNDEF=$(nm -u "$T/$TARGET.elf")
    if [ -n "$UNDEF" ]; then
        echo "ELF unresolved symbols for $TARGET" >&2; exit 1
    fi
    readelf -l "$T/$TARGET.elf" > "$T/program-headers.txt" || exit 1
    if grep -q INTERP "$T/program-headers.txt"; then
        echo "Dynamic loader in $TARGET" >&2; exit 1
    fi
done
echo 'PASS_SCOPED: host GCC/Clang x O0/O2/Os, ASan+UBSan, six ISA objects, ARM32/ARM64 ELF LINK_ONLY'
