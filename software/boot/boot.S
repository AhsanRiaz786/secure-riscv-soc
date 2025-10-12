/*
 * Secure Boot ROM Code
 * This is a minimal bootloader that will eventually verify firmware
 * For now, it just jumps to the main firmware
 */

.section .boot, "ax"
.globl _boot_start

_boot_start:
    # Initialize stack pointer
    lui sp, 0x10001           # Stack at 0x10001000 (within data memory)
    
    # In future: verify firmware signature here
    # For now: directly jump to firmware
    
    # Jump to firmware at 0x00010000
    lui t0, 0x10
    jalr zero, 0(t0)          # Jump to firmware entry point
    
    # Should never reach here
_boot_hang:
    j _boot_hang

