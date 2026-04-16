#!/bin/bash
# ============================================================================
# METAL OPTIMIZATION - Remove CPU bottlenecks
# ============================================================================

set -euo pipefail

echo "[*] Detecting GPU capabilities..."

# Metal (macOS/iOS)
if command -v xcrun &> /dev/null; then
    echo "[+] Metal SDK available"
    METAL_AVAILABLE=1
else
    METAL_AVAILABLE=0
fi

# Vulkan (Linux/Windows/Android)
if pkg-config --exists vulkan 2>/dev/null; then
    echo "[+] Vulkan SDK available"
    VULKAN_AVAILABLE=1
else
    VULKAN_AVAILABLE=0
fi

# CUDA (NVIDIA)
if command -v nvcc &> /dev/null; then
    echo "[+] CUDA Toolkit available"
    CUDA_AVAILABLE=1
    CUDA_PATH=$(which nvcc | xargs dirname | xargs dirname)
else
    CUDA_AVAILABLE=0
fi

# Build with optimal flags
CMAKE_FLAGS="-O3 -march=native -flto"

if [ "$METAL_AVAILABLE" -eq 1 ]; then
    CMAKE_FLAGS="$CMAKE_FLAGS -DUSE_METAL=ON"
    echo "[+] Building with Metal support"
fi

if [ "$VULKAN_AVAILABLE" -eq 1 ]; then
    CMAKE_FLAGS="$CMAKE_FLAGS -DUSE_VULKAN=ON"
    echo "[+] Building with Vulkan support"
fi

if [ "$CUDA_AVAILABLE" -eq 1 ]; then
    CMAKE_FLAGS="$CMAKE_FLAGS -DUSE_CUDA=ON"
    echo "[+] Building with CUDA support"
fi

# Optimize C++ compilation
export CXXFLAGS="-O3 -march=native -flto -fno-exceptions -fno-rtti"
export CFLAGS="-O3 -march=native -flto -fno-builtin"

# Build
mkdir -p build
cd build

cmake .. $CMAKE_FLAGS
make -j$(nproc)

echo "[✓] Optimization complete"
