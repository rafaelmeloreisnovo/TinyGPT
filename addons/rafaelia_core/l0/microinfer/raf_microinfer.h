/* SPDX-License-Identifier: MIT
 * Copyright (c) 2026 Instituto Rafael / ΔRafaelVerboΩ
 * Standalone C11 integer matvec API; see ../../LICENSE-RAFAELIA.txt.
 */
#ifndef RAF_MICROINFER_H
#define RAF_MICROINFER_H
typedef signed char raf_q8;
typedef signed int raf_acc32;
typedef unsigned int raf_count32;
_Static_assert(sizeof(raf_q8) == 1 && (raf_q8)-1 < 0, "requires signed 8-bit char");
_Static_assert(sizeof(raf_acc32) == 4, "requires 32-bit signed int");
_Static_assert(sizeof(raf_count32) == 4, "requires 32-bit unsigned int");
enum {
    RAF_MICRO_OK = 0,
    RAF_MICRO_BAD_POINTER = 1,
    RAF_MICRO_BAD_SHAPE = 2,
    RAF_MICRO_BAD_CAPACITY = 3
};
/* Row-major W[rows][cols] * x[cols] -> out[rows], exact signed int32 sum.
 * max cols 4096 proves no accumulator overflow even at -128 * -128.
 * Counts are in elements, NOT bytes; validates ALL bounds before output writes.
 * Non-overlapping, properly aligned caller-owned buffers are required.
 * No allocation, global writable state, I/O, syscalls or implicit platform API.
 */
int raf_micro_q8_matvec(raf_acc32 *out, raf_count32 out_count,
                        const raf_q8 *weights, raf_count32 weight_count,
                        const raf_q8 *input, raf_count32 input_count,
                        raf_count32 rows, raf_count32 cols);
#endif
