#include <stdint.h>
#include <stdlib.h>
#include "gen/opensbi.h"
#include "gen/u_boot.h" 

static void bootrom_memcpy(void *restrict dest, const void * restrict src, size_t nbytes)
{
   uint8_t *csrc = (uint8_t *)src;
   uint8_t *cdest = (uint8_t *)dest;
   for (size_t i=0; i< nbytes; i++)
       cdest[i] = csrc[i];
}


int main(void) {
        bootrom_memcpy((void*) 0x80000000, (void*) opensbi, opensbi_len);
        bootrom_memcpy((void*) 0x80200000, (void*) u_boot, u_boot_len);

        const uintptr_t entryPoint = 0x80000000;
        const uintptr_t device_tree_ptr = 0x10080;
        asm volatile ("li  a0, 0"); // Hart No
        asm volatile ("li  a1, %0" :: "n" (device_tree_ptr)); // Device Tree
        asm volatile ("fence.i" ::: "memory");
        asm volatile ("jr %0" :: "r" (entryPoint));
}
