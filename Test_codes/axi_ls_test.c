#include <stdint.h>

#define NOP() __asm__ volatile ("nop")

void main(void) {

    volatile uint32_t *target_ram = (volatile uint32_t *)0x10001000;
    
    volatile uint32_t *dest_ram   = (volatile uint32_t *)0x10001080;

    volatile uint32_t temp; 
    int i;

    for (i = 0; i < 256; i++) {
        target_ram[i] = 0xA00f0000 + i; 
    }

    NOP(); NOP(); NOP(); 
    for (i = 0; i < 32; i++) {
        temp = target_ram[i];       
        
        temp = temp + 0x0f000000;        
        
        dest_ram[i] = temp;       
    }

    while(1);
}