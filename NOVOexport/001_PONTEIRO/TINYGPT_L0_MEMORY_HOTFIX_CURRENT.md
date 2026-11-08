# 001_PONTEIRO — TinyGPT L0 memória segura: hotfix incremental

- INTENT: eliminar caminhos de corrupção silenciosa em Q8 scalar/ARM inline, sem redesenhar o TinyGPT herdado.
- AUTHORITY: produtor `rafaelmeloreisnovo/TinyGPT`, baseline `main@c11ac574ec29c528e0af14f2e3688ef31ef3c6ad`.
- PRECEDENT: TinyGPT PR#13 MERGED, não tratar como DRAFT atual; copyright e MIT herdado preservados.
- SOURCE: `addons/rafaelia_core/l0/microinfer/raf_microinfer.c` + `../asm_inline/raf_q8_inline_asm.c`.
- SINGLE GUARD: `addons/rafaelia_core/l0/microinfer/raf_micro_preflight.h` (C11 freestanding, header-only).
- ABI: códigos 0..3 inalterados, `RAF_MICRO_BAD_ALIAS=4`, `RAF_MICRO_BAD_ALIGNMENT=5`; mesma assinatura exportada.
- INVARIANT: validação antes da primeira escrita, contagens em elementos, multiplicação alargada, intervalo de endereço não pode transbordar, saída não pode sobrepor input/pesos, saída int32 deve alinhar em 4 bytes.
- TESTS: `addons/rafaelia_core/l0/microinfer/tests/test_preflight.c`, `tests/verify.sh`, `addons/rafaelia_core/l0/asm_inline/tests/verify.sh`, `addons/rafaelia_core/l0/decoder_q8/tests/verify.sh`.
- EVIDENCE LOCAL: GCC/Clang x O0/O2/Os host, 2000 vetores de matvec, casos negativos, ASan/UBSan; Clang ARMv7 A32/Thumb-2/AArch64 9 objetos, no imports; GitHub exact-head CI precisa ser observada separadamente.
- SCOPE: mudanças apenas nos dois backends Q8, contrato, guard, teste e docs; não tocar C++/submódulos/terceiros.
- NONCLAIMS: o guard não pode provar que o endereço é mapeado nem o buffer efetivamente alocado, não detecta races, use-after-free em chamador, leak do C++ ou no hardware. Sem malloc local -> sem vazamento por alocação do próprio módulo; isso não garante segurança integral.
- PRIORITY: P0 integridade e não escrita em erro. P1 revisar manualmente ponteiros e vida útil do decodificador; P1 gates hardware e desempenho A/B; P2 deduplicar peso de atenção após teste numérico.
- GOVERNANCE: SOURCE ≠ ARTIFACT ≠ EXECUTION ≠ EVIDENCE ≠ CLAIM; merge/release/claim_allowed=false até CI, revisão e teste de runtime. Rollback: fechar PR não mesclada, ou PR de reversão com aprovação se mesclada.
