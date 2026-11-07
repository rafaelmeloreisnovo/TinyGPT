/* SPDX-License-Identifier: MIT
 * Copyright (c) 2026 Instituto Rafael / Delta RafaelVerbo Omega
 * Isolated experimental C11 freestanding causal-attention decode step.
 */
#ifndef RAF_DECODER_Q8_H
#define RAF_DECODER_Q8_H
#include "../microinfer/raf_microinfer.h"
#define RAF_DEC_Q8_MAX_DIM 64u
#define RAF_DEC_Q8_MAX_SLOTS 128u

enum {
    RAF_DEC_Q8_OK = 0,
    RAF_DEC_Q8_BAD_POINTER = 1,
    RAF_DEC_Q8_BAD_SHAPE = 2,
    RAF_DEC_Q8_BAD_CAPACITY = 3,
    RAF_DEC_Q8_BAD_STATE = 4,
    RAF_DEC_Q8_KERNEL_FAILURE = 5
};

typedef struct {
    const raf_q8 *wq;
    const raf_q8 *wk;
    const raf_q8 *wv;
    const raf_q8 *wo;
    raf_count32 weight_elements; /* element count of EACH matrix */
    raf_count32 dim;             /* exactly 16 or 64; one causal head */
} raf_dec_q8_model;

typedef struct {
    raf_q8 *keys;
    raf_q8 *values;
    raf_count32 elements;    /* independently valid capacity of EACH cache */
    raf_count32 slots;       /* max tokens; 1..128 */
    raf_count32 used;        /* committed tokens; <=slots */
} raf_dec_q8_cache;

typedef struct {
    raf_q8 q[RAF_DEC_Q8_MAX_DIM];
    raf_q8 k[RAF_DEC_Q8_MAX_DIM];
    raf_q8 v[RAF_DEC_Q8_MAX_DIM];
    raf_q8 context[RAF_DEC_Q8_MAX_DIM];
    raf_acc32 accum[RAF_DEC_Q8_MAX_DIM];
    raf_acc32 scores[RAF_DEC_Q8_MAX_SLOTS];
} raf_dec_q8_scratch;

/* Contract: writable regions (output, cache keys/values and scratch) must be
 * disjoint from each other and from input and immutable model weights.
 * Read-only weight matrices may alias each other. Caller owns memory.
 * Each Q8 matrix is row-major dim*dim, coefficients interpreted as x/128.
 * Quantize by truncation toward zero and saturate to [-128,127].
 * Attention: logits dot(q,k)/(4*sqrt(dim)) in Q12; exp(-delta) LUT
 * rounded at 1/4 increments, normalized using integer truncation.
 * This is an approximate SINGLE-HEAD causal attention step, NOT a complete GPT.
 * A successful call appends exactly one key/value and one output token-vector.
 * On rejected calls: output, cache data and cache.used remain unchanged.
 * No malloc/heap, libc, OS, syscalls, globals with mutable state or I/O.
 * Does not support aliased regions or concurrent mutation.
 */
int raf_dec_q8_step(const raf_dec_q8_model *model,
                    raf_dec_q8_cache *cache,
                    raf_dec_q8_scratch *scratch,
                    const raf_q8 *input, raf_count32 input_elements,
                    raf_q8 *output, raf_count32 output_elements);
#endif
