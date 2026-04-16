
============================================================================

MAKEFILE OTIMIZADO - ZERO OVERHEAD, DEPENDENCY TRACKING

============================================================================

.PHONY: all clean build-arm32 build-arm64 build-x86 build-x86_64
.DELETE_ON_ERROR:

Compiler settings

CC := gcc
CXX := g++
AS := as
LD := ld
AR := ar
RANLIB := ranlib

Flags otimizadas (ZERO OVERHEAD)

CFLAGS := -O3 -march=native -flto -ffunction-sections -fdata-sections
CFLAGS += -fno-builtin -fno-exceptions -fno-rtti -fno-asynchronous-unwind-tables
CFLAGS += -static -nostdlib -nostdinc -fno-common
CFLAGS += -Wall -Werror -Wextra -Wpedantic

ASFLAGS := -march=native -g0

LDFLAGS := -static -nostdlib -gc-sections -s

Diretórios

SRC_DIR := native/src
ASM_DIR := native/src/asm
OUT_DIR := out
ARM32_DIR := $(OUT_DIR)/arm32
ARM64_DIR := $(OUT_DIR)/arm64
X86_DIR := $(OUT_DIR)/x86
X86_64_DIR := $(OUT_DIR)/x86_64

Targets

ARM32_CORE := $(ARM32_DIR)/core.a
ARM64_CORE := $(ARM64_DIR)/core.a
X86_CORE := $(X86_DIR)/core.a
X86_64_CORE := $(X86_64_DIR)/core.a

Sources

C_SOURCES := $(wildcard $(SRC_DIR)/**/.c)
ASM_SOURCES := $(wildcard $(ASM_DIR)/.S)

Objects

ARM32_OBJS := $(patsubst $(SRC_DIR)/%.c, $(ARM32_DIR)/%.o, $(C_SOURCES))
ARM64_OBJS := $(patsubst $(SRC_DIR)/%.c, $(ARM64_DIR)/%.o, $(C_SOURCES))

all: $(ARM32_CORE) $(ARM64_CORE) $(X86_CORE) $(X86_64_CORE)

ARM32 Build

$(ARM32_DIR)/%.o: $(SRC_DIR)/%.c
@mkdir -p $(@D)
arm-linux-gnueabihf-gcc $(CFLAGS) -march=armv7-a -mfpu=neon -c $< -o $@

$(ARM32_CORE): $(ARM32_OBJS)
arm-linux-gnueabihf-ar rcs $@ $^

ARM64 Build

$(ARM64_DIR)/%.o: $(SRC_DIR)/%.c
@mkdir -p $(@D)
aarch64-linux-gnu-gcc $(CFLAGS) -march=armv8-a+crc -c $< -o $@

$(ARM64_CORE): $(ARM64_OBJS)
aarch64-linux-gnu-ar rcs $@ $^

x86 Build

$(X86_DIR)/%.o: $(SRC_DIR)/%.c
@mkdir -p $(@D)
i686-linux-gnu-gcc $(CFLAGS) -march=i686 -msse4.2 -c $< -o $@

$(X86_CORE): $(X86_OBJS)
i686-linux-gnu-ar rcs $@ $^

x86-64 Build

$(X86_64_DIR)/%.o: $(SRC_DIR)/%.c
@mkdir -p $(@D)
x86_64-linux-gnu-gcc $(CFLAGS) -march=haswell -mavx2 -c $< -o $@

$(X86_64_CORE): $(X86_64_OBJS)
x86_64-linux-gnu-ar rcs $@ $^

clean:
rm -rf $(OUT_DIR)

.PRECIOUS: $(ARM32_DIR)/%.o $(ARM64_DIR)/%.o $(X86_DIR)/%.o $(X86_64_DIR)/%.o
