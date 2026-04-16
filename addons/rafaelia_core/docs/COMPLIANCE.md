# Compliance Matrix (RafaelIA Addon)

> Documento inicial de rastreabilidade técnica e legal para o addon.

## Escopo

Este documento cobre apenas `addons/rafaelia_core/*`.

## Matriz de referência

| Tema | Referência | Objetivo | Evidência inicial | Status |
|---|---|---|---|---|
| Gestão de risco em IA | NIST AI RMF | Mapear e mitigar risco operacional | Estrutura modular e isolada | Em progresso |
| Segurança de sistemas | NIST SP 800-53 (referência) | Controles de segurança e rastreabilidade | API mínima e superfície reduzida | Em progresso |
| Qualidade de software | ISO/IEC 25010 | Manutenibilidade e confiabilidade | Camadas documentadas e contrato explícito | Em progresso |
| Governança IA | ISO/IEC 42001 (referência) | Diretrizes de gestão de ciclo de vida | Documentação dedicada do addon | Em progresso |
| Privacidade e dados | LGPD/GDPR (referência legal) | Uso responsável de dados pessoais | Sem coleta ativa no esqueleto inicial | Em progresso |
| Interoperabilidade web | W3C (referência) | Padrões de integração e portabilidade | ABI C para acoplamentos diversos | Em progresso |
| Direitos autorais | Convenção de Berna / copyright | Preservação de autoria e condições de uso | LICENSE + NOTICE separados | Iniciado |

## Princípios operacionais iniciais

1. **Separação**: código autoral fora do core TinyGPT.
2. **Minimização**: contrato mínimo e explícito.
3. **Rastreabilidade**: documentação e termos no próprio addon.
4. **Evolução segura**: mudanças incrementais com testes e revisão.
