# Minimal assembly test - no C, no stack
# Just test basic CPU operation

.section .text.start, "ax"
.globl _start

_start:
    # Test ADD
    addi x1, x0, 10
    addi x2, x0, 20
    add x3, x1, x2          # x3 = 30
    
    # Test memory write to data region
    lui x4, 0x10000         # x4 = 0x10000000
    sw x3, 0(x4)            # Store 30 to 0x10000000
    
    # Test memory read
    lw x5, 0(x4)            # x5 should be 30
    
    # Test branch
    beq x3, x5, success
    
failure:
    # If we get here, test failed
    addi x10, x0, -1        # -1 = failure
    j halt
    
success:
    # Test passed
    addi x10, x0, 42        # 42 = success
    
halt:
    # Infinite loop
    j halt

