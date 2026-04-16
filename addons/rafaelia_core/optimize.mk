
============================================================================

QEMU OPTIMIZATION MAKEFILE - ZERO-OVERHEAD BUILD

============================================================================

.PHONY: all clean optimize build-arm64 build-x86_64 build-riscv

Optimization flags

OPTIMIZE_FLAGS := -O3 -march=native -flto -ffunction-sections -fdata-sections
OPTIMIZE_FLAGS += -fno-builtin -fno-exceptions -fno-rtti -fno-asynchronous-unwind-tables
OPTIMIZE_FLAGS += -static-libgcc -static-libstdc++

Architecture-specific flags

ARM64_FLAGS := -march=armv8-a+crc -mtune=native
X86_64_FLAGS := -march=haswell -mtune=native -mavx2
RISCV_FLAGS := -march=rv64imac -mtune=native

Build targets

TARGETS := qemu-system-arm64 qemu-system-x86_64 qemu-system-riscv64

all: $(TARGETS)

qemu-system-arm64:
./configure --target-list=aarch64-softmmu 
		--extra-cflags="$(OPTIMIZE_FLAGS) $(ARM64_FLAGS)" 
		--extra-ldflags="-Wl,--gc-sections" 
		--disable-docs 
		--disable-debug-info 
		--enable-lto
make -j$(nproc)

qemu-system-x86_64:
./configure --target-list=x86_64-softmmu 
		--extra-cflags="$(OPTIMIZE_FLAGS) $(X86_64_FLAGS)" 
		--extra-ldflags="-Wl,--gc-sections" 
		--disable-docs 
		--disable-debug-info 
		--enable-lto
make -j$(nproc)

qemu-system-riscv64:
./configure --target-list=riscv64-softmmu 
		--extra-cflags="$(OPTIMIZE_FLAGS) $(RISCV_FLAGS)" 
		--extra-ldflags="-Wl,--gc-sections" 
		--disable-docs 
		--disable-debug-info 
		--enable-lto
make -j$(nproc)

optimize:
strip --strip-all $(TARGETS)
upx -9 $(TARGETS) || true

clean:
make distclean
