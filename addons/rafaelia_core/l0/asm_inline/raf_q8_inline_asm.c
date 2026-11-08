/* SPDX-License-Identifier: MIT
 * Copyright (c) 2026 Instituto Rafael / Delta RafaelVerbo Omega
 * Independent ARMv7-A / AArch64 inline-assembly alternative to Q8 matvec.
 * ABI contract: ../microinfer/raf_microinfer.h. No libc or global state.
 */
#include "../microinfer/raf_microinfer.h"
#include "../microinfer/raf_micro_preflight.h"

#if !defined(__GNUC__) && !defined(__clang__)
#error "This inline assembly backend requires GNU-compatible compiler asm"
#endif
#if defined(__arm__) && !defined(__aarch64__)
#if !defined(__ARM_ARCH_7A__) && !defined(__ARM_ARCH_7R__) && !defined(__ARM_ARCH_7S__)
#error "The A32 inline-asm backend requires ARMv7-A/R/S with MLA"
#endif
#elif !defined(__aarch64__)
#error "No silent portable fallback: select the scalar kernel on other ISAs"
#endif

/* n=1..4096, so max abs signed Q8 sum is 4096*128*128=67,108,864.
 * The signed 32-bit accumulator never overflows, including -128 extremes.
 * For each lane, both bytes are sign extended by LDRSB before MLA/MADD.
 * No writes to input or weights. Compiler owns the enclosing call ABI.
 */
static inline raf_acc32 raf_dot_q8_a32_a64(const raf_q8 *weights,
                                            const raf_q8 *input,
                                            raf_count32 n)
{
    raf_acc32 sum = 0;
    raf_acc32 a, b;
    const raf_q8 *wp = weights, *xp = input;
#if defined(__aarch64__)
    __asm__ volatile(
        "1:\n\t"
        "ldrsb %w[a], [%[wp]], #1\n\t"
        "ldrsb %w[b], [%[xp]], #1\n\t"
        "madd %w[sum], %w[a], %w[b], %w[sum]\n\t"
        "subs %w[n], %w[n], #1\n\t"
        "b.ne 1b\n\t"
        : [sum] "+r" (sum), [n] "+r" (n),
          [wp] "+r" (wp), [xp] "+r" (xp),
          [a] "=&r" (a), [b] "=&r" (b)
        :
        : "cc", "memory");
#else
    __asm__ volatile(
        "1:\n\t"
        "ldrsb %[a], [%[wp]], #1\n\t"
        "ldrsb %[b], [%[xp]], #1\n\t"
        "mla %[sum], %[a], %[b], %[sum]\n\t"
        "subs %[n], %[n], #1\n\t"
        "bne 1b\n\t"
        : [sum] "+r" (sum), [n] "+r" (n),
          [wp] "+r" (wp), [xp] "+r" (xp),
          [a] "=&r" (a), [b] "=&r" (b)
        :
        : "cc", "memory");
#endif
    return sum;
}

/* Drop-in ABI: link THIS object in place of raf_microinfer.c, never both.
 * All validation happens before any output write. Buffers must be distinct,
 * aligned to their element types and sized according to caller counts.
 */
int raf_micro_q8_matvec(raf_acc32 *out, raf_count32 out_count,
                        const raf_q8 *weights, raf_count32 weight_count,
                        const raf_q8 *input, raf_count32 input_count,
                        raf_count32 rows, raf_count32 cols)
{
    raf_count32 r, offset = 0u;
    /* Identical preflight to scalar kernel; no output writes on error. */
    int status = raf_micro_q8_preflight(out, out_count, weights, weight_count,
                                        input, input_count, rows, cols);
    if (status != RAF_MICRO_OK) return status;
    for (r = 0u; r < rows; ++r) {
        out[r] = raf_dot_q8_a32_a64(weights + offset, input, cols);
        offset += cols;
    }
    return RAF_MICRO_OK;
}
