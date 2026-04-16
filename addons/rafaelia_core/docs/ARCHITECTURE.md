# Arquitetura Inicial do Addon RafaelIA

## 1) Princípio de separação

O addon RafaelIA é mantido fora do núcleo do TinyGPT para garantir:

- independência autoral;
- evolução técnica desacoplada;
- licenciamento separado;
- integração opcional por interface estável.

## 2) Camadas

### Camada A — ABI pública

Arquivo: `include/rafaelia_contract.h`

Define quatro pontos de entrada estáveis:

1. `vectra_pulse_init(seed)`
2. `vectra_pulse_step(c_in_q16, h_in_q16)`
3. `vectra_pulse_collapse()`
4. `vectra_pulse_inject(data, len)`

### Camada B — Núcleo de execução (ASM ARM64)

Arquivo: `asm/arm64/vectra_pulse.S`

Objetivo:

- permitir execução determinística de baixa latência;
- manter controle explícito sobre registradores e layout de dados;
- abrir caminho para otimizações de cache, prefetch e SIMD.

### Camada C — Governança técnica

Arquivo: `docs/COMPLIANCE.md`

Mantém matriz de conformidade para segurança, privacidade, qualidade e rastreabilidade.

## 3) Estratégia de integração (sem quebra)

- O TinyGPT permanece intacto.
- A integração ocorre por ponte C/ABI (FFI), opcional.
- O addon pode ser compilado e testado de forma isolada.

## 4) Roadmap curto

1. Implementar estado interno Q16.16 e invariantes.
2. Adicionar testes de contrato ABI e sanidade numérica.
3. Criar benchmark de latência/cache para rotinas críticas.
4. Integrar build opcional (feature flag), sem alterar execução padrão.
