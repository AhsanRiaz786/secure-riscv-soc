# Firmware Startup Code
# Sets up the environment and calls main()

.section .text.start, "ax"
.globl _start

_start:
    # Set up stack pointer (end of RAM)
    lui sp, 0x10010
    
    # Clear .bss section (if needed)
    # For now, skip this as we don't have much BSS
    
    # Call main function
    call main
    
    # If main returns, halt
halt:
    j halt

