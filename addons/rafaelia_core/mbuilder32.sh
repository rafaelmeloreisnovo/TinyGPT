#!/bin/sh
set -e
clang --target=aarch64-elf -c -o rafaelia.o rafaelia_monolith32n.S
cat > linker.ld << 'EOF'
OUTPUT_ARCH(aarch64)
ENTRY(_start)
SECTIONS
{
    . = 0x40000000;
    .text : { *(.text*) }
    .rodata : { *(.rodata*) }
    .data : { *(.data*) }
    .bss : { *(.bss*) }
    . = ALIGN(16);
    _end = .;
}
EOF
ld.lld -T linker.ld -o rafaelia.elf rafaelia.o
llvm-objcopy -O binary rafaelia.elf rafaelia.bin
echo "✅ rafaelia.bin gerado com sucesso."
