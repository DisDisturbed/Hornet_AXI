#include <stdint.h>


void main(void) {
    volatile uint32_t *mem_ptr = (volatile uint32_t *)0x9000;

    // Force NOPs to let the pipeline flush register a4
    asm volatile ("nop");
    asm volatile ("nop");
    asm volatile ("nop"); 

    for (int i = 0; i < 28; i++) {
        mem_ptr[i] = (i + 1) * 0x10; 
    }
    
    while(1);
}