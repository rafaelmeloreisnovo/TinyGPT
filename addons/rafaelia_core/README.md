# RafaelIA Core Addon (Standalone)

Addon autoral separado do TinyGPT com execução de baixo nível em AArch64.

## Objetivo

- preservar o TinyGPT sem mudanças invasivas;
- manter o núcleo RafaelIA isolado, rastreável e com licença própria;
- operar com baixa fricção (estado estático, sem GC, sem dependências externas no núcleo ASM).

## Estrutura

```text
addons/rafaelia_core/
  asm/arm64/vectra_pulse.S     # núcleo AArch64
  include/rafaelia_contract.h  # ABI C mínima
  docs/ARCHITECTURE.md
  docs/COMPLIANCE.md
  CMakeLists.txt               # build opcional e isolado
  LICENSE-RAFAELIA.txt
  NOTICE-RAFAELIA.txt
```

## ABI pública

- `vectra_pulse_init(seed)`
- `vectra_pulse_step(c_in_q16, h_in_q16)`
- `vectra_pulse_collapse()`
- `vectra_pulse_inject(data, len)`
- `vectra_pulse_read(phase, coherence_q16, entropy_q16, flags)`

## Semântica operacional

- Q16.16 para coerência/entropia.
- EMA sem alocação dinâmica: `C=(3*C+C_in)>>2`, `H=(3*H+H_in)>>2`.
- Colapso estável/exploratório por limiar de delta (`|C-H|`).
- Permutação multinível por mistura xorshift + rotação + FNV-1a.

## RMR Engine (executável real)

Engine C de baixa abstração para pipeline cognitivo com:

- tokenização zero-copy por tabela (`uint8_t -> token`);
- hash multiplicativo estilo phi (`0x9E3779B9`);
- gating esparso por limiar (`score >= threshold`);
- processamento branch-light com máscara;
- validação CRC32 incremental.

API pública em `include/rmr_engine.h`:

- `rmr_engine_init(...)`
- `rmr_engine_run(...)`

## Build

No CMake do repositório, o addon é opcional:

- `-DTINYGPT_BUILD_RAFAELIA_ADDON=ON`

Em arquiteturas não AArch64 o núcleo ASM é pulado automaticamente e o RMR Engine em C continua disponível.


### Mapeamento matemático implantado (núcleo RMR)

- Estado toroidal `s in [0,1)^7` e ciclo periódico `x_(n+42)=x_n`.
- EMA com `alpha=0.25` para coerência/entropia.
- `phi=(1-H)*C` em Q16.16.
- Entropia operacional `H ~= U/256 + T/N` e versão milli `entropy_milli`.
- Integridade por FNV-1a (`h=(h xor byte)*0x100000001B3`) + CRC32 incremental.
- Agregação Merkle-lite (`rmr_merkle_root64`) para folhas 64-bit.

- FFT/DFT discreta com `rmr_dft_magnitude` e correlação normalizada cardio com `rmr_cardio_resonance`.
- Invariantes de malha com `rmr_gcd_u32` e `rmr_stride_is_coprime` (`gcd(Δ,size)=1`).
- Dinâmica espiral/força com `rmr_spiral_pow_sqrt3_over_2` e `rmr_force_next`.
