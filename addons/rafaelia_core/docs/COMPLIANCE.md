# Compliance Matrix (RafaelIA Addon)

Escopo: somente `addons/rafaelia_core/*`.

## Matriz de referência

| Tema | Referência | Aplicação no addon | Evidência atual | Status |
|---|---|---|---|---|
| Gestão de risco em IA | NIST AI RMF | minimizar superfície e falhas sistêmicas | addon isolado + ABI mínima | Em progresso |
| Segurança de arquitetura | NIST SP 800-53 (referência) | integridade de estado interno | estado estático + sem GC no núcleo | Em progresso |
| Qualidade de software | ISO/IEC 25010 | confiabilidade e manutenibilidade | documentação + contrato explícito | Em progresso |
| Governança de IA | ISO/IEC 42001 (referência) | rastreabilidade de ciclo de vida | docs dedicados e escopo definido | Em progresso |
| Privacidade e dados | LGPD/GDPR (referência legal) | controle de uso de dados injetados | sem persistência externa no esqueleto | Em progresso |
| Interoperabilidade | W3C/portabilidade (referência) | integração em pipelines heterogêneos | ABI C estável | Em progresso |
| Direitos autorais | Convenção de Berna / copyright | atribuição e separação de licença | LICENSE + NOTICE no addon | Iniciado |

## Regras técnicas operacionais

1. sem alocação dinâmica no caminho crítico;
2. sem dependência externa no núcleo ASM;
3. sem classes/objetos no núcleo;
4. registrar toda mudança de ABI com versionamento explícito.
