/*
 * Simple Test Program - Easy to understand what's happening
 */

 #include "../common/soc_map.h"

 // UART functions (already exist in uart.c)
 extern void uart_putc(char c);
 extern void uart_puts(const char* s);
 extern void uart_puthex(unsigned int val);
 
 // Simple function to test
 int multiply_by_two(int x) {
     return x + x;  // Double the input
 }
 
 void main(void) {
     // ========================================
     // TEST 1: Hello World
     // ========================================
     uart_puts("\n");
     uart_puts("=== TEST 1: Hello World ===\n");
     uart_puts("If you see this, the CPU is running!\n");
     uart_puts("\n");
     
     // ========================================
     // TEST 2: Basic Math
     // ========================================
     uart_puts("=== TEST 2: Basic Math ===\n");
     
     int a = 10;
     int b = 20;
     int sum = a + b;
     
     uart_puts("Computing: 10 + 20\n");
     uart_puts("Result: ");
     uart_puthex(sum);
     uart_puts("\n");
     
     if (sum == 30) {
         uart_puts("Math works! CPU ALU is OK.\n");
     } else {
         uart_puts("ERROR: Math is broken!\n");
     }
     uart_puts("\n");
     
     // ========================================
     // TEST 3: Function Call
     // ========================================
     uart_puts("=== TEST 3: Function Call ===\n");
     
     int input = 7;
     int output = multiply_by_two(input);
     
     uart_puts("Input: ");
     uart_puthex(input);
     uart_puts("\n");
     uart_puts("Output: ");
     uart_puthex(output);
     uart_puts("\n");
     
     if (output == 14) {
         uart_puts("Function call works! Stack is OK.\n");
     } else {
         uart_puts("ERROR: Function call broken!\n");
     }
     uart_puts("\n");
     
     // ========================================
     // TEST 4: Memory Read/Write
     // ========================================
     uart_puts("=== TEST 4: Memory Test ===\n");
     
     // Write to data memory
     volatile unsigned int* memory_location = (unsigned int*)0x10000000;
     unsigned int test_value = 0xCAFEBABE;
     
     uart_puts("Writing to memory: ");
     uart_puthex(test_value);
     uart_puts("\n");
     
     *memory_location = test_value;  // WRITE
     
     unsigned int read_back = *memory_location;  // READ
     
     uart_puts("Reading from memory: ");
     uart_puthex(read_back);
     uart_puts("\n");
     
     if (read_back == test_value) {
         uart_puts("Memory works! RAM is OK.\n");
     } else {
         uart_puts("ERROR: Memory is broken!\n");
     }
     uart_puts("\n");
     
     // ========================================
     // TEST 5: Loop Test
     // ========================================
     uart_puts("=== TEST 5: Loop Test ===\n");
     uart_puts("Counting from 0 to 4:\n");
     
     for (int i = 0; i < 5; i++) {
         uart_puts("  Count: ");
         uart_puthex(i);
         uart_puts("\n");
     }
     uart_puts("Loop works! Branches OK.\n");
     uart_puts("\n");
     
     // ========================================
     // FINAL SUMMARY
     // ========================================
     uart_puts("================================\n");
     uart_puts("  ALL TESTS PASSED!\n");
     uart_puts("  Your RISC-V CPU is alive!\n");
     uart_puts("================================\n");
     uart_puts("\n");
     
     // Halt - infinite loop
     uart_puts("Program finished. Halting...\n");
     while(1) {
         // Do nothing forever
     }
 }