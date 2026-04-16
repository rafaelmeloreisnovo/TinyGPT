#pragma once

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RMR_TORUS_DIM 7u
#define RMR_PERIOD_42 42u

typedef struct {
    uint32_t gate_threshold;      /* 0..255 */
    uint32_t seed;
    uint32_t alpha_q16;           /* default 0x4000 (0.25) */
} rmr_config_t;

typedef struct {
    uint32_t bytes_in;
    uint32_t bytes_out;
    uint32_t bytes_skipped;
    uint32_t crc32;
    uint32_t rolling_hash;
    uint32_t coherence_q16;
    uint32_t entropy_q16;
    uint32_t phi_q16;
    uint32_t cycle_42;
    uint16_t torus_u16[RMR_TORUS_DIM]; /* s in [0,1)^7 */
} rmr_report_t;

typedef struct {
    uint32_t threshold;
    uint32_t rolling;
    uint32_t crc32;
    uint32_t coherence_q16;
    uint32_t entropy_q16;
    uint32_t phi_q16;
    uint32_t cycle_42;
    uint32_t alpha_q16;
    uint16_t torus_u16[RMR_TORUS_DIM];
} rmr_engine_t;

void rmr_engine_init(rmr_engine_t* engine, const rmr_config_t* cfg);
size_t rmr_engine_run(rmr_engine_t* engine,
                      const uint8_t* input,
                      size_t input_len,
                      uint8_t* output,
                      size_t output_cap,
                      rmr_report_t* report);

/* utilitários de integridade */
uint64_t rmr_merkle_root64(const uint64_t* leaves, size_t leaf_count);
uint32_t rmr_entropy_milli(const uint8_t* input, size_t input_len);

#ifdef __cplusplus
}
#endif
