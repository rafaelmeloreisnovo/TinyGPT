# TinyGPT RAFAELIA L0 — freestanding causal attention, bounded Q8

**Scope:** an independent, authorial experimental C11 component that reuses the
existing `../microinfer/raf_microinfer.c`. It performs **one causal single-head
attention decode step** with four Q8 projections (Q/K/V/O) and caller-owned
incremental KV cache. This is *not* a complete GPT, chat model, tokenizer,
checkpoint reader, Transformer block, training system or proof of model parity.

## Boundary and rights

- Original TinyGPT C++ and third-party submodules remain untouched. Root
  `LICENSE` is MIT, © 2023 keith2018. This scoped addition uses
  `../../LICENSE-RAFAELIA.txt`, MIT, © 2026 Instituto Rafael / ΔRafaelVerboΩ.
- No libc, libm, standard C headers, heap/malloc, syscalls, global mutable
  state, dynamic memory, C++ classes, framework or OS callback in the target.
- Compiler/linker, ABI, startup code, stack, device RAM map, model weights and
  I/O remain separate concerns. Synthetic ARM32/ARM64 ELF link does **not**
  prove boot on a physical board or execution on Android.
- Host test launcher/shell/Clang/GCC/LLD are **development tools**, not target
  runtime dependencies.

## Verified-contract implementation

- Accepted vector dimensions: **16 or 64**; cache **1–128 tokens**; one head.
- Each caller-supplied weight matrix is Q8 signed row-major `dim × dim` with
  scale `1/128`; signed accumulation in int32 and saturation to Q8.
- `score_q12 = dot(q,k)/[4 sqrt(dim)]` with exact sqrt for 16/64;
  approximate LUT `exp(-Δ)` sampled in steps of 0.25 and integer normalization.
  It is **not bit-exact full-precision softmax**.
- Stable causal decode: future tokens are not visible. Cache and output commit
  only after all preflight checks/projections. Error leaves committed cache and
  output untouched. Scratch workspace may change during a failed computation.
- Written/read-only buffers must obey the non-overlap contract in the header;
  bounds are element counts, not bytes. No concurrency support.
- The existing `microinfer` preflight multiplication guard is made explicitly
  64-bit to remove host compiler-runtime `__aeabi_uidiv` from ARM32 objects,
  without permitting product overflow.

## Falsification / build

```sh
sh addons/rafaelia_core/l0/microinfer/tests/verify.sh
sh addons/rafaelia_core/l0/decoder_q8/tests/verify.sh
```

Tests: host GCC/Clang × `-O0/-O2/-Os`, ASan/UBSan, capacity/state/pointer
rejects, KV commit and deterministic attention KATs, max 128-token sequence,
6 cross target objects (`x86_64`, `i386`, `ARMv7`, `AArch64`, `RV32`, `RV64`)
and ARM32/ARM64 LLD synthetic bare-metal ELF **LINK_ONLY** checks (no
undefined imports or program interpreter). Compiler availability is required
for the checks; `nm -u` on objects permits only explicit in-repo matvec call.

## Non-claims and gates

`SOURCE ≠ ARTIFACT ≠ EXECUTION ≠ EVIDENCE ≠ CLAIM`.

| Stage | Current evidence | Next gate |
| --- | --- | --- |
| Q8 attention host | Local tests scoped | Exact GitHub head CI + independent review |
| ISA object cross-compile | Six object targets | Real instruction/parity/device evidence |
| ELF ARM32/ARM64 | Synthetic LINK_ONLY | Board startup/stack/memory map/boot |
| Motorola E7 Power ARMv7 | NOT_RUN / TOKEN_VAZIO | Measured E2E through an authorized adapter |
| GPT-2/Llama/Qwen model inference | NOT_IMPLEMENTED | Tokenizer, embeddings, RMSNorm/MLP, layer stack, loader, parity |
| General-purpose memory safety | Not demonstrated | Adversarial fuzz and alias contract checks |

**Rollback:** keep this change in a DRAFT PR; close or revert its scoped diff
without rewriting history. Do not merge/ship or advertise a complete
freestanding TinyGPT based only on this module's CI.
