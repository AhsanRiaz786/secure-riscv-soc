/*
 * Secure Boot ROM
 * 
 * This boot ROM verifies the firmware HMAC-SHA256 signature before execution.
 * If verification fails, the system halts and refuses to boot.
 * 
 * Process:
 * 1. Load HMAC key from KEY_STORE (0x40000000)
 * 2. Configure crypto accelerator for HMAC-SHA256
 * 3. Point to firmware region and calculate HMAC
 * 4. Wait for crypto to finish
 * 5. Read calculated HMAC from crypto registers
 * 6. Compare with expected signature in firmware header
 * 7. If match: jump to firmware
 *    If no match: print error and halt
 */

.section .text, "ax"
.globl _start

// Memory map constants
.equ UART_BASE,       0x20000000
.equ CRYPTO_BASE,     0x30000000
.equ KEY_STORE_BASE,  0x40000000
.equ FIRMWARE_BASE,   0x00010000
.equ FW_HEADER_OFFSET, 0xFFC0

// Crypto registers
.equ CRYPTO_CTRL,     0x00
.equ CRYPTO_STATUS,   0x04
.equ CRYPTO_MODE,     0x08
.equ CRYPTO_MSG_ADDR, 0x0C
.equ CRYPTO_MSG_LEN,  0x10
.equ CRYPTO_KEY_BASE, 0x14    // Keys at 0x14-0x30
.equ CRYPTO_HASH_BASE, 0x40   // Hash output at 0x40-0x5C

// Control/status bits
.equ CTRL_START, 0x01
.equ MODE_HMAC,  0x01
.equ STATUS_DONE, 0x02

_start:
    //=================================================================
    // Print Boot Message
    //=================================================================
    li   a0, UART_BASE
    
    // Print "\nSECURE BOOT\n"
    li   a1, '\n'
    sb   a1, 0(a0)
    li   a1, 'S'
    sb   a1, 0(a0)
    li   a1, 'E'
    sb   a1, 0(a0)
    li   a1, 'C'
    sb   a1, 0(a0)
    li   a1, 'U'
    sb   a1, 0(a0)
    li   a1, 'R'
    sb   a1, 0(a0)
    li   a1, 'E'
    sb   a1, 0(a0)
    li   a1, ' '
    sb   a1, 0(a0)
    li   a1, 'B'
    sb   a1, 0(a0)
    li   a1, 'O'
    sb   a1, 0(a0)
    li   a1, 'O'
    sb   a1, 0(a0)
    li   a1, 'T'
    sb   a1, 0(a0)
    li   a1, '\n'
    sb   a1, 0(a0)
    
    //=================================================================
    // Step 1: Load HMAC key from KEY_STORE
    //=================================================================
    // Key = 0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF
    // We'll hardcode this key for now (in production, burn into OTP/eFuse)
    // Key words (little-endian): 
    li   s0, 0x67452301
    li   s1, 0xEFCDAB89
    li   s2, 0x98BADCFE
    li   s3, 0x10325476
    li   s4, 0x67452301
    li   s5, 0xEFCDAB89
    li   s6, 0x98BADCFE
    li   s7, 0x10325476
    
    //=================================================================
    // Step 2: Write key to crypto accelerator
    //=================================================================
    li   t0, CRYPTO_BASE
    
    // Write all 8 key words
    sw   s0, 0x14(t0)    // KEY_0
    sw   s1, 0x18(t0)    // KEY_1
    sw   s2, 0x1C(t0)    // KEY_2
    sw   s3, 0x20(t0)    // KEY_3
    sw   s4, 0x24(t0)    // KEY_4
    sw   s5, 0x28(t0)    // KEY_5
    sw   s6, 0x2C(t0)    // KEY_6
    sw   s7, 0x30(t0)    // KEY_7
    
    //=================================================================
    // Step 3: Configure HMAC operation
    //=================================================================
    // Message address = firmware start
    li   t1, FIRMWARE_BASE
    sw   t1, CRYPTO_MSG_ADDR(t0)
    
    // Message length = up to header (0xFFC0 bytes)
    li   t1, FW_HEADER_OFFSET
    sw   t1, CRYPTO_MSG_LEN(t0)
    
    // Set mode to HMAC-SHA256
    li   t1, MODE_HMAC
    sw   t1, CRYPTO_MODE(t0)
    
    //=================================================================
    // Step 4: Start HMAC calculation
    //=================================================================
    li   t1, CTRL_START
    sw   t1, CRYPTO_CTRL(t0)
    
    // Print "Verifying...\n"
    li   a0, UART_BASE
    li   a1, 'V'
    sb   a1, 0(a0)
    li   a1, 'e'
    sb   a1, 0(a0)
    li   a1, 'r'
    sb   a1, 0(a0)
    li   a1, 'i'
    sb   a1, 0(a0)
    li   a1, 'f'
    sb   a1, 0(a0)
    li   a1, 'y'
    sb   a1, 0(a0)
    li   a1, 'i'
    sb   a1, 0(a0)
    li   a1, 'n'
    sb   a1, 0(a0)
    li   a1, 'g'
    sb   a1, 0(a0)
    li   a1, '.'
    sb   a1, 0(a0)
    li   a1, '.'
    sb   a1, 0(a0)
    li   a1, '.'
    sb   a1, 0(a0)
    li   a1, '\n'
    sb   a1, 0(a0)
    
    //=================================================================
    // Step 5: Wait for crypto to finish
    //=================================================================
