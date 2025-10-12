/*
 * Simple Test Firmware - No UART
 * Just tests basic CPU and memory operations
 */

void main(void) {
    // Test arithmetic
    volatile int a = 10;
    volatile int b = 20;
    volatile int c = a + b;  // Should be 30
    
    // Test memory writes
    volatile unsigned int* mem = (unsigned int*)0x10000100;
    *mem = 0xDEADBEEF;
    
    // Read it back
    volatile unsigned int val = *mem;
    
    // Simple loop
    for (int i = 0; i < 10; i++) {
        c += i;
    }
    
    // Halt forever
    while(1) {
        // Do nothing - successful execution
    }
}

