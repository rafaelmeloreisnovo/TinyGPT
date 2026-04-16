#include <stdio.h>
#include <stdint.h>
#include <string.h>

#ifdef ARCH64
extern void neon_ergodic_mix_arm64(uint8_t *buffer, uint64_t len);
#else
extern void neon_ergodic_mix_arm32(uint8_t *buffer, uint32_t len);
#endif

int main() {
    uint8_t memory_pool[64];
    memset(memory_pool, 0xAA, 64);

    printf("--- RAFAELIA SIMD TEST (%s) ---\n", 
#ifdef ARCH64
    "ARM64"
#else
    "ARM32"
#endif
    );

    printf("Original: 0x%02X\n", memory_pool[0]);

#ifdef ARCH64
    neon_ergodic_mix_arm64(memory_pool, 64);
#else
    neon_ergodic_mix_arm32(memory_pool, 64);
#endif

    printf("Processed: 0x%02X\n", memory_pool[0]);
    if (memory_pool[0] == 0xFF) printf("✅ SUCESSO!\n");
    return 0;
}
