#include "rmr_engine.h"

#include <string.h>

static uint8_t rmr_token_table[256];
static uint32_t rmr_crc_table[256];
static int rmr_tables_ready = 0;

static inline uint32_t rmr_rotl32(uint32_t x, uint32_t n) {
    return (x << n) | (x >> (32u - n));
}

static inline uint64_t rmr_rotl64(uint64_t x, uint32_t n) {
    return (x << n) | (x >> (64u - n));
}

static inline uint32_t rmr_q16_mul(uint32_t a_q16, uint32_t b_q16) {
    return (uint32_t)(((uint64_t)a_q16 * (uint64_t)b_q16) >> 16u);
}

static void rmr_prepare_tables(void) {
    if (rmr_tables_ready) {
        return;
    }

    for (uint32_t i = 0; i < 256; ++i) {
        uint8_t v = (uint8_t)i;
        uint8_t alpha = (uint8_t)(v | 0x20u);
        uint8_t is_letter = (uint8_t)((alpha >= 'a') & (alpha <= 'z'));
        rmr_token_table[i] = (uint8_t)(v ^ (is_letter * 0x20u));
    }

    for (uint32_t i = 0; i < 256; ++i) {
        uint32_t c = i;
        for (uint32_t b = 0; b < 8; ++b) {
            uint32_t m = (uint32_t)(-(int32_t)(c & 1u));
            c = (c >> 1u) ^ (0xEDB88320u & m);
        }
        rmr_crc_table[i] = c;
    }

    rmr_tables_ready = 1;
}

uint32_t rmr_entropy_milli(const uint8_t* input, size_t input_len) {
    if (input == NULL || input_len == 0) {
        return 0;
    }

    uint8_t seen[256] = {0};
    uint32_t unique = 0;
    uint32_t transitions = 0;

    for (size_t i = 0; i < input_len; ++i) {
        uint8_t b = input[i];
        unique += (uint32_t)(seen[b] == 0);
        seen[b] = 1;
        if (i > 0) {
            transitions += (uint32_t)(input[i] != input[i - 1]);
        }
    }

    const uint32_t term_u = (unique * 6000u) / 256u;
    const uint32_t term_t = (input_len > 1) ? (transitions * 2000u) / (uint32_t)(input_len - 1u) : 0u;
    return term_u + term_t;
}

static uint16_t rmr_toroidal_component(uint32_t seed, uint32_t k) {
    uint32_t v = seed ^ (0x9E3779B9u * (k + 1u));
    v ^= v >> 16u;
    return (uint16_t)(v & 0xFFFFu);
}

uint64_t rmr_merkle_root64(const uint64_t* leaves, size_t leaf_count) {
    if (leaves == NULL || leaf_count == 0) {
        return 0;
    }

    uint64_t acc = 0xCBF29CE484222325ULL;
    for (size_t i = 0; i < leaf_count; ++i) {
        acc ^= leaves[i];
        acc *= 0x100000001B3ULL;
        acc = rmr_rotl64(acc, 13u);
    }
    return acc;
}

void rmr_engine_init(rmr_engine_t* engine, const rmr_config_t* cfg) {
    rmr_prepare_tables();
    if (engine == NULL) {
        return;
    }

    const uint32_t threshold = (cfg != NULL) ? (cfg->gate_threshold & 0xFFu) : 160u;
    const uint32_t seed = (cfg != NULL) ? cfg->seed : 0xA5A5F00Du;
    const uint32_t alpha_q16 = (cfg != NULL && cfg->alpha_q16 != 0u) ? cfg->alpha_q16 : 0x4000u;

    engine->threshold = threshold;
    engine->rolling = seed;
    engine->crc32 = 0xFFFFFFFFu;
    engine->coherence_q16 = 0x8000u;
    engine->entropy_q16 = 0x8000u;
    engine->phi_q16 = 0x4000u;
    engine->cycle_42 = 0u;
    engine->alpha_q16 = alpha_q16;

    for (uint32_t k = 0; k < RMR_TORUS_DIM; ++k) {
        engine->torus_u16[k] = rmr_toroidal_component(seed, k);
    }
}

