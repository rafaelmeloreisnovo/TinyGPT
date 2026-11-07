/* SPDX-License-Identifier: MIT; freestanding-aware negative and parity tests. */
#include "../raf_microinfer.h"
static unsigned rng = 0x5eed1234u;
static unsigned next(void)
{
    rng ^= rng << 13u;
    rng ^= rng >> 17u;
    rng ^= rng << 5u;
    return rng;
}
int main(void)
{
    raf_q8 weights[8u * 96u], input[96u];
    raf_acc32 out[8u], ref[8u];
    unsigned cols, rows, r, c, i, seed;
    for (cols = 1u; cols <= 96u; ++cols) {
        for (rows = 1u; rows <= 8u; ++rows) {
            for (i = 0u; i < rows * cols; ++i)
                weights[i] = (raf_q8)((int)(next() & 255u) - 128);
            for (i = 0u; i < cols; ++i)
                input[i] = (raf_q8)((int)(next() & 255u) - 128);
            for (r = 0u; r < rows; ++r) {
                ref[r] = 0;
                for (c = 0u; c < cols; ++c)
                    ref[r] += (int)weights[r * cols + c] * (int)input[c];
                out[r] = -1234567;
            }
            if (raf_micro_q8_matvec(out, rows, weights, rows * cols,
                                    input, cols, rows, cols) != RAF_MICRO_OK)
                return 1;
            for (r = 0u; r < rows; ++r) if (out[r] != ref[r]) return 2;
        }
    }
    /* Full Q8 extremes and maximum allowed dot length: no 32-bit overflow. */
    {
        raf_q8 fullw[4096], fullx[4096];
        raf_acc32 one = 0;
        for (i = 0u; i < 4096u; ++i) fullw[i] = fullx[i] = -128;
        if (raf_micro_q8_matvec(&one, 1u, fullw, 4096u,
                                fullx, 4096u, 1u, 4096u) != RAF_MICRO_OK ||
            one != 67108864) return 3;
    }
    /* Failure must not mutate output; shape and capacity checks precede writes. */
    seed = 0x77aa11eeu;
    out[0] = (raf_acc32)seed;
    if (raf_micro_q8_matvec(out, 1u, weights, 1u, input, 1u, 0u, 1u)
        != RAF_MICRO_BAD_SHAPE || out[0] != (raf_acc32)seed) return 4;
    if (raf_micro_q8_matvec(out, 1u, weights, 1u, input, 1u, 1u, 4097u)
        != RAF_MICRO_BAD_SHAPE || out[0] != (raf_acc32)seed) return 5;
    if (raf_micro_q8_matvec(out, 1u, weights, 0u, input, 1u, 1u, 1u)
        != RAF_MICRO_BAD_CAPACITY || out[0] != (raf_acc32)seed) return 6;
    if (raf_micro_q8_matvec(out, 0u, weights, 1u, input, 1u, 1u, 1u)
        != RAF_MICRO_BAD_CAPACITY || out[0] != (raf_acc32)seed) return 7;
    if (raf_micro_q8_matvec(out, 1u, weights, 1u, input, 0u, 1u, 1u)
        != RAF_MICRO_BAD_CAPACITY || out[0] != (raf_acc32)seed) return 8;
    if (raf_micro_q8_matvec(out, 1u, (const raf_q8 *)0, 1u, input, 1u, 1u, 1u)
        != RAF_MICRO_BAD_POINTER || out[0] != (raf_acc32)seed) return 9;
    if (raf_micro_q8_matvec(out, 1u, weights, 1u, input, 1u, 2u, 1u)
        != RAF_MICRO_BAD_CAPACITY || out[0] != (raf_acc32)seed) return 10;
    return 0;
}
