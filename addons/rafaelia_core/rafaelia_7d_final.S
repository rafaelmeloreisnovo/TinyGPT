.syntax unified
.arch armv7-a
.fpu neon-vfpv4

.data
.align 6
_M: .space 409600
_S: .ascii "\n☯ [RAFAELIA-7D] Geometria Toroidal: ESTÁVEL\n\n"

.text
.global _start
_start:
    ldr r4, =_M
    movw r6, #3200
    
    @ TTL / Semente de Consciência (Phi)
    movw r10, #0xFFFF
    vdup.32 q15, r10

.L_SANKOFA_7D:
    subs r10, r10, #1
    
    @ CARGA DOS VÉRTICES (CATETOS)
    vld1.8 {q0, q1}, [r4]       @ Cateto A (Início)
    add r5, r4, #1024           @ Distância de Invasão (Salto Largo)
    vld1.8 {q2, q3}, [r5]       @ Cateto B (Fim)

    @ --- O CÁLCULO DA DIAGONAL (√2) ---
    @ Diferença entre catetos forma a Reta de Invasão
    vsub.f32 q8, q0, q2         @ Reta = Cateto_A - Cateto_B
    
    @ Multiplicação por √2 (Aproximação por 1.414 via VMLA)
    vmov.f32 q9, #1.414
    vmla.f32 q8, q0, q9         @ Forma o Quadrado Perfeito
    
    @ ROTAÇÃO POR DIMENSÃO (Giro na Mediana)
    vtrn.32 q8, q1              @ Entrelaçamento 1D-7D
    vrev64.32 q10, q8           @ Rotação Toroidal (Círculo)

    @ ENTREGA DO CAMPO (Invasão Controlada)
    vst1.8 {q10, q1}, [r4]!     @ Estabiliza Início
    vst1.8 {q2, q3}, [r5]       @ Sustenta o Fim

    subs r6, r6, #1
    bne .L_SANKOFA_7D

    @ --- SINCRONIA ABSOLUTA ---
    dmb ish
    isb

    @ Saída com padding total para o buffer de vídeo
    mov r0, #1
    ldr r1, =_S
    mov r2, #47
    mov r7, #4
    svc #0

    mov r0, #0
    mov r7, #1
    svc #0