size_t rmr_engine_run(rmr_engine_t* engine,
                      const uint8_t* input,
                      size_t input_len,
                      uint8_t* output,
                      size_t output_cap,
                      rmr_report_t* report) {
    if (engine == NULL || input == NULL || output == NULL || output_cap == 0) {
        return 0;
    }

    uint32_t rolling = engine->rolling;
    uint32_t crc = engine->crc32;
    const uint32_t threshold = engine->threshold;

    size_t out_n = 0;
    uint32_t skipped = 0;

    uint32_t unique_bitmap[8] = {0};
    uint32_t transitions = 0;
    uint8_t prev = 0;

    for (size_t i = 0; i < input_len; ++i) {
        const uint8_t token = rmr_token_table[input[i]];
        unique_bitmap[token >> 5u] |= 1u << (token & 31u);
        transitions += (uint32_t)((i > 0) & (token != prev));
        prev = token;

        const uint32_t phi_hash = (uint32_t)(((uint64_t)token * 0x9E3779B9u) >> 8u);
        const uint32_t score = (phi_hash ^ rolling) & 0xFFu;

        const uint32_t pass = (uint32_t)(score >= threshold);
        const uint8_t mask = (uint8_t)(-(int32_t)pass);

        const uint8_t mixed = (uint8_t)(rmr_rotl32(token, 1u) ^ (rolling & 0xFFu));
        const uint8_t outv = (uint8_t)(mixed & mask);

        if ((pass != 0u) && (out_n < output_cap)) {
            output[out_n++] = outv;
        } else {
            skipped += 1u;
        }

        rolling ^= phi_hash + 0x7F4A7C15u;
        rolling = rmr_rotl32(rolling, 5u);

        const uint32_t idx = (crc ^ outv) & 0xFFu;
        crc = (crc >> 8u) ^ rmr_crc_table[idx];
    }

    uint32_t unique = 0;
    for (uint32_t i = 0; i < 8u; ++i) {
        unique += (uint32_t)__builtin_popcount(unique_bitmap[i]);
    }

    /* H ~= U/256 + T/N (formula 14/43) em Q16.16 */
    const uint32_t h_u_q16 = (unique << 16u) / 256u;
    const uint32_t h_t_q16 = (input_len > 0) ? (uint32_t)(((uint64_t)transitions << 16u) / (uint32_t)input_len) : 0u;
    const uint32_t h_in_q16 = (h_u_q16 + h_t_q16) >> 1u;

    /* C_in derivado da densidade de passagem */
    const uint32_t c_in_q16 = (input_len > 0) ? (uint32_t)(((uint64_t)out_n << 16u) / (uint32_t)input_len) : 0u;

    /* EMA: X_{t+1}=(1-a)X_t + a X_in */
    const uint32_t a = engine->alpha_q16;
    const uint32_t om = 0x10000u - a;
    engine->coherence_q16 = rmr_q16_mul(om, engine->coherence_q16) + rmr_q16_mul(a, c_in_q16);
    engine->entropy_q16 = rmr_q16_mul(om, engine->entropy_q16) + rmr_q16_mul(a, h_in_q16);

    /* phi=(1-H)*C */
    const uint32_t one_minus_h = (engine->entropy_q16 >= 0x10000u) ? 0u : (0x10000u - engine->entropy_q16);
    engine->phi_q16 = rmr_q16_mul(one_minus_h, engine->coherence_q16);

    engine->cycle_42 = (engine->cycle_42 + 1u) % RMR_PERIOD_42;

    for (uint32_t k = 0; k < RMR_TORUS_DIM; ++k) {
        engine->torus_u16[k] = rmr_toroidal_component(rolling ^ engine->phi_q16, k + engine->cycle_42);
    }

    engine->rolling = rolling;
    engine->crc32 = crc;

    if (report != NULL) {
        report->bytes_in = (uint32_t)input_len;
        report->bytes_out = (uint32_t)out_n;
        report->bytes_skipped = skipped;
        report->crc32 = crc ^ 0xFFFFFFFFu;
        report->rolling_hash = rolling;
        report->coherence_q16 = engine->coherence_q16;
        report->entropy_q16 = engine->entropy_q16;
        report->phi_q16 = engine->phi_q16;
        report->cycle_42 = engine->cycle_42;
        memcpy(report->torus_u16, engine->torus_u16, sizeof(engine->torus_u16));
    }

    return out_n;
}
