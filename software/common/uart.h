/*
 * UART Helper Functions - Header
 */

#ifndef UART_H
#define UART_H

void uart_putc(char c);
void uart_puts(const char* s);
void uart_puthex(unsigned int val);

#endif // UART_H


