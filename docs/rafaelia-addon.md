# RafaelIA Addon (Início)

Este documento marca o início da documentação do núcleo autoral RafaelIA dentro do repositório, mantendo separação do TinyGPT.

## Diretriz principal

- **TinyGPT permanece sem alterações estruturais internas para o addon**.
- O addon vive em `addons/rafaelia_core` com documentação e licença próprias.

## Entregas iniciais

- Estrutura de diretórios para ASM, headers e docs.
- Contrato ABI mínimo (`rafaelia_contract.h`).
- Esqueleto AArch64 (`vectra_pulse.S`).
- Arquivos de licença/notice separados.
- Matriz inicial de compliance.

## Próxima etapa sugerida

1. Criar build opcional do addon.
2. Adicionar testes de contrato.
3. Conectar chamada do addon via ponte opcional sem acoplamento rígido.
