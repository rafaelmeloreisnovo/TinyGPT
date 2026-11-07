/* SPDX-License-Identifier: MIT
 * Copyright (c) 2026 Instituto Rafael / ΔRafaelVerboΩ
 * No C standard headers, libc, allocation or compiler runtime assumptions.
 */
#include "raf_microinfer.h"
#ifndef RAF_MICRO_UNROLL4
#define RAF_MICRO_UNROLL4 0
#endif
#if defined(RAF_MICRO_ARM_ASM) && !defined(__arm__) && !defined(__aarch64__)
#error "RAF_MICRO_ARM_ASM requires ARMv7 or AArch64; portable C is the default"
#endif
static inline raf_acc32 raf_mac(raf_acc32 sum, raf_acc32 a, raf_acc32 b)
{
#if defined(RAF_MICRO_ARM_ASM) && defined(__aarch64__)
    __asm__ volatile("madd %w0, %w1, %w2, %w0"
                     : "+r"(sum) : "r"(a), "r"(b));
#elif defined(RAF_MICRO_ARM_ASM) && defined(__arm__)
    __asm__ volatile("mla %0, %1, %2, %0"
                     : "+r"(sum) : "r"(a), "r"(b));
#else
    sum += a * b;
#endif
    return sum;
}
int raf_micro_q8_matvec(raf_acc32 *out, raf_count32 out_count,
                        const raf_q8 *weights, raf_count32 weight_count,
                        const raf_q8 *input, raf_count32 input_count,
                        raf_count32 rows, raf_count32 cols)
{
    raf_count32 r, c, offset = 0u;
    if (!out || !weights || !input) return RAF_MICRO_BAD_POINTER;
    if (!rows || !cols || cols > 4096u) return RAF_MICRO_BAD_SHAPE;
    /* Check division BEFORE row*col or pointer arithmetic; no partial writes. */
    if (out_count < rows || input_count < cols ||
        ((unsigned long long)rows * (unsigned long long)cols > (unsigned long long)weight_count)) return RAF_MICRO_BAD_CAPACITY;
    for (r = 0u; r < rows; ++r) {
        raf_acc32 acc = 0;
        c = 0u;
#if RAF_MICRO_UNROLL4
        for (; c + 4u <= cols; c += 4u) {
            acc = raf_mac(acc, weights[offset + c], input[c]);
            acc = raf_mac(acc, weights[offset + c + 1u], input[c + 1u]);
            acc = raf_mac(acc, weights[offset + c + 2u], input[c + 2u]);
            acc = raf_mac(acc, weights[offset + c + 3u], input[c + 3u]);
        }
#endif
        for (; c < cols; ++c)
            acc = raf_mac(acc, weights[offset + c], input[c]);
        out[r] = acc;
        offset += cols;
    }
    return RAF_MICRO_OK;
}
