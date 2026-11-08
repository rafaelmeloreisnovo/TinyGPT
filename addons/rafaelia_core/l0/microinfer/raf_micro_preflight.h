/* SPDX-License-Identifier: MIT
 * Copyright (c) 2026 Instituto Rafael / Delta RafaelVerbo Omega
 * Bounded, ABI-preserving, header-only memory preflight for Q8 kernels.
 * Target: freestanding GCC/Clang ARMv7 and AArch64; also tests on host.
 */
#ifndef RAF_MICRO_PREFLIGHT_H
#define RAF_MICRO_PREFLIGHT_H
#include "raf_microinfer.h"
#if !defined(__UINTPTR_TYPE__)
#error "An integer type capable of representing pointers is required"
#endif
typedef __UINTPTR_TYPE__ raf_micro_address;
typedef struct {
    raf_micro_address lo;
    raf_micro_address hi; /* exclusive */
} raf_micro_span;

_Static_assert(_Alignof(raf_acc32) == 4u, "Q8 ABI requires 4-byte int32 alignment");
_Static_assert(sizeof(raf_micro_address) == sizeof(void *), "pointer representation mismatch");

/* Reject a wrap or length outside addressable space before any pointer math.
 * Validity of the backing allocation remains a caller responsibility.
 * Numeric ordering of pointer representations uses GCC/Clang target ABI.
 */
static inline int raf_micro_span_make(const void *p, unsigned long long n,
                                      raf_micro_span *out)
{
    raf_micro_address lo = (raf_micro_address)p;
    raf_micro_address max = (raf_micro_address)~(raf_micro_address)0;
    if (!p || !out || n == 0u || n > (unsigned long long)(max - lo))
        return 0;
    out->lo = lo;
    out->hi = lo + (raf_micro_address)n;
    return 1;
}

static inline int raf_micro_span_overlap(raf_micro_span a, raf_micro_span b)
{
    return a.lo < b.hi && b.lo < a.hi;
}

/* Shared preflight for portable scalar C and ARM inline assembly.
 * No output write occurs on rejection; existing return values are unchanged.
 */
static inline int raf_micro_q8_preflight(raf_acc32 *out, raf_count32 out_count,
                                         const raf_q8 *weights, raf_count32 weight_count,
                                         const raf_q8 *input, raf_count32 input_count,
                                         raf_count32 rows, raf_count32 cols)
{
    raf_micro_span dst, w, x;
    unsigned long long total;
    if (!out || !weights || !input) return RAF_MICRO_BAD_POINTER;
    if (!rows || !cols || cols > 4096u) return RAF_MICRO_BAD_SHAPE;
    total = (unsigned long long)rows * (unsigned long long)cols;
    if (out_count < rows || input_count < cols ||
        total > (unsigned long long)weight_count) return RAF_MICRO_BAD_CAPACITY;
    if (((raf_micro_address)out & 3u) != 0u) return RAF_MICRO_BAD_ALIGNMENT;
    if (!raf_micro_span_make(out, (unsigned long long)rows * sizeof(*out), &dst) ||
        !raf_micro_span_make(weights, total * sizeof(*weights), &w) ||
        !raf_micro_span_make(input, (unsigned long long)cols * sizeof(*input), &x))
        return RAF_MICRO_BAD_CAPACITY;
    if (raf_micro_span_overlap(dst, w) || raf_micro_span_overlap(dst, x))
        return RAF_MICRO_BAD_ALIAS;
    return RAF_MICRO_OK;
}
#endif
