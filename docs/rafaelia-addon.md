# RafaelIA Addon (integração inicial)

Este documento descreve a entrada do núcleo RafaelIA como addon separado no repositório.

## Premissas aplicadas

- TinyGPT permanece funcional sem depender do addon.
- O addon é opcional no build (`TINYGPT_BUILD_RAFAELIA_ADDON`).
- O núcleo é isolado em `addons/rafaelia_core` com ABI C própria.

## Entregas desta etapa

- estrutura de diretórios dedicada para ASM/headers/docs;
- núcleo ARM64 com estado estático e operações determinísticas;
- contrato ABI ampliado com leitura de estado (`vectra_pulse_read`);
- CMake do addon para compilação isolada;
- documentação de arquitetura/compliance e licença separada.

## Build

```bash
cmake -S . -B build -DTINYGPT_BUILD_RAFAELIA_ADDON=ON
cmake --build build -j
```

> Em arquiteturas sem AArch64, o addon é ignorado sem quebrar o build geral.
