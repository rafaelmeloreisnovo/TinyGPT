# 001_PONTEIRO — TinyGPT inline ARM Assembly (successor path)

- INTENT: new authorial inline ASM backend, not rewriting inherited TinyGPT C++.
- PRODUCER: `rafaelmeloreisnovo/TinyGPT` (main) → additive review PR.
- BASE: GitHub `main@a90696eb380c996d0cf7db3ed3208d9af1f5ecaa` observed 2026-11-07.
- PARENT: merged PR #12 (`a90696eb...`) introduced single-head Q8 attention/microinfer.
- NEW SOURCE: `addons/rafaelia_core/l0/asm_inline/raf_q8_inline_asm.c`.
- CONTRACT: `addons/rafaelia_core/l0/microinfer/raf_microinfer.h`.
- DESIGN & GATES: `addons/rafaelia_core/l0/asm_inline/README.md` → `tests/verify.sh` → `.github/workflows/rafaelia-inline-asm.yml`.
- PROVENANCE: inherited MIT root keith2018; independent MIT RAFAELIA subtree.
- METHOD: A32/Thumb-2 signed LDRSB+MLA and AArch64 signed LDRSB+MADD, with compiler-checked clobbers; same matvec ABI, selected by linking one implementation.
- EVIDENCE: local Clang 17 compilation 9 objects + 3 synthetic ELFs, actual instruction disassembly and no undefined symbols. CI head not yet observed until provider readback.
- GAP: real ARM execution, DSP/NEON performance, physical board boot, GPT parity, external license review = TOKEN_VAZIO/NOT_RUN.
- CONTROL: DRAFT/HOLD, claim_allowed=false, no auto-merge. Rollback by closing draft or reverting additive files. `SOURCE != ARTIFACT != EXECUTION != EVIDENCE != CLAIM`.
