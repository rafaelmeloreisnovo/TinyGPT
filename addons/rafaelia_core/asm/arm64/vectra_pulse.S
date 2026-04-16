// =============================================================================
// RAFAELIA / VECTRA PULSE (AArch64, sem dependências externas)
// Núcleo autoral separado, com estado estático e operação determinística.
// =============================================================================

.text
.align 6

.global vectra_pulse_init
.global vectra_pulse_step
.global vectra_pulse_collapse
.global vectra_pulse_inject
.global vectra_pulse_read

// offsets da estrutura interna
.equ OFF_SEED,      0
.equ OFF_ACC,       8
.equ OFF_PHASE,    16
.equ OFF_COH,      20
.equ OFF_ENT,      24
.equ OFF_FLAGS,    28
.equ STATE_SIZE,   32

// constantes
.equ Q16_HALF,     0x8000
.equ Q16_DELTA_OK, 0x0800
.equ PERIOD_42,    42

// -----------------------------------------------------------------------------
// void vectra_pulse_init(uint64_t seed)
// x0 = seed
// -----------------------------------------------------------------------------
vectra_pulse_init:
    adrp    x9, vectra_state
    add     x9, x9, :lo12:vectra_state

    // seed
    str     x0, [x9, #OFF_SEED]

    // acc = seed ^ const
    movz    x10, #0x1b3
    movk    x10, #0x0100, lsl #16
    movk    x10, #0x0000, lsl #32
    movk    x10, #0x0100, lsl #48
    eor     x10, x10, x0
    str     x10, [x9, #OFF_ACC]

    // phase = 0
    str     wzr, [x9, #OFF_PHASE]

    // coerência / entropia = 0.5 (Q16.16)
    mov     w10, #Q16_HALF
    str     w10, [x9, #OFF_COH]
    str     w10, [x9, #OFF_ENT]

    // flags = 0
    str     wzr, [x9, #OFF_FLAGS]
    ret

// -----------------------------------------------------------------------------
// void vectra_pulse_step(int32_t c_in_q16, int32_t h_in_q16)
// w0 = c_in_q16, w1 = h_in_q16
// EMA: C=(3*C+c_in)>>2 ; H=(3*H+h_in)>>2
// -----------------------------------------------------------------------------
vectra_pulse_step:
    adrp    x9, vectra_state
    add     x9, x9, :lo12:vectra_state

    ldr     w10, [x9, #OFF_COH]
    ldr     w11, [x9, #OFF_ENT]

    // C
    add     w12, w10, w10, lsl #1
    add     w12, w12, w0
    asr     w12, w12, #2

    // H
    add     w13, w11, w11, lsl #1
    add     w13, w13, w1
    asr     w13, w13, #2

    str     w12, [x9, #OFF_COH]
    str     w13, [x9, #OFF_ENT]

    // phase = (phase + 1) mod 42
    ldr     w14, [x9, #OFF_PHASE]
    add     w14, w14, #1
    cmp     w14, #PERIOD_42
    csel    w14, w14, wzr, lt
    str     w14, [x9, #OFF_PHASE]

    // mistura branchless no acumulador (xorshift + rotate)
    ldr     x15, [x9, #OFF_ACC]
    eor     x15, x15, x15, lsl #13
    eor     x15, x15, x15, lsr #7
    eor     x15, x15, x15, lsl #17

    // injeta C/H no acc
    uxtw    x16, w12
    uxtw    x17, w13
    eor     x15, x15, x16
    ror     x15, x15, #11
    add     x15, x15, x17

    str     x15, [x9, #OFF_ACC]
    ret

// -----------------------------------------------------------------------------
// void vectra_pulse_collapse(void)
// Avalia delta=abs(C-H). Se delta <= threshold => flags bit0=1, senão bit1=1.
// -----------------------------------------------------------------------------
vectra_pulse_collapse:
    adrp    x9, vectra_state
    add     x9, x9, :lo12:vectra_state

    ldr     w10, [x9, #OFF_COH]
    ldr     w11, [x9, #OFF_ENT]
    subs    w12, w10, w11
    cneg    w12, w12, mi

    // bit 0 se estado estável, bit 1 se estado exploratório
    mov     w13, #1
    mov     w14, #2
    cmp     w12, #Q16_DELTA_OK
    csel    w15, w13, w14, le
    str     w15, [x9, #OFF_FLAGS]

    // acc ^= (delta << 16) ^ flags
    ldr     x16, [x9, #OFF_ACC]
    uxtw    x17, w12
    lsl     x17, x17, #16
    eor     x16, x16, x17
    uxtw    x17, w15
    eor     x16, x16, x17
    str     x16, [x9, #OFF_ACC]
    ret

// -----------------------------------------------------------------------------
// void vectra_pulse_inject(const uint8_t* data, uint32_t len)
// x0=data, w1=len
// FNV-1a 64-bit no acc interno.
// -----------------------------------------------------------------------------
vectra_pulse_inject:
    cbz     w1, 2f

    adrp    x9, vectra_state
    add     x9, x9, :lo12:vectra_state
    ldr     x10, [x9, #OFF_ACC]

    // prime FNV-1a 64
    movz    x11, #0x01b3
    movk    x11, #0x0000, lsl #16
    movk    x11, #0x0000, lsl #32
    movk    x11, #0x0100, lsl #48

1:
    ldrb    w12, [x0], #1
    eor     x10, x10, x12
    mul     x10, x10, x11
    subs    w1, w1, #1
    b.ne    1b

    str     x10, [x9, #OFF_ACC]

    // phase = (phase + (len mod 42)) mod 42
    // neste ponto w1=0; usar x0 original não disponível -> usar low acc para variar fase
    ldr     w13, [x9, #OFF_PHASE]
    and     w14, w10, #0x1f
    add     w13, w13, w14
3:
    cmp     w13, #PERIOD_42
    b.lt    4f
    sub     w13, w13, #PERIOD_42
    b       3b
4:
    str     w13, [x9, #OFF_PHASE]
2:
    ret

// -----------------------------------------------------------------------------
// uint64_t vectra_pulse_read(uint32_t* phase, uint32_t* coh, uint32_t* ent, uint32_t* flags)
// x0=phase*, x1=coh*, x2=ent*, x3=flags* ; retorno x0=acc
// -----------------------------------------------------------------------------
vectra_pulse_read:
    adrp    x9, vectra_state
    add     x9, x9, :lo12:vectra_state

    ldr     w10, [x9, #OFF_PHASE]
    ldr     w11, [x9, #OFF_COH]
    ldr     w12, [x9, #OFF_ENT]
    ldr     w13, [x9, #OFF_FLAGS]

    cbz     x0, 5f
    str     w10, [x0]
5:
    cbz     x1, 6f
    str     w11, [x1]
6:
    cbz     x2, 7f
    str     w12, [x2]
7:
    cbz     x3, 8f
    str     w13, [x3]
8:
    ldr     x0, [x9, #OFF_ACC]
    ret

.bss
.align 6
vectra_state:
    .space STATE_SIZE
