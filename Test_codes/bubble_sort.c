#include <stdint.h>

#define SORT_RAM_BASE   ((volatile uint32_t *)0x10001000)

// Inline assembly for NOP delays
#define NOP() __asm__ volatile ("nop")
#define DELAY_10() do { NOP(); NOP(); NOP(); NOP(); NOP(); NOP(); NOP(); NOP(); NOP(); NOP(); } while(0)

void main(void) {
    volatile uint32_t *ram = SORT_RAM_BASE;
    int i, j;
    uint32_t val1, val2;
    ram[0] = 0xDEADBEEF;  
    DELAY_10();
    ram[0] = 45; 
    ram[1] = 12; 
    ram[2] = 89; 
    ram[3] = 2;  
    ram[4] = 7;
    ram[5] = 63; 
    ram[6] = 15; 
    ram[7] = 99; 
    ram[8] = 31; 
    ram[9] = 20;
    
    DELAY_10();

    for (i = 0; i < 9; i++) {
        for (j = 0; j < 9 - i; j++) {
            
            val1 = ram[j];
            val2 = ram[j+1];

            if (val1 > val2) {
                ram[j]   = val2;
                ram[j+1] = val1;
            }
        }
    }
    ram[19] = 0xAAAAAAAA; 
    DELAY_10();
    DELAY_10();
    for (i = 0; i < 10; i++) {
        uint32_t sorted_val = ram[i]; 
        ram[20 + i] = sorted_val; 
    }
    
    ram[30] = 0x5555AAAA;  
    
    while(1) {
        NOP();
    }
}

/* 
 * EXPECTED RESULTS in RAM after sorting:
 * 
 * ram[0-9]   = Sorted array: 2, 7, 12, 15, 20, 31, 45, 63, 89, 99
 * ram[19]    = 0xAAAAAAAA (flush marker)
 * ram[20-29] = Copy of sorted array: 2, 7, 12, 15, 20, 31, 45, 63, 89, 99  
 * ram[30]    = 0x5555AAAA (completion marker)
 *
 * In your waveform, check:
 * 1. ram[19] should be 0xAAAAAAAA
 * 2. ram[20] should be 0x00000002 (2)
 * 3. ram[21] should be 0x00000007 (7)
 * 4. ram[22] should be 0x0000000C (12)
 * 5. ram[23] should be 0x0000000F (15)
 * 6. ram[24] should be 0x00000014 (20)
 * 7. ram[25] should be 0x0000001F (31)
 * 8. ram[26] should be 0x0000002D (45)
 * 9. ram[27] should be 0x0000003F (63)
 * 10. ram[28] should be 0x00000059 (89)
 * 11. ram[29] should be 0x00000063 (99)
 * 12. ram[30] should be 0x5555AAAA
 */