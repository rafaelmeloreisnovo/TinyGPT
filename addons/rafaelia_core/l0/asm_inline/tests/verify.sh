#!/bin/sh
# SPDX-License-Identifier: MIT
# Strict ISA/ELF gate. Arm objects are NOT executed on host; no hardware PASS.
set -eu
D=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
L="$D/../microinfer"
DEC="$D/../decoder_q8"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT HUP INT TERM
for TOOL in clang nm readelf grep; do
    command -v "$TOOL" >/dev/null 2>&1 || { echo "Missing host tool: $TOOL" >&2; exit 1; }
done
DISASM=
for TOOL in llvm-objdump llvm-objdump-19 llvm-objdump-18 llvm-objdump-17 llvm-objdump-16; do
    if command -v "$TOOL" >/dev/null 2>&1; then DISASM=$TOOL; break; fi
done
[ -n "$DISASM" ] || { echo 'llvm-objdump required to verify actual inline ISA' >&2; exit 1; }

# No implicit C fallback on architectures the backend does not support.
if clang --target=x86_64-unknown-none -Os -nostdinc -c \
    "$D/raf_q8_inline_asm.c" -o "$T/invalid.o" >"$T/invalid.log" 2>&1; then
    echo 'Invalid host ISA unexpectedly compiled' >&2; exit 1
fi

i=0
for MODE in a32 thumb2 a64; do
    case "$MODE" in
      a32) TARGET=armv7a-none-eabi; ABI='-march=armv7-a -marm'; REQUIRED=mla;;
      thumb2) TARGET=armv7a-none-eabi; ABI='-march=armv7-a -mthumb'; REQUIRED=mla;;
      a64) TARGET=aarch64-none-elf; ABI='-march=armv8-a'; REQUIRED=madd;;
    esac
    for OPT in 0 2 s; do
        # shellcheck disable=SC2086 # ABI intentionally expands into two flags
        clang --target="$TARGET" $ABI -std=c11 -O"$OPT" \
          -Wall -Wextra -Werror -pedantic -ffreestanding \
          -fno-builtin -fno-stack-protector -fno-pic -nostdinc \
          -c "$D/raf_q8_inline_asm.c" -o "$T/$MODE-$OPT.o"
        [ -z "$(nm -u "$T/$MODE-$OPT.o")" ] || {
            echo "Unresolved runtime symbol: $MODE O$OPT" >&2; exit 1;
        }
        "$DISASM" -d "$T/$MODE-$OPT.o" > "$T/$MODE-$OPT.dis"
        [ "$(grep -c 'ldrsb' "$T/$MODE-$OPT.dis")" -ge 2 ] || {
            echo "Missing signed-byte loads: $MODE O$OPT" >&2; exit 1;
        }
        grep -q "$REQUIRED" "$T/$MODE-$OPT.dis" || {
            echo "Missing multiply-add $REQUIRED: $MODE O$OPT" >&2; exit 1;
        }
        i=$((i + 1))
    done
    # Compiling the full decoder with the alternative backend proves ABI fit.
    # synthetic linker map is not an actual RAM, boot, MMU, stack or board gate.
    # shellcheck disable=SC2086
    clang --target="$TARGET" $ABI -std=c11 -Os -Wall -Wextra -Werror \
      -ffreestanding -fno-builtin -fno-stack-protector -fno-pic -nostdinc \
      -nostdlib -fuse-ld=lld -Wl,--no-undefined \
      -Wl,-T,"$DEC/tests/linker.ld" \
      "$D/raf_q8_inline_asm.c" "$DEC/raf_decoder_q8.c" "$DEC/tests/smoke.c" \
      -o "$T/$MODE.elf"
    [ -z "$(nm -u "$T/$MODE.elf")" ] || {
        echo "Unresolved ELF symbols: $MODE" >&2; exit 1;
    }
    readelf -l "$T/$MODE.elf" > "$T/$MODE.phdrs"
    readelf -S "$T/$MODE.elf" > "$T/$MODE.sections"
    if grep -Eq 'INTERP|DYNAMIC' "$T/$MODE.phdrs" ||
       grep -Eq '\.interp|\.dynamic|\.plt' "$T/$MODE.sections"; then
        echo "Runtime loader dependency detected: $MODE" >&2; exit 1
    fi
    "$DISASM" -d "$T/$MODE.elf" > "$T/$MODE.elf.dis"
    grep -q "$REQUIRED" "$T/$MODE.elf.dis" || {
        echo "No inline multiply-add in linked ELF: $MODE" >&2; exit 1;
    }
done

echo "PASS_SCOPED: $i freestanding ARM objects (A32/Thumb2/A64 x O0/O2/Os), 3 ELF LINK_ONLY, ISA and import gates"
