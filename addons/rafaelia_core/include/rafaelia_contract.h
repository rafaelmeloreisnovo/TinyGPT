#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Inicializa o estado interno com seed determinística. */
void vectra_pulse_init(uint64_t seed);

/* Passo de atualização com coerência e entropia de entrada em Q16.16. */
void vectra_pulse_step(int32_t c_in_q16, int32_t h_in_q16);

/* Colapsa estado (estável/exploratório) com base no delta interno. */
void vectra_pulse_collapse(void);

/* Injeta fluxo de bytes no acumulador interno (FNV-1a 64). */
void vectra_pulse_inject(const uint8_t* data, uint32_t len);

/*
 * Leitura de estado sem alocação:
 * - ponteiros nulos são aceitos;
 * - retorna o acumulador (acc) de 64 bits.
 */
uint64_t vectra_pulse_read(uint32_t* phase,
                           uint32_t* coherence_q16,
                           uint32_t* entropy_q16,
                           uint32_t* flags);

#ifdef __cplusplus
}
#endif
