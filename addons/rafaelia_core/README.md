# RafaelIA Core Addon (Standalone)

Este diretório inicia a estrutura do **núcleo autoral RafaelIA** como addon separado do TinyGPT.

## Objetivo

- Manter o TinyGPT intacto.
- Isolar o núcleo RafaelIA em uma árvore própria.
- Definir contrato de integração mínimo (ABI C).
- Preparar base de documentação técnica, conformidade e licença separada.

## Estrutura

```text
addons/rafaelia_core/
  asm/arm64/           # implementação base em assembler AArch64
  include/             # headers de contrato público
  docs/                # arquitetura e conformidade
  LICENSE-RAFAELIA.txt # licença separada do addon
  NOTICE-RAFAELIA.txt  # aviso de autoria e termos adicionais
```

## Status inicial

- [x] Estrutura de pastas criada
- [x] Header de contrato (`include/rafaelia_contract.h`)
- [x] Esqueleto ARM64 (`asm/arm64/vectra_pulse.S`)
- [x] Documentação inicial
- [x] Licença e notice separados

## Próximos passos sugeridos

1. Adicionar build opcional para o addon sem alterar o fluxo padrão do TinyGPT.
2. Criar testes de sanidade para ABI e invariantes Q16.16.
3. Definir política de auditoria técnica/legal em `docs/COMPLIANCE.md`.
