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

## Build

No CMake do repositório, o addon é opcional:

- `-DTINYGPT_BUILD_RAFAELIA_ADDON=ON`

Em arquiteturas não AArch64 o build do addon é pulado automaticamente.
