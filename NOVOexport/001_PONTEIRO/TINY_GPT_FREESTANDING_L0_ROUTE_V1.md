# 001_PONTEIRO — TinyGPT RAFAELIA freestanding decoder L0

- PRODUCER: `rafaelmeloreisnovo/TinyGPT`, branch `rafcode/tinygpt-freestanding-attn-q8-20261107`.
- BASE: `main@368e1a603baf39b053c402e2699d275e66e10128` (observed 2026-11-07).
- SOURCE: original MIT TinyGPT; additive MIT RAFAELIA under `addons/rafaelia_core/`.
- ROUTE: `README.md` (inherited C++ context) → `addons/rafaelia_core/l0/microinfer/README.md` → `addons/rafaelia_core/l0/decoder_q8/README.md` → `.github/workflows/rafaelia-decoder-q8.yml`.
- EVIDENCE: local host parity/negatives/sanitizers + 6 ISA compile + 2 ELF LINK_ONLY. GitHub CI exact-HEAD = TOKEN_VAZIO until observed.
- DELTA: new bounded single-head Q8 causal attention step + compiler-rt division hotfix for existing Q8 preflight. No C++ TinyGPT integration or platform bootstrap.
- BLOCKED: full model loader/tokenizer/embedding/layer stack; device boot/Android; real model outputs; independent code/rights review; rollout.
- AUTHORITY: source implementation GitHub producer; Drive only append-only continuity receipt after external write readback.
- ROLLBACK: DRAFT HOLD, original main unchanged; no deletion/relicensing/auto-merge.
- CLAIM: IMPLEMENTED_TESTED_LOCAL_SCOPED; full GPT/bare-metal hardware claim_allowed=false.
