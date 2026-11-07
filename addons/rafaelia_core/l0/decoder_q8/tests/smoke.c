/* SPDX-License-Identifier: MIT; ELF link probe only, not bootable board firmware. */
#include "../raf_decoder_q8.h"
static raf_q8 weights[16u*16u], keys[16u], values[16u], x[16u], y[16u];
static raf_dec_q8_scratch scratch;
static raf_dec_q8_model model = {weights,weights,weights,weights,16u*16u,16u};
static raf_dec_q8_cache cache = {keys,values,16u,1u,0u};
static volatile int result;
void raf_dec_q8_entry(void)
{
    result=raf_dec_q8_step(&model,&cache,&scratch,x,16u,y,16u);
    for (;;) { __asm__ volatile("" ::: "memory"); }
}
