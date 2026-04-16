#!/bin/bash

============================================================================

METAL/VULKAN BUILDER - GPU ACCELERATION

============================================================================

set -euo pipefail

echo "[*] Building llama with GPU acceleration..."

Detect GPU capabilities

GPU_SUPPORT=""

if command -v metal-clang &> /dev/null; then
echo "[+] Metal detected (macOS/iOS)"
GPU_SUPPORT="-DUSE_METAL=ON"
fi

if pkg-config --exists vulkan 2>/dev/null; then
echo "[+] Vulkan detected"
GPU_SUPPORT="$GPU_SUPPORT -DUSE_VULKAN=ON"
fi

if command -v nvcc &> /dev/null; then
echo "[+] CUDA detected (NVIDIA)"
CUDA_PATH=$(which nvcc | xargs dirname | xargs dirname)
GPU_SUPPORT="$GPU_SUPPORT -DUSE_CUDA=ON -DCUDA_PATH=$CUDA_PATH"
fi

Optimization flags

export CFLAGS="-O3 -march=native -flto -fno-builtin"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--gc-sections"

Build with CMake

mkdir -p build
cd build

cmake .. 
    -DCMAKE_BUILD_TYPE=Release 
    -DCMAKE_C_FLAGS_RELEASE="$CFLAGS" 
    -DCMAKE_CXX_FLAGS_RELEASE="$CXXFLAGS" 
    $GPU_SUPPORT 
    -DBUILD_SHARED_LIBS=OFF

make -j$(nproc)

echo "[✓] Build complete"
echo "[*] Binary: ./bin/llama-cli"
