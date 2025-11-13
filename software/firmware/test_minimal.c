/*
 * Minimal Test - Just print a few characters
 */

#include "../common/soc_map.h"

// Simple inline UART - no busy wait for now
void simple_uart_putc(char c) {
    volatile unsigned int* uart_tx = (unsigned int*)0x20000000;
    *uart_tx = c;
    
    // Wait a bit (simple delay)
    for (volatile int i = 0; i < 10000; i++);
}

void main(void) {
    simple_uart_putc('H');
    simple_uart_putc('e');
    simple_uart_putc('l');
    simple_uart_putc('l');
    simple_uart_putc('o');
    simple_uart_putc('!');
    simple_uart_putc('\n');
    
    // Halt
    while(1);
}

