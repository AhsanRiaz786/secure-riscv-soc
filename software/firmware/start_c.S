/*
 * Firmware Startup Code
 * Entry point for main application
 */

.section .text.start, "ax"
.globl _start

_start:
    # Initialize stack pointer (already set by bootloader, but ensure)
    lui sp, 0x10001
    
    # Clear BSS section
    la t0, _bss_start
    la t1, _bss_end
clear_bss:
    bge t0, t1, bss_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j clear_bss
    
bss_done:
    # Call main
    call main
    
    # If main returns, halt
halt:
    j halt

.section .bss
.globl _bss_start
.globl _bss_end
_bss_start:
_bss_end:

