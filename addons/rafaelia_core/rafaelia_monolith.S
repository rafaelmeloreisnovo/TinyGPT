// rafaelia_monolith.S – AArch64 Bare-Metal (com fallback)
// Compilar com: clang --target=aarch64-elf -c -o rafaelia.o rafaelia_monolith.S
// Linkar: ld.lld -T linker.ld -o rafaelia.elf rafaelia.o
// Flat:   llvm-objcopy -O binary rafaelia.elf rafaelia.bin

    .arch armv8-a
    .cpu cortex-a53
    .section .text
    .globl _start
    .type _start, %function

_start:
    // Setup stack
    movz x0, #0x4100, lsl #16
    mov  sp, x0

    // Detectar capacidades
    bl   detect_hw
    mov  x19, x0                 // salva flags

    // Executar NEON mix (sempre seguro)
    adr  x0, memory_pool
    movz x1, #0x1000
    bl   neon_ergodic_mix_arm64

    // Calcular CRC32 (usando hardware ou software)
    adr  x0, memory_pool
    movz x1, #0x1000
    tbz  x19, #0, 1f            // se CRC32 não disponível, pula para fallback
    bl   crc32_hw_arm64
    b     2f
1:  bl    crc32_sw_arm64
2:  mov  x20, x0

    // Executar 7D
    adr  x0, mem_7d
    movz x1, #0x800
    movz x2, #0x100
    bl   rafaelia_7d

    // Escrever mensagem e sair
    movz x0, #1
    adr  x1, msg_done
    movz x2, #24
    movz x8, #64
    svc  #0

    movz x0, #0
    movz x8, #93
    svc  #0

// ------------------------------------------------------------
// Detecção de Hardware (retorna flags em x0: bit0=CRC32)
// ------------------------------------------------------------
detect_hw:
    mrs  x1, ID_AA64ISAR0_EL1
    ubfx x2, x1, #16, #4         // campo CRC32
    cmp  x2, #0
    cinc x0, xzr, ne
    ret

// ------------------------------------------------------------
// NEON Ergodic Mix (seguro, não usa extensões opcionais)
// ------------------------------------------------------------
neon_ergodic_mix_arm64:
    stp  x29, x30, [sp, #-16]!
    movz x5, #0x3f9e, lsl #16
    movk x5, #0x0419
    fmov s0, w5
    movz x5, #0x3fb5, lsl #16
    movk x5, #0x04f3
    fmov s1, w5
    dup  v2.2d, v0.d[0]
    dup  v3.2d, v1.d[0]
    mov  x2, x0
    mov  x4, x1

1:  cmp  x4, #32
    b.lt 2f
    ldr  q0, [x2]
    ldr  q1, [x2, #16]
    fmul v4.2d, v0.2d, v2.2d
    trn1 v5.2d, v0.2d, v1.2d
    trn2 v6.2d, v0.2d, v1.2d
    eor  v7.16b, v5.16b, v6.16b
    fmul v8.2d, v4.2d, v3.2d
    fadd v9.2d, v7.2d, v8.2d
    str  q9, [x2]
    str  q4, [x2, #16]
    add  x2, x2, #32
    sub  x4, x4, #32
    b    1b

2:  ldp  x29, x30, [sp], #16
    ret

// ------------------------------------------------------------
// CRC32 por hardware (SOMENTE SE SUPORTADO)
// ------------------------------------------------------------
crc32_hw_arm64:
    movz w2, #0
    mov  x3, x1
1:  ldr  w4, [x0], #4
    crc32w w2, w2, w4
    subs x3, x3, #4
    b.ne 1b
    mov  w0, w2
    ret

// ------------------------------------------------------------
// CRC32 por software (fallback universal)
// ------------------------------------------------------------
crc32_sw_arm64:
    movz w2, #0xffff
    movk w2, #0xffff, lsl #16   // crc inicial = 0xffffffff
    mov  x3, x1
    movz w5, #0x04c1, lsl #16
    movk w5, #0x1db7            // polinômio 0x04C11DB7
    mov  w6, #8

1:  ldrb w4, [x0], #1
    eor  w2, w2, w4
    mov  w7, w6
2:  tbnz w2, #0, 3f
    lsr  w2, w2, #1
    b     4f
3:  lsr  w2, w2, #1
    eor  w2, w2, w5
4:  subs w7, w7, #1
    b.ne 2b
    subs x3, x3, #1
    b.ne 1b
    mvn  w0, w2                // complemento final
    ret

// ------------------------------------------------------------
// Rafaelia 7D Toroidal
// ------------------------------------------------------------
rafaelia_7d:
    stp  x29, x30, [sp, #-16]!
    movz x5, #0x3fb5, lsl #16
    movk x5, #0x04f3
    fmov s0, w5
    dup  v14.2d, v0.d[0]
    mov  x5, x0
    mov  x6, x1
    mov  x7, x2
    mov  x8, x2

1:  cbz  x7, 2f
    ldr  q0, [x5], #16
    ldr  q1, [x5]
    sub  x5, x5, #16
    ldr  q2, [x6], #16
    ldr  q3, [x6]
    sub  x6, x6, #16

    fsub v4.2d, v0.2d, v2.2d
    fsub v5.2d, v1.2d, v3.2d
    fmul v6.2d, v4.2d, v14.2d
    fmul v7.2d, v5.2d, v14.2d
    trn1 v8.2d, v6.2d, v7.2d
    trn2 v9.2d, v6.2d, v7.2d
    fadd v0.2d, v0.2d, v8.2d
    fadd v1.2d, v1.2d, v9.2d

    str  q0, [x5], #16
    str  q1, [x5]
    sub  x5, x5, #16

    subs x7, x7, #1
    b.ne 1b

2:  ldp  x29, x30, [sp], #16
    ret

    .section .rodata
    .balign 4
msg_done:
    .ascii "[RAFAELIA_MONOLITH] OK\n"

    .section .bss
    .balign 16
memory_pool:
    .space 0x1000
mem_7d:
    .space 0x1000
