/*
 * Linker Script for Firmware
 * Places firmware at 0x00010000
 */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    flash (rx)  : ORIGIN = 0x00010000, LENGTH = 64K
    ram (rwx)   : ORIGIN = 0x10000000, LENGTH = 64K
}

SECTIONS
{
    .text : {
        *(.text.start)
        *(.text*)
    } > flash
    
    .rodata : {
        *(.rodata*)
    } > flash
    
    .data : {
        *(.data*)
    } > ram AT > flash
    
    .bss : {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > ram
    
    . = ALIGN(4);
    _stack_top = ORIGIN(ram) + LENGTH(ram);
}

