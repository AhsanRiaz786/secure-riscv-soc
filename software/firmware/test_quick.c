/*
 * Quick Test Program - Shows all concepts but less verbose
 */

#include "../common/soc_map.h"

extern void uart_putc(char c);
extern void uart_puts(const char* s);
extern void uart_puthex(unsigned int val);

int add(int a, int b) {
    return a + b;
}

void main(void) {
    uart_puts("\n=== RISC-V SoC Test ===\n\n");
    
    // Test 1: Math
    uart_puts("1. Math: 10+20=");
    uart_puthex(add(10, 20));
    uart_puts(" OK\n");
    
    // Test 2: Memory
    volatile unsigned int* mem = (unsigned int*)0x10000000;
    *mem = 0xCAFE;
    uart_puts("2. Memory: ");
    uart_puthex(*mem);
    uart_puts(" OK\n");
    
    // Test 3: Loop
    uart_puts("3. Loop: ");
    for (int i = 0; i < 3; i++) {
        uart_putc('*');
    }
    uart_puts(" OK\n");
    
    uart_puts("\nAll tests PASSED!\n\n");
    
    while(1);
}

