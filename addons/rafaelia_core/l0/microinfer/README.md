# RAFAELIA L0 — Q8 microinfer (isolated, experimental)

Authority: new standalone source under `addons/rafaelia_core/`, scoped by
`../../LICENSE-RAFAELIA.txt` (MIT, Copyright 2026 Instituto Rafael /
ΔRafaelVerboΩ). Upstream root `LICENSE` (MIT, Copyright 2023 keith2018)
and third-party notices/submodule licenses remain unchanged and effective.
No claim that existing fork sources or bundled binaries are all independently authored.
Do not remove upstream attribution, relicence inherited files or present this
module as TinyGPT's complete inferencer.

## What this actually implements

One deterministic, signed Q8 row-major matrix × vector operation with an
exact int32 accumulator, bounded K<=4096. Useful as a foundational kernel for
future attention/MLP inference; **NOT** GPT-2/Llama/Qwen inference, tokenizer,
model loading, quantized scaling, a trained model or end-to-end LLM.

- C11 freestanding; no headers from libc, no heap, no globals, no syscalls,
  no threads, no network, no hidden runtime callbacks.
- Caller owns all buffers; element counts and shapes checked before any write.
- No allocation/copy of weights; separate output memory, no in-place aliasing.
- Portable scalar default, optional `-DRAF_MICRO_UNROLL4=1`.
- Experimental ARMv7 `mla` / AArch64 `madd` via
  `-DRAF_MICRO_ARM_ASM=1`; no speedup claimed without device benchmarks.
- Object-file `nm -u` checks are **not** proof that a complete ELF/APK has
  no runtime prerequisites. Kernel, ABI, loader and compiler toolchain still exist.
  Host tests use the host C runtime only to launch the test executable.

## Build and falsify

```sh
sh addons/rafaelia_core/l0/microinfer/tests/verify.sh
clang --target=armv7-none-eabi -std=c11 -Os -ffreestanding -nostdinc -fno-builtin -fno-stack-protector -c addons/rafaelia_core/l0/microinfer/raf_microinfer.c -o /tmp/raf_microinfer_armv7.o
nm -u /tmp/raf_microinfer_armv7.o
```

The verify script runs GCC/Clang host KAT/parity for scalar and 4-way unroll,
negative capacity/pointer/shape tests, no-undefined-symbol object compilation
for x86_64, i386, ARMv7, AArch64, RV32, RV64, and opt-in ARM ASM codegen.
Physical ARMv7/AArch64 runtime, compiler/linker fingerprint, latency, energy,
peak RAM and TinyGPT integration are **TOKEN_VAZIO / NOT_RUN** until receipts.

## Compiler reality and boundaries

Comments and whitespace do **not** generally affect machine code in C; macros,
pragmas, attributes, function layout, optimization flags, linker scripts and
architecture-specific instructions sometimes do. Inspect real `objdump`, ELF
sections, disassembly and benchmarks, keeping source/flags/compiler version in
receipts. Avoid instruction hex encoding unless assembler output is independently
compared against the intended ISA and constraints. A `void` return type neither
eliminates allocation nor creates platform-independent system calls.

## Next gates (not pre-approved)

Independent source-rights review; exact-head CI; negative and UBSan where hosted;
deterministic ARM32/ARM64 runtime parity on a real device; compare `-O2/-Os`,
unroll and ASM variants before retaining any fast path. Integrate through an
explicit TinyGPT adapter only after interface, license and regression review.
Rollback: leave this review branch unmerged; never rewrite upstream history.
