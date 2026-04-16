#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Inicializa o estado do núcleo RafaelIA com uma seed determinística.
 */
void vectra_pulse_init(uint64_t seed);

/**
 * Executa um passo da dinâmica com coerência/entropia de entrada em Q16.16.
 */
void vectra_pulse_step(int32_t c_in_q16, int32_t h_in_q16);

/**
 * Executa o colapso para o atrator mais próximo no espaço de estados.
 */
void vectra_pulse_collapse(void);

/**
 * Injeta bytes no núcleo para atualização incremental de estado.
 */
void vectra_pulse_inject(const uint8_t* data, uint32_t len);

#ifdef __cplusplus
}
#endif
