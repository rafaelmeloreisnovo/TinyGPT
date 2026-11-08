# RAFAELIA Ω / TinyGPT L0 — inline Assembly autoral

**Status:** experimental / freestanding codegen + link-only gate; not an E2E GPT or a physical bare-metal boot.

## Scope, provenance, copyright

- New standalone C11/inline-Assembly Q8 matrix-vector backend in this directory;
  MIT © 2026 Instituto Rafael / ΔRafaelVerboΩ, see `../../LICENSE-RAFAELIA.txt`.
- Inherited TinyGPT code, root MIT © 2023 keith2018 and third-party notices retain
  their original licenses and history; no third-party ASM is copied here.
- Model-data conversion, tokenizer, training, numeric GPT parity and physical hardware
  execution **not implemented**.

## Methodology: compiler as verified orchestrator, not implicit runtime

1. **Contract first.** Use the same exported
   `raf_micro_q8_matvec(out,out_count,weights,weight_count,input,input_count,rows,cols)`
   signature and return codes in `../microinfer/raf_microinfer.h`.
2. **Fail-closed backend choice.** Build either the original portable
   `../microinfer/raf_microinfer.c` or **this** `raf_q8_inline_asm.c` as the sole
   definition of `raf_micro_q8_matvec`. Never link both. Unsupported ISA yields a
   compile-time error, not a silent software fallback.
3. **Explicit ISA and registers.** The C compiler owns AAPCS/AAPCS64 calling
   convention, prologue, stack and register allocation. The authored inline loop
   loads signed Q8 bytes using `LDRSB`, accumulates with `MLA` (ARMv7-A/Thumb-2)
   or `MADD` (AArch64), updates two pointers, decrements a 32-bit iteration count
   and branches. `+r`, early-clobber `=&r`, `cc` and `memory` tell the optimizer
   what can change. This is ordinary integer ISA, not a SIMD/NEON claim.
4. **Math bound.** `cols∈[1,4096]`, signed inputs in `[-128,127]`; maximum
   `abs(sum)≤4096×128²=67,108,864`, so signed 32-bit accumulation does not
   overflow. `rows×cols` is widened before the capacity comparison. Counts are
   in elements, not bytes; all required bounds are checked before any output.
5. **Fail-closed span safety.** Both scalar and ASM backends now call
   `../microinfer/raf_micro_preflight.h` before the first output write:
   reject output/input or output/weight overlap, misaligned int32 output,
   address-range wrap, missing capacity, null pointers or invalid shape.
   Only the active read/write extents are checked. The caller still proves
   allocation validity, region ownership, lifetime, data races and MMIO safety;
   numeric pointer checks alone are not memory-safe capabilities.
6. **No target runtime dependency.** No libc, libm, heap, malloc, syscalls,
   global writable state, C++ standard library, OS, broker or runtime imports.
   The compiler/linker are **build-time** tooling; physical boot still requires
   board-specific startup/stack/memory map and an authorized I/O adapter.
7. **Observable proof gates.** Compile `A32`, `Thumb-2`, `AArch64` under
   `O0/O2/Os`, inspect decoded ISA with `llvm-objdump`, reject unresolved
   symbols via `nm -u`, and link synthetic ELFs with no PT_INTERP/DYNAMIC.
   A synthetic ELF without an OS is not proof it boots or runs on a board.
8. **A/B regression path.** Keep the original scalar backend intact. Both
   backend objects export the same function; select one through the link DAG,
   run the existing scalar functional suite and independently execute the ASM
   version on real ARM hardware before asserting numerical parity.

## Build and falsification

Run from the repository root:

```sh
sh addons/rafaelia_core/l0/asm_inline/tests/verify.sh
```

Manual example, Motorola E7 Power compatible A32 instruction set (codegen only):

```sh
clang --target=armv7a-none-eabi -march=armv7-a -marm -std=c11 -Os \
  -Wall -Wextra -Werror -ffreestanding -fno-builtin -fno-stack-protector \
  -nostdinc -c addons/rafaelia_core/l0/asm_inline/raf_q8_inline_asm.c \
  -o /tmp/raf_q8_inline_armv7.o
nm -u /tmp/raf_q8_inline_armv7.o
llvm-objdump -d /tmp/raf_q8_inline_armv7.o
```

To link the existing decoder with the authorial inline ASM backend, replace
`../microinfer/raf_microinfer.c` in its link inputs with the file above;
`../decoder_q8/raf_decoder_q8.c` does not need to change. The test script
performs this link for all three ARM build modes and rejects undefined imports.

## Remaining gates

| Layer | Current condition | Required falsifier |
| --- | --- | --- |
| Host functional scalar reference | Existing separate tests | Keep unchanged and green |
| A32 / Thumb-2 / A64 | Assembled and ELF LINK_ONLY | Compare same inputs/outputs on ARM runtime |
| Motorola E7 Power / Android 10 | NOT_RUN | Install/execute through a separate, audited Android ABI adapter |
| Bare-metal board | NOT_RUN | Board-specific reset, entrypoint, SP, RAM/MMIO and memory isolation |
| GPT inference | NOT_IMPLEMENTED | Models, layers, tokenization and checkpoint parity |
| Performance/energy | TOKEN_VAZIO | Reproducible per-device benchmark vs scalar |

`SOURCE ≠ ARTIFACT ≠ EXECUTION ≠ EVIDENCE ≠ CLAIM`.
Do not infer an entire freestanding TinyGPT from one inline ASM backend.
Rollback for merged PR #13 requires an independently reviewed successor revert;
for the separate span-preflight hotfix PR, close the unmerged review or revert only its scoped diff;
no upstream relicensing or destructive rewrite is required.
