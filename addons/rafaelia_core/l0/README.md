# RAFAELIA L0 — bounded transaction gate and falsifiers

Scope: authorial code beneath `addons/rafaelia_core/`, separate from the TinyGPT C++/third-party runtime. The original MIT attribution in the repository root and individual submodule licenses remain intact. This addition neither rebrands nor replaces upstream code.

## Operating contract

`raf_l0_gate.h` is C11 freestanding with caller-owned 36-byte state, no libc, heap, syscalls, classes, C++, global writable state, compiler intrinsics or hidden threads. The only operations are **STAGE → COMMIT** and **ROLLBACK**; a rejected operation does not consume its sequence number. Non-repeatable effects belong to a separate host adapter, never inside this arithmetic gate.

Two **logical** watchdog predicates use distinct, caller-supplied clocks with their own progress budgets and absolute deadlines. Faults cancel staged work, latch denial and preserve the previously committed value; an explicitly authorized fallback can return that value if its bitwise-complement guard is intact. A mismatch of the guard blocks even the fallback.

**Limits:** This complement guard is not cryptography, ECC or tamper protection. Both clock sources must be separately verified; feeding both from one counter does not create two independent watchdogs. This gate is single-owner and not safe for concurrent writers. Any 32-bit clock/sequence wrap requires explicit authority-controlled reinitialization, which also clears the fault latch. Failover to a second *independent* process, device or engine is **NOT_IMPLEMENTED** and must not be inferred from the fallback.

### Falsification gates

Run from the repository root:

```sh
sh addons/rafaelia_core/l0/tests/verify.sh
```

Host assertions cover commit/rollback/aborted pending work, replay and wrong-value rejection, both clocks and both deadlines, corrupt committed state, authorized fallback, unknown opcode and **10,000 reproducible pairs of independent state traces**. Clang emits objects for x86-64, x86-32, ARMv7, AArch64, RV32 and RV64 under `-nostdinc -ffreestanding`, checking for undefined symbols. The existing Vectra AArch64 module is also assembled and checked for external unresolved symbols. The full C++ TinyGPT inferencer is outside the scope of this test.

### AArch64 hotfix

`asm/arm64/vectra_pulse.S` now rejects `NULL + len>0` as a no-op and calculates `phase=(previous_phase+original_len%42)%42` using the original uint32 input length instead of bits from an unrelated accumulator. The ABI entrypoints stay unchanged. **AArch64 instruction assembly is not the same as a runtime proof**; native Android and QEMU execution remain TOKEN_VAZIO until a separately accepted execution receipt exists.

### Capability routing, no invented speedups

| Layer | Permitted path | Boundary |
| --- | --- | --- |
| L0 | Freestanding scalar C11 / verified AArch64 ASM | No OS, libc, allocator, implicit ownership |
| ELF | Explicit Linux/Android native-loader adapter | OS/ABI/loader still exist outside L0 |
| DEX / ART | Only a necessary Android managed entrypoint | No Java classes are added by this hotfix |
| NUMA | Probe and select only on real multi-node hosts | No NUMA performance claim on mobile SoCs |
| Fail-safe | Deny + cancel uncommitted stage | Staged data never promoted on fault |
| Fallback | Previous committed snapshot, explicit permission | Not a redundant process or hardware failover |
| Failover | Separate independently validated provider needed | BLOCKED / NOT_IMPLEMENTED |

`Agente.md` contains illustrative AArch64 instructions rather than a verified executable; executable source for this hotfix is the actual Vectra `.S` file above.

Evidence promotion is strictly scoped: SOURCE != ARTIFACT != EXECUTION != EVIDENCE != CLAIM. The root `LICENSE` and `addons/rafaelia_core/NOTICE-RAFAELIA.txt` remain authoritative for their respective attributions. Rollback is closing an unmerged review PR, keeping the parent SHA and evidence receipts.
