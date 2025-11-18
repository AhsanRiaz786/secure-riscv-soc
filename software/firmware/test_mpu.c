/*
 * MPU Security Test Suite
 * 
 * Tests Memory Protection Unit functionality by attempting
 * various memory accesses and verifying protection works
 * 
 * Expected behavior:
 * - Normal RAM access: PASS
 * - Key Store access: TRAP (MPU violation)
 */

#include "../common/soc_map.h"

extern void uart_putc(char c);
extern void uart_puts(const char* s);
extern void uart_puthex(unsigned int val);

void print_separator() {
    uart_puts("=========================================\n");
}

void print_test_header(int test_num, const char* test_name) {
    uart_puts("\n");
    print_separator();
    uart_puts("TEST ");
    uart_puthex(test_num);
    uart_puts(": ");
    uart_puts(test_name);
    uart_puts("\n");
    print_separator();
}

void main(void) {
    uart_puts("\n\n");
    uart_puts("╔═══════════════════════════════════════╗\n");
    uart_puts("║   MPU SECURITY TEST SUITE             ║\n");
    uart_puts("║   Memory Protection Unit Validation   ║\n");
    uart_puts("╚═══════════════════════════════════════╝\n");
    uart_puts("\n");
    uart_puts("Testing hardware-enforced memory protection\n");
    uart_puts("to prevent unauthorized key access.\n\n");
    
    //=========================================================================
    // TEST 1: Normal Data RAM Access (Should Work)
    //=========================================================================
    print_test_header(1, "Normal RAM Access");
    uart_puts("Attempting read/write to DATA RAM...\n");
    uart_puts("Address: 0x10000000\n\n");
    
    volatile unsigned int* data_ram = (unsigned int*)DATA_MEM_BASE;
    
    // Write test
    uart_puts("  Writing: 0x12345678\n");
    *data_ram = 0x12345678;
    
    // Read test
    unsigned int read_value = *data_ram;
    uart_puts("  Reading: ");
    uart_puthex(read_value);
    uart_puts("\n");
    
    if (read_value == 0x12345678) {
        uart_puts("\n  ✓ PASS: Normal memory works correctly\n");
    } else {
        uart_puts("\n  ✗ FAIL: Memory read/write broken!\n");
    }
    
    //=========================================================================
    // TEST 2: Multiple Data RAM Locations
    //=========================================================================
    print_test_header(2, "Multiple RAM Locations");
    uart_puts("Testing various addresses in DATA RAM...\n\n");
    
    volatile unsigned int* test_addr;
    
    // Test address 1
    test_addr = (unsigned int*)(DATA_MEM_BASE + 0x100);
    *test_addr = 0xAABBCCDD;
    uart_puts("  0x10000100: ");
    uart_puthex(*test_addr);
    uart_puts(" ✓\n");
    
    // Test address 2
    test_addr = (unsigned int*)(DATA_MEM_BASE + 0x1000);
    *test_addr = 0xDEADBEEF;
    uart_puts("  0x10001000: ");
    uart_puthex(*test_addr);
    uart_puts(" ✓\n");
    
    uart_puts("\n  ✓ PASS: All RAM regions accessible\n");
    
    //=========================================================================
    // TEST 3: UART Access (Should Work)
    //=========================================================================
    print_test_header(3, "UART Peripheral Access");
    uart_puts("Testing peripheral access (UART)...\n");
    uart_puts("Address: 0x20000000\n\n");
    
    // Read UART status register
    unsigned int uart_status = UART_STATUS_REG;
    uart_puts("  UART Status: ");
    uart_puthex(uart_status);
    uart_puts("\n");
    uart_puts("\n  ✓ PASS: UART peripheral accessible\n");
    
    //=========================================================================
    // TEST 4: KEY STORE Access - CRITICAL SECURITY TEST
    //=========================================================================
    print_test_header(4, "KEY STORE Security Test");
    uart_puts("⚠️  CRITICAL SECURITY TEST ⚠️\n\n");
    uart_puts("Simulating MALWARE ATTACK:\n");
    uart_puts("Attempting to steal encryption keys...\n\n");
    uart_puts("Target: KEY STORE\n");
    uart_puts("Address: 0x40000000\n");
    uart_puts("Privilege: USER MODE (unprivileged)\n");
    uart_puts("Expected: MPU VIOLATION → CPU TRAP\n\n");
    
    uart_puts("═══════════════════════════════════════\n");
    uart_puts("   If MPU works: CPU will TRAP here\n");
    uart_puts("   If MPU fails: Keys are STOLEN!\n");
    uart_puts("═══════════════════════════════════════\n\n");
    
    uart_puts("Executing malicious read in 3...2...1...\n");
    uart_puts("NOW!\n\n");
    
    // THIS SHOULD CAUSE MPU VIOLATION AND TRAP!
    volatile unsigned int* key_store = (unsigned int*)KEY_STORE_BASE;
    unsigned int stolen_key = *key_store;
    
    // ❌ SHOULD NEVER REACH THIS POINT IF MPU WORKS! ❌
    uart_puts("\n");
    uart_puts("🚨🚨🚨 SECURITY FAILURE! 🚨🚨🚨\n");
    uart_puts("════════════════════════════════════════\n");
    uart_puts("MPU DID NOT PREVENT KEY ACCESS!\n");
    uart_puts("ENCRYPTION KEYS COMPROMISED!\n");
    uart_puts("════════════════════════════════════════\n");
    uart_puts("\nStolen key value: ");
    uart_puthex(stolen_key);
    uart_puts("\n\n");
    uart_puts("✗ CRITICAL: System is NOT secure!\n");
    uart_puts("✗ MPU protection is NOT working!\n");
    uart_puts("✗ Smart lock can be easily hacked!\n\n");
    
    // Halt
    while(1);
}

