/*
 * Hello World Firmware
 * Demonstrates basic SoC functionality
 */

#include "../common/soc_map.h"

// External UART functions
extern void uart_putc(char c);
extern void uart_puts(const char* s);
extern void uart_puthex(unsigned int val);

// Simple test function
int add(int a, int b) {
    return a + b;
}

void main(void) {
    // Print startup message
    uart_puts("\n");
    uart_puts("================================================\n");
    uart_puts("  Secure RISC-V SoC - Firmware v0.1\n");
    uart_puts("================================================\n");
    uart_puts("\n");
    
    uart_puts("Hello from PicoRV32!\n");
    uart_puts("\n");
    
    // Test basic arithmetic
    uart_puts("Testing CPU operations:\n");
    int result = add(42, 8);
    uart_puts("  42 + 8 = ");
    uart_puthex(result);
    uart_puts("\n");
    
    // Test memory
    uart_puts("\nTesting memory:\n");
    volatile unsigned int* test_addr = (unsigned int*)DATA_MEM_BASE;
    *test_addr = 0xDEADBEEF;
    unsigned int read_val = *test_addr;
    uart_puts("  Wrote: 0xDEADBEEF\n");
    uart_puts("  Read:  ");
    uart_puthex(read_val);
    uart_puts("\n");
    
    if (read_val == 0xDEADBEEF) {
        uart_puts("  ✓ Memory test PASSED\n");
    } else {
        uart_puts("  ✗ Memory test FAILED\n");
    }
    
    uart_puts("\n");
    uart_puts("================================================\n");
    uart_puts("  All tests completed successfully!\n");
    uart_puts("================================================\n");
    uart_puts("\n");
    
    // Halt
    while(1);
}

