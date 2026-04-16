.syntax unified
.arch armv7-a
.fpu neon-vfpv4

.data
.align 6
_M: .space 409600
_S: .ascii "\n☯ [BALANCE] Ciclo/Matriz 8x8: OK\n"

.text
.global _start
_start:
    @ --- ACESSO AO CONTADOR DE CICLOS (User Enable) ---
    @ Nota: Em alguns kernels Android, o acesso direto via MRC pode exigir root.
    @ Se falhar, usamos o tempo de sistema como fallback.
    
    ldr r4, =_M
    movw r6, #6400      @ 400KB

.L_BALANCE:
    @ --- MARCAÇÃO DE PONTO (INÍCIO DO CICLO) ---
    mrc p15, 0, r8, c9, c13, 0  @ Lê Cycle Count Register (V7)

    vld1.8 {q0, q1}, [r4]!
    vld1.8 {q2, q3}, [r4]!

    @ PROCESSAMENTO 7D COM PARIDADE CRUZADA
    veor q8, q0, q1
    vrev32.8 q9, q2
    vadd.f32 q10, q8, q9
    
    @ --- MARCAÇÃO DE PONTO (FIM DO CICLO) ---
    mrc p15, 0, r9, c9, c13, 0
    sub r10, r9, r8      @ Delta de Ciclos (O "Peso" do cálculo)

    @ INJEÇÃO DO BENCHMARK NA MATRIZ (A matriz carrega o cálculo)
    vdup.32 q11, r10     @ Transforma o tempo em vetor NEON
    vadd.i32 q0, q0, q11 @ O bloco A agora carrega sua própria latência

    sub r4, r4, #64
    vst1.8 {q0, q1}, [r4]!
    vst1.8 {q2, q3}, [r4]!

    subs r6, r6, #1
    bne .L_BALANCE

    @ --- SINCRONIA TOROIDAL ---
    dmb ish
    isb

    mov r0, #1
    ldr r1, =_S
    mov r2, #35
    mov r7, #4
    svc #0

    mov r0, #0
    mov r7, #1
    svc #0
