/* SPDX-License-Identifier: MIT. Reproducible no-libc host test for common Q8 guard. */
#include "../raf_micro_preflight.h"
static raf_q8 weights[4096], input[4096];
static raf_acc32 result[64];
static unsigned seed = 0x4d8b0321u;
static unsigned rnd(void) { seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5; return seed; }
int main(void)
{
    unsigned i, t, rows, cols, r, c;
    raf_micro_span a, b;
    for (t = 0; t < 2000u; ++t) {
        rows = 1u + (rnd() % 16u);
        cols = 1u + (rnd() % 256u);
        for (i = 0; i < rows * cols; ++i) weights[i] = (raf_q8)((int)(rnd() & 255u) - 128);
        for (i = 0; i < cols; ++i) input[i] = (raf_q8)((int)(rnd() & 255u) - 128);
        for (r = 0; r < rows; ++r) result[r] = -123456;
        if (raf_micro_q8_matvec(result, 64u, weights, 4096u, input, 4096u, rows, cols) != RAF_MICRO_OK) return 1;
        for (r = 0; r < rows; ++r) {
            raf_acc32 expected = 0;
            for (c = 0; c < cols; ++c) expected += (raf_acc32)weights[r * cols + c] * (raf_acc32)input[c];
            if (result[r] != expected) return 2;
        }
    }
    for (i = 0; i < 4096u; ++i) weights[i] = input[i] = -128;
    if (raf_micro_q8_matvec(result, 64u, weights, 4096u, input, 4096u, 1u, 4096u) != RAF_MICRO_OK || result[0] != 67108864) return 3;
    result[0] = 31337;
    if (raf_micro_q8_matvec(result, 64u, (const raf_q8 *)result, 4096u, input, 4096u, 1u, 16u) != RAF_MICRO_BAD_ALIAS || result[0] != 31337) return 4;
    if (raf_micro_q8_matvec(result, 64u, weights, 4096u, (const raf_q8 *)result, 4096u, 1u, 16u) != RAF_MICRO_BAD_ALIAS || result[0] != 31337) return 5;
    if (raf_micro_q8_matvec((raf_acc32 *)((raf_q8 *)result + 1), 64u, weights, 4096u, input, 4096u, 1u, 16u) != RAF_MICRO_BAD_ALIGNMENT || result[0] != 31337) return 6;
    if (raf_micro_q8_matvec(result, 64u, weights, 15u, input, 4096u, 1u, 16u) != RAF_MICRO_BAD_CAPACITY || result[0] != 31337) return 7;
    if (raf_micro_q8_matvec(result, 64u, weights, 4096u, input, 4096u, 0xffffffffu, 4096u) != RAF_MICRO_BAD_CAPACITY || result[0] != 31337) return 8;
    if (raf_micro_span_make((const void *)((raf_micro_address)~(raf_micro_address)0 - 3u), 16u, &a)) return 9;
    if (!raf_micro_span_make(weights, 16u, &a) || !raf_micro_span_make(weights, 8u, &b) || !raf_micro_span_overlap(a, b)) return 10;
    if (raf_micro_q8_matvec(result, 64u, weights, 4096u, input, 4096u, 1u, 4097u) != RAF_MICRO_BAD_SHAPE || result[0] != 31337) return 11;
    /* Source/source overlap is legal: both spans are read-only. */
    weights[0] = 7;
    for (i = 1u; i < 16u; ++i) weights[i] = 0;
    if (raf_micro_q8_matvec(result, 64u, weights, 4096u, weights, 4096u, 1u, 16u) != RAF_MICRO_OK || result[0] != 49) return 12;
    return 0;
}
