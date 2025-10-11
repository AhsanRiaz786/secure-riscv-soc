    .section .text
    .globl _start
_start:
    addi x1, x0, 10   # x1 = 10
    addi x2, x0, 20   # x2 = 20
    add  x3, x1, x2   # x3 = x1 + x2
    # loop forever to stop PC moving (optional)
1:  jal x0, 1b
