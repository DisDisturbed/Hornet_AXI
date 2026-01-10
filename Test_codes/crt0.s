/* start.S */
.section .text.init
.global _start

_start:
    /* ------------------------------------------------- */
    /* 1. Initialize Stack Pointer                       */
    /* ------------------------------------------------- */
    /* Sets SP to the top of the Main RAM (defined in linker) */
    la sp, __stack_top

    /* Optional: Clear Frame Pointer (s0) for debugging  */
    add s0, sp, zero

    /* ------------------------------------------------- */
    /* 2. Jump to C Code                                 */
    /* ------------------------------------------------- */
    jal ra, main

    /* ------------------------------------------------- */
    /* 3. Trap Loop                                      */
    /* ------------------------------------------------- */
    /* If main() returns, spin here to prevent crashing. */
1:  j 1b