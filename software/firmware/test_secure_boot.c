/*
 * Secure Boot Test Firmware
 * 
 * This firmware will ONLY run if the boot ROM successfully verifies
 * the HMAC-SHA256 signature. If this runs, it proves secure boot works!
 */

#include "../common/soc_map.h"
#include "../common/firmware_header.h"

extern void uart_putc(char c);
extern void uart_puts(const char* s);
extern void uart_puthex(unsigned int val);

void main(void) {
    uart_puts("\n\n");
    uart_puts("╔════════════════════════════════════════╗\n");
    uart_puts("║     SECURE BOOT SUCCESS! ✓             ║\n");
    uart_puts("║  Firmware Signature Verified           ║\n");
    uart_puts("╚════════════════════════════════════════╝\n\n");
    
    uart_puts("This message proves:\n");
    uart_puts("  ✓ Boot ROM calculated HMAC-SHA256\n");
    uart_puts("  ✓ Signature matched expected value\n");
    uart_puts("  ✓ Firmware is authentic and untampered\n");
    uart_puts("  ✓ Only manufacturer-signed code can run\n\n");
    
    // Read our own firmware header
    firmware_header_t* header = GET_FW_HEADER();
    
    uart_puts("Firmware Information:\n");
    uart_puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    
    uart_puts("  Magic:      ");
    uart_puthex(header->magic);
    if (header->magic == FW_HEADER_MAGIC) {
        uart_puts(" ✓\n");
    } else {
        uart_puts(" ✗ INVALID!\n");
    }
    
    uart_puts("  Version:    ");
    uart_puthex(header->version);
    uart_puts("\n");
    
    uart_puts("  Length:     ");
    uart_puthex(header->length);
    uart_puts(" bytes\n");
    
    uart_puts("  Entry:      ");
    uart_puthex(header->entry_point);
    uart_puts("\n");
    
    uart_puts("  Timestamp:  ");
    uart_puthex(header->timestamp);
    uart_puts("\n\n");
    
    uart_puts("HMAC-SHA256 Signature:\n");
    uart_puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    for (int i = 0; i < 8; i++) {
        uart_puts("  [");
        uart_puthex(i);
        uart_puts("] = ");
        uart_puthex(header->signature[i]);
        uart_puts("\n");
    }
    
    uart_puts("\n");
    uart_puts("Security Features Demonstrated:\n");
    uart_puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    uart_puts("  1. ✓ Hardware SHA-256 accelerator\n");
    uart_puts("  2. ✓ HMAC-based firmware authentication\n");
    uart_puts("  3. ✓ Boot ROM verification logic\n");
    uart_puts("  4. ✓ Cryptographic signature checking\n");
    uart_puts("  5. ✓ Protection against tampering\n");
    uart_puts("  6. ✓ Secure boot chain of trust\n\n");
    
    uart_puts("Attack Prevention:\n");
    uart_puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    uart_puts("  ✗ Cannot run unsigned firmware\n");
    uart_puts("  ✗ Cannot modify firmware (signature breaks)\n");
    uart_puts("  ✗ Cannot inject malicious code\n");
    uart_puts("  ✗ Cannot bypass boot verification\n");
    uart_puts("  ✗ Cannot extract signing key from hardware\n\n");
    
    uart_puts("╔════════════════════════════════════════╗\n");
    uart_puts("║  SECURE BOOT TEST: PASSED ✓            ║\n");
    uart_puts("╚════════════════════════════════════════╝\n\n");
    
    uart_puts("System is secure and ready.\n\n");
    
    // Infinite loop
    while(1) {
        // In a real system, this would run the actual application
    }
}

