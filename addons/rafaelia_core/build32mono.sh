#!/bin/sh
# Build script para Rafaelia Monolith – Bare-metal ARM64
# Zero overhead, sem libc, sem variáveis desnecessárias.

set -e

echo ">>> Montando com Clang (AArch64)..."
clang --target=aarch64-elf -c -o rafaelia.o rafaelia_monolith32.S

echo ">>> Criando linker script..."
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

echo ">>> Linkando com LLD..."
ld.lld -T linker.ld -o rafaelia.elf rafaelia.o

echo ">>> Gerando binário flat..."
llvm-objcopy -O binary rafaelia.elf rafaelia.bin

echo ">>> Binário final: rafaelia.bin"
echo ">>> Tamanho: $(stat -c%s rafaelia.bin) bytes"

# Teste rápido com QEMU (se instalado)
if command -v qemu-system-aarch64 >/dev/null; then
    echo ">>> Executando no QEMU..."
    qemu-system-aarch64 -M virt -cpu cortex-a57 -kernel rafaelia.bin -nographic
else
    echo ">>> QEMU não encontrado. Execute manualmente:"
    echo "    qemu-system-aarch64 -M virt -cpu cortex-a57 -kernel rafaelia.bin -nographic"
fi
