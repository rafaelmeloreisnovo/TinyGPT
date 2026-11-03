#ifndef RAF_L0_GATE_H
#define RAF_L0_GATE_H
/* RAFAELIA L0 v1: caller-owned deterministic transaction gate.
 * C11 freestanding: no libc, heap, syscalls, compiler builtins or global state.
 * Single-owner only; caller supplies two monotonic clock domains and deadlines.
 * Neither a cryptographic integrity check nor an independent hardware watchdog.
 */
typedef unsigned int raf_l0_u32;
_Static_assert(sizeof(raf_l0_u32) == 4, "requires 32-bit unsigned int");

enum { RAF_L0_STAGE=1u, RAF_L0_COMMIT=2u, RAF_L0_ROLLBACK=3u };
enum { RAF_L0_DENY=0u, RAF_L0_STAGED=1u, RAF_L0_COMMITTED=2u,
       RAF_L0_ROLLED_BACK=3u, RAF_L0_FALLBACK=4u,
       RAF_L0_REPLAY=5u, RAF_L0_FAULT=6u };
#define RAF_L0_MAGIC 0x52414631u

typedef struct {
    raf_l0_u32 magic;
    raf_l0_u32 committed;
    raf_l0_u32 complement;
    raf_l0_u32 staged;
    raf_l0_u32 pending;
    raf_l0_u32 sequence;
    raf_l0_u32 clock_a;
    raf_l0_u32 clock_b;
    raf_l0_u32 fault_latched;
} raf_l0_gate;

typedef struct {
    raf_l0_u32 opcode;
    raf_l0_u32 candidate;
    raf_l0_u32 sequence;
    raf_l0_u32 clock_a;
    raf_l0_u32 clock_b;
    raf_l0_u32 budget_a;
    raf_l0_u32 budget_b;
    raf_l0_u32 deadline_a;
    raf_l0_u32 deadline_b;
    raf_l0_u32 allow_fallback;
} raf_l0_request;

typedef struct { raf_l0_u32 status; raf_l0_u32 value; } raf_l0_result;

static inline void raf_l0_init(raf_l0_gate *s, raf_l0_u32 initial)
{
    if (!s) return;
    s->magic = RAF_L0_MAGIC;
    s->committed = initial;
    s->complement = ~initial;
    s->staged = 0u;
    s->pending = 0u;
    s->sequence = 0u;
    s->clock_a = 0u;
    s->clock_b = 0u;
    s->fault_latched = 0u;
}

static inline raf_l0_result raf_l0_apply(raf_l0_gate *s, const raf_l0_request *r)
{
    raf_l0_result out = { RAF_L0_DENY, 0u };
    if (!s || !r) return out;
    if (s->magic != RAF_L0_MAGIC ||
        (s->committed ^ s->complement) != 0xFFFFFFFFu) {
        s->pending = 0u;
        s->fault_latched = 1u;
        out.status = RAF_L0_FAULT;
        return out;
    }
    if (s->fault_latched) { out.status = RAF_L0_FAULT; return out; }
    if (r->sequence == s->sequence) { out.status = RAF_L0_REPLAY; return out; }

    /* A and B must originate from separate trusted clock/heartbeat sources
     * for operational independence. Equality alone is not proof of progress.
     * No wrap-around is admitted: reset explicitly at epoch boundary. */
    if (r->sequence < s->sequence || r->clock_a < s->clock_a ||
        r->clock_b < s->clock_b ||
        r->clock_a - s->clock_a > r->budget_a ||
        r->clock_b - s->clock_b > r->budget_b ||
        r->clock_a > r->deadline_a || r->clock_b > r->deadline_b ||
        r->budget_a == 0u || r->budget_b == 0u) {
        s->pending = 0u;
        s->fault_latched = 1u;
        out.status = RAF_L0_FAULT;
        if (r->allow_fallback == 1u) {
            out.status = RAF_L0_FALLBACK;
            out.value = s->committed; /* last committed snapshot only */
        }
        return out;
    }
    if (r->opcode == RAF_L0_STAGE && s->pending == 0u) {
        s->staged = r->candidate;
        s->pending = 1u;
        out.status = RAF_L0_STAGED;
    } else if (r->opcode == RAF_L0_COMMIT && s->pending == 1u &&
               r->candidate == s->staged) {
        s->committed = s->staged;
        s->complement = ~s->committed;
        s->pending = 0u;
        out.status = RAF_L0_COMMITTED;
        out.value = s->committed;
    } else if (r->opcode == RAF_L0_ROLLBACK) {
        s->pending = 0u;
        out.status = RAF_L0_ROLLED_BACK;
        out.value = s->committed;
    } else {
        /* Reject unauthorized mutation without consuming a sequence. */
        return out;
    }
    s->sequence = r->sequence;
    s->clock_a = r->clock_a;
    s->clock_b = r->clock_b;
    return out;
}
#endif
