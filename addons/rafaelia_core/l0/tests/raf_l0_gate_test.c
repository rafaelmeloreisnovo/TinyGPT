#include "raf_l0_gate.h"
#define CHECK(expr) do { if (!(expr)) return __LINE__; } while (0)
static raf_l0_request req(unsigned op, unsigned seq, unsigned ta, unsigned tb)
{
    raf_l0_request r = {0};
    r.opcode=op; r.sequence=seq; r.clock_a=ta; r.clock_b=tb;
    r.budget_a=4u; r.budget_b=4u; r.deadline_a=100u; r.deadline_b=100u;
    return r;
}
int main(void)
{
    raf_l0_gate s; raf_l0_request r; raf_l0_result x;
    raf_l0_init(&s, 7u);
    CHECK(s.committed==7u && s.pending==0u && s.fault_latched==0u);
    r=req(RAF_L0_STAGE, 1u, 1u, 1u); r.candidate=42u;
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_STAGED);
    CHECK(s.committed==7u && s.pending==1u);
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_REPLAY);
    CHECK(s.committed==7u && s.sequence==1u);
    r=req(RAF_L0_COMMIT, 2u, 2u, 2u); r.candidate=41u;
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_DENY);
    CHECK(s.sequence==1u && s.pending==1u);
    r.candidate=42u; x=raf_l0_apply(&s,&r);
    CHECK(x.status==RAF_L0_COMMITTED && x.value==42u);
    CHECK(s.committed==42u && s.pending==0u);
    r=req(RAF_L0_STAGE,3u,3u,3u); r.candidate=99u;
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_STAGED);
    r=req(RAF_L0_STAGE,4u,4u,4u); r.candidate=99u;
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_DENY);
    r.opcode=RAF_L0_ROLLBACK;
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_ROLLED_BACK);
    CHECK(s.committed==42u && s.pending==0u);
    r=req(RAF_L0_STAGE,5u,10u,5u); r.allow_fallback=1u;
    x=raf_l0_apply(&s,&r);
    CHECK(x.status==RAF_L0_FALLBACK && x.value==42u);
    CHECK(s.fault_latched==1u && s.committed==42u);
    r=req(RAF_L0_STAGE,6u,11u,6u);
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_FAULT);
    raf_l0_init(&s,13u);
    r=req(RAF_L0_STAGE,1u,1u,7u); r.allow_fallback=0u;
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_FAULT);
    CHECK(s.committed==13u && s.fault_latched==1u);
    raf_l0_init(&s,13u);
    r=req(RAF_L0_STAGE,1u,1u,1u); r.deadline_a=0u;
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_FAULT);
    raf_l0_init(&s,13u);
    r=req(RAF_L0_STAGE,1u,1u,1u); r.budget_b=0u;
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_FAULT);
    raf_l0_init(&s,13u);
    r=req(RAF_L0_STAGE,1u,1u,1u); r.deadline_b=0u;
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_FAULT);
    raf_l0_init(&s,13u);
    r=req(RAF_L0_STAGE,1u,1u,1u); r.opcode=999u;
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_DENY && s.sequence==0u);
    raf_l0_init(&s,13u);
    s.complement ^= 1u;
    r=req(RAF_L0_STAGE,1u,1u,1u); r.allow_fallback=1u;
    x=raf_l0_apply(&s,&r);
    CHECK(x.status==RAF_L0_FAULT && x.value==0u);
    CHECK(s.pending==0u);
    raf_l0_init(&s,13u);
    r=req(RAF_L0_STAGE,1u,1u,1u);
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_STAGED);
    r=req(RAF_L0_ROLLBACK,1u,1u,1u);
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_REPLAY);
    r=req(RAF_L0_ROLLBACK,2u,2u,2u);
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_ROLLED_BACK);
    r=req(RAF_L0_COMMIT,3u,3u,3u);
    CHECK(raf_l0_apply(&s,&r).status==RAF_L0_DENY);
    r=req(RAF_L0_STAGE,3u,3u,3u);
    CHECK(raf_l0_apply((raf_l0_gate*)0,&r).status==RAF_L0_DENY);
    CHECK(raf_l0_apply(&s,(raf_l0_request*)0).status==RAF_L0_DENY);
    /* Deterministic repeated independent traces: no hidden/global state. */
    for (unsigned i=0; i<10000u; ++i) {
        raf_l0_gate a,b;
        raf_l0_init(&a,i); raf_l0_init(&b,i);
        r=req(RAF_L0_STAGE,1u,1u,1u); r.candidate=i^0x5A5A5A5Au;
        CHECK(raf_l0_apply(&a,&r).status==raf_l0_apply(&b,&r).status);
        r=req(RAF_L0_COMMIT,2u,2u,2u); r.candidate=i^0x5A5A5A5Au;
        CHECK(raf_l0_apply(&a,&r).status==RAF_L0_COMMITTED);
        CHECK(raf_l0_apply(&b,&r).status==RAF_L0_COMMITTED);
        CHECK(a.committed==(i^0x5A5A5A5Au) && a.committed==b.committed && a.pending==b.pending);
    }
    return 0;
}
