/* SPDX-License-Identifier: MIT
 * Copyright (c) 2026 Instituto Rafael / Delta RafaelVerbo Omega
 * Freestanding attention: no platform includes, allocation, host callbacks.
 */
#include "raf_decoder_q8.h"

/* Q15 table for exp(-n/4), n=0..45. Offline rounded integer constants.
 * Scores with delta>=46/4 have zero approximate weight. */
static const unsigned short raf_exp_q15[46] = {
    32767,25519,19874,15478,12054,9388,7311,5694,4435,3454,
    2690,2095,1631,1271,989,771,600,467,364,283,221,172,134,
    104,81,63,49,38,30,23,18,14,11,9,7,5,4,3,2,2,1,1,1,1,1,0
};

/* Truncate signed division by 2^shift toward zero without compiler-rt. */
static raf_acc32 raf_div_pow2(raf_acc32 v, unsigned int shift)
{
    unsigned int magnitude = (unsigned int)(v < 0 ? -v : v);
    raf_acc32 quotient = (raf_acc32)(magnitude >> shift);
    return v < 0 ? -quotient : quotient;
}

static raf_q8 raf_sat_q8(raf_acc32 v)
{
    if (v > 127) return (raf_q8)127;
    if (v < -128) return (raf_q8)-128;
    return (raf_q8)v;
}

/* Restoring divide: avoid compiler-rt/__aeabi_idiv on ARMv7. d>0.
 * Before each shift remainder<d<=4194176, so remainder<<1 fits u32. */
static unsigned int raf_div_u32(unsigned int n, unsigned int d)
{
    unsigned int quotient = 0u, remainder = 0u, i;
    for (i = 0u; i < 32u; ++i) {
        remainder = (remainder << 1u) | ((n >> (31u - i)) & 1u);
        quotient <<= 1u;
        if (remainder >= d) {
            remainder -= d;
            quotient |= 1u;
        }
    }
    return quotient;
}

static raf_q8 raf_weighted_div(raf_acc32 numerator, unsigned int denominator)
{
    unsigned int magnitude = (unsigned int)(numerator < 0 ? -numerator : numerator);
    unsigned int quotient = raf_div_u32(magnitude, denominator);
    if (numerator < 0) return (raf_q8)(quotient > 128u ? -128 : -(int)quotient);
    return (raf_q8)(quotient > 127u ? 127 : (int)quotient);
}

static raf_acc32 raf_score(const raf_q8 *a, const raf_q8 *b,
                           raf_count32 dim)
{
    raf_count32 j;
    raf_acc32 dot = 0;
    for (j = 0u; j < dim; ++j)
        dot += (raf_acc32)a[j] * (raf_acc32)b[j];
    /* sqrt(16)=4, sqrt(64)=8; convert Q14 dot to Q12 logits. */
    return raf_div_pow2(dot, dim == 16u ? 4u : 5u);
}

static unsigned int raf_weight(raf_acc32 maximum, raf_acc32 score)
{
    /* maximum >= score; bounded difference <= 131072, no overflow. */
    unsigned int idx = (unsigned int)(maximum - score) / 1024u;
    return idx < 46u ? (unsigned int)raf_exp_q15[idx] : 0u;
}

int raf_dec_q8_step(const raf_dec_q8_model *model,
                    raf_dec_q8_cache *cache,
                    raf_dec_q8_scratch *scratch,
                    const raf_q8 *input, raf_count32 input_elements,
                    raf_q8 *output, raf_count32 output_elements)
{
    raf_count32 dim, t, j, total;
    raf_acc32 maximum;
    unsigned int denominator = 0u;
    int code;
    if (!model || !cache || !scratch || !input || !output)
        return RAF_DEC_Q8_BAD_POINTER;
    if (!model->wq || !model->wk || !model->wv || !model->wo ||
        !cache->keys || !cache->values) return RAF_DEC_Q8_BAD_POINTER;
    dim = model->dim;
    if ((dim != 16u && dim != 64u) || cache->slots == 0u ||
        cache->slots > RAF_DEC_Q8_MAX_SLOTS) return RAF_DEC_Q8_BAD_SHAPE;
    if (cache->used > cache->slots) return RAF_DEC_Q8_BAD_STATE;
    if (cache->used == cache->slots || input_elements < dim ||
        output_elements < dim || model->weight_elements < dim * dim ||
        cache->elements < cache->slots * dim) return RAF_DEC_Q8_BAD_CAPACITY;

    code = raf_micro_q8_matvec(scratch->accum, dim, model->wq,
            model->weight_elements, input, input_elements, dim, dim);
    if (code != RAF_MICRO_OK) return RAF_DEC_Q8_KERNEL_FAILURE;
    for (j = 0u; j < dim; ++j)
        scratch->q[j] = raf_sat_q8(raf_div_pow2(scratch->accum[j], 7u));
    code = raf_micro_q8_matvec(scratch->accum, dim, model->wk,
            model->weight_elements, input, input_elements, dim, dim);
    if (code != RAF_MICRO_OK) return RAF_DEC_Q8_KERNEL_FAILURE;
    for (j = 0u; j < dim; ++j)
        scratch->k[j] = raf_sat_q8(raf_div_pow2(scratch->accum[j], 7u));
    code = raf_micro_q8_matvec(scratch->accum, dim, model->wv,
            model->weight_elements, input, input_elements, dim, dim);
    if (code != RAF_MICRO_OK) return RAF_DEC_Q8_KERNEL_FAILURE;
    for (j = 0u; j < dim; ++j)
        scratch->v[j] = raf_sat_q8(raf_div_pow2(scratch->accum[j], 7u));

    total = cache->used + 1u;
    maximum = -2147483647 - 1;
    for (t = 0u; t < total; ++t) {
        const raf_q8 *key = t == cache->used ? scratch->k :
                            cache->keys + t * dim;
        scratch->scores[t] = raf_score(scratch->q, key, dim);
        if (scratch->scores[t] > maximum) maximum = scratch->scores[t];
    }
    for (t = 0u; t < total; ++t)
        denominator += raf_weight(maximum, scratch->scores[t]);
    /* At least the maximum score has LUT weight 32767, so denominator>0. */
    for (j = 0u; j < dim; ++j) {
        raf_acc32 numerator = 0;
        for (t = 0u; t < total; ++t) {
            const raf_q8 *val = t == cache->used ? scratch->v :
                                cache->values + t * dim;
            numerator += (raf_acc32)raf_weight(maximum, scratch->scores[t]) *
                         (raf_acc32)val[j];
        }
        scratch->context[j] = raf_weighted_div(numerator, denominator);
    }
    code = raf_micro_q8_matvec(scratch->accum, dim, model->wo,
            model->weight_elements, scratch->context, dim, dim, dim);
    if (code != RAF_MICRO_OK) return RAF_DEC_Q8_KERNEL_FAILURE;

    /* Commit is final: no error path below; no partial mutation on rejection. */
    for (j = 0u; j < dim; ++j) {
        cache->keys[cache->used * dim + j] = scratch->k[j];
        cache->values[cache->used * dim + j] = scratch->v[j];
        output[j] = raf_sat_q8(raf_div_pow2(scratch->accum[j], 7u));
    }
    cache->used = total;
    return RAF_DEC_Q8_OK;
}
