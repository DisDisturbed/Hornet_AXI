/* link.ld */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    /* * Corresponds to u_main_ram (Slave 0) 
     * Base: 0x0000_0000
     * Size: 32KB (Adjust if your Verilog ADDR_WIDTH is larger)
     */
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00008000
}

SECTIONS
{
    /* ------------------------------------------------------------------ */
    /* 1. Text Section (Code)                                             */
    /* ------------------------------------------------------------------ */
    .text :
    {
        /* CRITICAL: Put the startup code at the very beginning (0x0) */    
        KEEP(*(.text.init))
        
        /* Then the rest of the code */
        *(.text)
        *(.text.*)
    } > RAM

    /* ------------------------------------------------------------------ */
    /* 2. Read-Only Data (Constants, Strings)                             */
    /* ------------------------------------------------------------------ */
    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)
        *(.rodata.*)
        . = ALIGN(4);
    } > RAM

    /* ------------------------------------------------------------------ */
    /* 3. Initialized Data (Global variables with values)                 */
    /* ------------------------------------------------------------------ */
    .data :
    {
        . = ALIGN(4);
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
        . = ALIGN(4);
    } > RAM

    /* ------------------------------------------------------------------ */
    /* 4. Uninitialized Data (BSS)                                        */
    /* ------------------------------------------------------------------ */
    .bss :
    {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM

    /* ------------------------------------------------------------------ */
    /* 5. Stack Definition                                                */
    /* ------------------------------------------------------------------ */
    /* Place stack at the very end of the RAM region */
    . = ALIGN(16);
    __stack_top = ORIGIN(RAM) + LENGTH(RAM);
}