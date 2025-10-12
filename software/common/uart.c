/*
 * Simple UART Driver
 */

#include "soc_map.h"

void uart_putc(char c) {
    // Wait if TX is busy
    while (UART_STATUS_REG & UART_TX_BUSY);
    
    // Send character
    UART_TX_REG = c;
}

void uart_puts(const char* s) {
    while (*s) {
        if (*s == '\n') {
            uart_putc('\r');  // Add carriage return for newline
        }
        uart_putc(*s++);
    }
}

void uart_puthex(unsigned int val) {
    const char hex[] = "0123456789ABCDEF";
    uart_puts("0x");
    for (int i = 28; i >= 0; i -= 4) {
        uart_putc(hex[(val >> i) & 0xF]);
    }
}

