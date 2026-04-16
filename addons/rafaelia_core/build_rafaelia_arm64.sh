#!/bin/bash
set -e

export TARGET="--target=aarch64-linux-android"
export CC="clang $TARGET"
export AR="llvm-ar"
export CFLAGS="-O3 -march=armv8-a+simd -fno-builtin"
BUILD_DIR="build_out"

mkdir -p $BUILD_DIR

echo "[1/2] Compilando Núcleo NEON ARM64..."
$CC $CFLAGS -c native/src/asm/02_arm64v8_neon_core.S -o $BUILD_DIR/core_neon.o

echo "[2/2] Gerando librafaelia.a..."
$AR rcs librafaelia.a $BUILD_DIR/core_neon.o
echo "✅ librafaelia.a (Matriz ARM64) gerada."
