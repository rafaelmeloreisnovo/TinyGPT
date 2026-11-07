/* SPDX-License-Identifier: MIT; deterministic host test harness, no libc. */
#include "../raf_decoder_q8.h"
static raf_q8 wq[64u*64u], wk[64u*64u], wv[64u*64u], wo[64u*64u];
static raf_q8 keys[128u*64u], values[128u*64u];
static raf_dec_q8_scratch work;
static raf_q8 x[64], y[64];

static void clear_buffers(void)
{
    unsigned i;
    for (i=0;i<64u*64u;++i) wq[i]=wk[i]=wv[i]=wo[i]=0;
    for (i=0;i<128u*64u;++i) keys[i]=values[i]=(raf_q8)55;
    for (i=0;i<64u;++i) x[i]=0,y[i]=(raf_q8)99;
}

int main(void)
{
    unsigned i;
    raf_dec_q8_model m = {wq,wk,wv,wo,64u*64u,16u};
    raf_dec_q8_cache c = {keys,values,128u*64u,3u,0u};
    clear_buffers();
    for (i=0u;i<16u;++i) {wv[i*16u+i]=127; wo[i*16u+i]=127;}
    x[0]=64;
    if (raf_dec_q8_step(&m,&c,&work,x,16u,y,16u) != RAF_DEC_Q8_OK ||
        c.used!=1u || y[0]!=62 || values[0]!=63 || keys[0]!=0) return 1;
    x[0]=0;
    if (raf_dec_q8_step(&m,&c,&work,x,16u,y,16u) != RAF_DEC_Q8_OK ||
        c.used!=2u || y[0]!=30) return 2;
    x[0]=-64;
    if (raf_dec_q8_step(&m,&c,&work,x,16u,y,16u) != RAF_DEC_Q8_OK ||
        c.used!=3u || y[0]!=0) return 3;
    y[0]=42;
    if (raf_dec_q8_step(&m,&c,&work,x,16u,y,16u) != RAF_DEC_Q8_BAD_CAPACITY ||
        c.used!=3u || y[0]!=42) return 4;
    c.used=4u;
    if (raf_dec_q8_step(&m,&c,&work,x,16u,y,16u) != RAF_DEC_Q8_BAD_STATE ||
        c.used!=4u || y[0]!=42) return 5;
    c.used=0u; c.slots=3u;
    m.dim=17u;
    if (raf_dec_q8_step(&m,&c,&work,x,64u,y,64u) != RAF_DEC_Q8_BAD_SHAPE ||
        y[0]!=42) return 6;
    m.dim=64u;
    c.slots=128u; c.elements=128u*64u;
    clear_buffers();
    for (i=0u;i<64u;++i) {wv[i*64u+i]=127;wo[i*64u+i]=127;}
    x[0]=64;
    if (raf_dec_q8_step(&m,&c,&work,x,64u,y,64u) != RAF_DEC_Q8_OK ||
        c.used!=1u || y[0]!=62) return 7;
    c.used=0u;
    y[0]=44;
    c.elements=64u;
    if (raf_dec_q8_step(&m,&c,&work,x,64u,y,64u) != RAF_DEC_Q8_BAD_CAPACITY ||
        c.used!=0u || y[0]!=44 || keys[0]!=0) return 8;
    c.elements=128u*64u;
    if (raf_dec_q8_step(&m,&c,&work,x,63u,y,64u) != RAF_DEC_Q8_BAD_CAPACITY ||
        y[0]!=44) return 9;
    if (raf_dec_q8_step(&m,&c,&work,x,64u,(raf_q8*)0,64u) != RAF_DEC_Q8_BAD_POINTER)
        return 10;
    m.weight_elements=64u;
    if (raf_dec_q8_step(&m,&c,&work,x,64u,y,64u) != RAF_DEC_Q8_BAD_CAPACITY ||
        y[0]!=44) return 11;
    /* Extreme scores: different Q/K sign must strongly select current token. */
    clear_buffers(); m.dim=16u; m.weight_elements=16u*16u;
    c.slots=2u; c.elements=128u*64u; c.used=0u;
    for (i=0u;i<16u;++i) {
        wq[i*16u+i]=wk[i*16u+i]=wv[i*16u+i]=wo[i*16u+i]=127;
    }
    for (i=0u;i<16u;++i) x[i]=127;
    if (raf_dec_q8_step(&m,&c,&work,x,16u,y,16u)!=RAF_DEC_Q8_OK) return 12;
    for (i=0u;i<16u;++i) x[i]=-128;
    if (raf_dec_q8_step(&m,&c,&work,x,16u,y,16u)!=RAF_DEC_Q8_OK ||
        y[0] > -100) return 13;
    /* Capacity maximum: Q8 -128 accumulation over 128 tokens remains bounded. */
    clear_buffers(); m.dim=64u; m.weight_elements=64u*64u;
    c.slots=128u; c.elements=128u*64u; c.used=0u;
    for (i=0u;i<64u;++i) {wv[i*64u+i]=127;wo[i*64u+i]=127;x[i]=-128;}
    for (i=0u;i<128u;++i) {
        if (raf_dec_q8_step(&m,&c,&work,x,64u,y,64u)!=RAF_DEC_Q8_OK ||
            c.used!=i+1u || y[0]!=-126) return 14;
    }
    if (raf_dec_q8_step(&m,&c,&work,x,64u,y,64u)!=RAF_DEC_Q8_BAD_CAPACITY ||
        c.used!=128u) return 15;
    return 0;
}
