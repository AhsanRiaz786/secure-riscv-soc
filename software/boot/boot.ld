/*
 * Linker Script for Boot ROM
 * Places bootloader code at 0x00000000
 */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    rom (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
}

SECTIONS
{
    .text : {
        *(.text)
        *(.text*)
    } > rom
    
    .rodata : {
        *(.rodata*)
    } > rom
    
    /DISCARD/ : {
        *(.data*)
        *(.bss*)
        *(.comment)
        *(.note*)
    }
}