verify_wait:
    lw   t1, CRYPTO_STATUS(t0)
    andi t1, t1, STATUS_DONE
    beqz t1, verify_wait
    
    //=================================================================
    // Step 6: Read calculated HMAC
    // Note: Hash registers are at word addresses 0x10-0x17 (byte offsets 0x40-0x5C)
    // But we access via byte addresses, so use 0x40, 0x44, etc.
    // The soc_top will convert to word addresses automatically
    lw   a0, 0x40(t0)    // HASH_0 (word addr 0x10)
    lw   a1, 0x44(t0)    // HASH_1 (word addr 0x11)
    lw   a2, 0x48(t0)    // HASH_2 (word addr 0x12)
    lw   a3, 0x4C(t0)    // HASH_3 (word addr 0x13)
    lw   a4, 0x50(t0)    // HASH_4 (word addr 0x14)
    lw   a5, 0x54(t0)    // HASH_5 (word addr 0x15)
    lw   a6, 0x58(t0)    // HASH_6 (word addr 0x16)
    lw   a7, 0x5C(t0)    // HASH_7 (word addr 0x17)
    
    //=================================================================
    // Step 7: Load expected signature from firmware header
    //=================================================================
    li   t0, FIRMWARE_BASE
    li   t1, FW_HEADER_OFFSET
    add  t0, t0, t1      // t0 = header address
    
    // Check magic first (0xDEADBEEF)
    lw   t2, 0(t0)
    li   t3, 0xDEADBEEF
    bne  t2, t3, boot_fail_magic
    
    // Load expected signature (starts at offset 0x20 in header)
    lw   t2, 0x20(t0)    // Expected HASH_0
    lw   t3, 0x24(t0)    // Expected HASH_1
    lw   t4, 0x28(t0)    // Expected HASH_2
    lw   t5, 0x2C(t0)    // Expected HASH_3
    lw   t6, 0x30(t0)    // Expected HASH_4
    lw   s8, 0x34(t0)    // Expected HASH_5
    lw   s9, 0x38(t0)    // Expected HASH_6
    lw   s10, 0x3C(t0)   // Expected HASH_7
    
    //=================================================================
    // Step 8: Compare all 8 words of signature
    //=================================================================
    bne  a0, t2, boot_fail_sig
    bne  a1, t3, boot_fail_sig
    bne  a2, t4, boot_fail_sig
    bne  a3, t5, boot_fail_sig
    bne  a4, t6, boot_fail_sig
    bne  a5, s8, boot_fail_sig
    bne  a6, s9, boot_fail_sig
    bne  a7, s10, boot_fail_sig
    
    //=================================================================
    // SUCCESS! Signature matches - Boot firmware
    //=================================================================
    // Print "OK\n"
    li   a0, UART_BASE
    li   a1, 'O'
    sb   a1, 0(a0)
    li   a1, 'K'
    sb   a1, 0(a0)
    li   a1, '\n'
    sb   a1, 0(a0)
    
    // Jump to firmware entry point (0x00010000)
    // Load firmware base address and jump immediately
    lui  t0, 0x00010        // Load upper 20 bits: 0x00010000
    addi t0, t0, 0          // Complete: 0x00010000
    jr   t0                 // Jump to firmware

//=================================================================
// FAILURE HANDLERS
//=================================================================
boot_fail_magic:
    // Print "BAD MAGIC\n"
    li   a0, UART_BASE
    li   a1, 'B'
    sb   a1, 0(a0)
    li   a1, 'A'
    sb   a1, 0(a0)
    li   a1, 'D'
    sb   a1, 0(a0)
    li   a1, ' '
    sb   a1, 0(a0)
    li   a1, 'M'
    sb   a1, 0(a0)
    li   a1, 'A'
    sb   a1, 0(a0)
    li   a1, 'G'
    sb   a1, 0(a0)
    li   a1, 'I'
    sb   a1, 0(a0)
    li   a1, 'C'
    sb   a1, 0(a0)
    li   a1, '\n'
    sb   a1, 0(a0)
    j    boot_halt

boot_fail_sig:
    // Print "BAD SIG\n"
    li   a0, UART_BASE
    li   a1, 'B'
    sb   a1, 0(a0)
    li   a1, 'A'
    sb   a1, 0(a0)
    li   a1, 'D'
    sb   a1, 0(a0)
    li   a1, ' '
    sb   a1, 0(a0)
    li   a1, 'S'
    sb   a1, 0(a0)
    li   a1, 'I'
    sb   a1, 0(a0)
    li   a1, 'G'
    sb   a1, 0(a0)
    li   a1, '\n'
    sb   a1, 0(a0)
    j    boot_halt

boot_halt:
    // Hang forever - do NOT boot untrusted firmware!
    j    boot_halt

