# Arquitetura do Addon RafaelIA

## 1) Separação estrutural

O addon fica em `addons/rafaelia_core` para manter:

- independência autoral;
- integração opcional;
- risco de regressão reduzido no TinyGPT.

## 2) Núcleo de execução (AArch64)

Arquivo principal: `asm/arm64/vectra_pulse.S`.

Características:

- estado interno fixo em `.bss` (32 bytes);
- sem alocação dinâmica;
- sem dependências externas;
- comandos básicos de registrador e memória;
- fluxo determinístico com custo previsível.

## 3) Modelo interno

### Estado estático

- `seed` (64-bit)
- `acc` (64-bit)
- `phase` (32-bit, período 42)
- `coherence_q16` (32-bit)
- `entropy_q16` (32-bit)
- `flags` (32-bit)

### Atualização por passo

- EMA com `alpha=0.25` em aritmética inteira (`>>2`)
- mistura multinível no acumulador (`xorshift`, `ror`, `xor`, `add`)

### Colapso

- `delta = abs(C-H)`
- `flags=1` (estável) quando `delta <= threshold`
- `flags=2` (exploratório) no restante

### Injeção

- stream de bytes processado por FNV-1a 64-bit
- fase atualizada por redução modular

## 4) Integração com TinyGPT

- contrato ABI C em `include/rafaelia_contract.h`
- build controlado por `TINYGPT_BUILD_RAFAELIA_ADDON`
- addon compilado como biblioteca estática isolada

## 5) Evolução sugerida

1. snapshots binários de estado para replay determinístico;
2. testes de sanidade Q16.16 e estabilidade de fase;
3. integração de telemetria opcional sem alterar caminho crítico.
