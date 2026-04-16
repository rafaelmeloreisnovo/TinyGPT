#!/bin/bash
ARCH=$(uname -m)
echo "Detected Arch: $ARCH"

if [[ "$ARCH" == "aarch64" ]]; then
    echo "🔨 Building for 64-bit..."
    clang -O3 -c native/src/asm/02_arm64v8_neon_core.S -o core.o
    clang main_test.c core.o -o rafaelia_runner -DARCH64
else
    echo "🔨 Building for 32-bit..."
    # No 32-bit usamos o arquivo ARMv7 e a função correta
    clang -O3 -c native/src/asm/02_arm32_neon_core.S -o core.o
    clang main_test.c core.o -o rafaelia_runner -DARCH32
fi
