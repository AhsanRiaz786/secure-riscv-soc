/*
 * SoC Memory Map and Register Definitions
 */

#ifndef SOC_MAP_H
#define SOC_MAP_H

// Memory regions
#define BOOT_ROM_BASE       0x00000000
#define BOOT_ROM_SIZE       0x00001000    // 4KB

#define INSTR_MEM_BASE      0x00010000
#define INSTR_MEM_SIZE      0x00010000    // 64KB

#define DATA_MEM_BASE       0x10000000
#define DATA_MEM_SIZE       0x00010000    // 64KB

// Peripherals
#define UART_BASE           0x20000000
#define CRYPTO_BASE         0x30000000    // Future
#define KEY_STORE_BASE      0x40000000    // Protected by MPU!

// UART Registers
#define UART_TX_REG         (*(volatile unsigned int*)(UART_BASE + 0x00))
#define UART_STATUS_REG     (*(volatile unsigned int*)(UART_BASE + 0x04))

#define UART_TX_BUSY        0x01

// Key Store Registers (PROTECTED - Machine mode only!)
// Attempting to access these from user mode will cause MPU violation
#define KEY_STORE_SIZE      0x00000100    // 256 bytes
#define AES_KEY_0           (*(volatile unsigned int*)(KEY_STORE_BASE + 0x00))
#define AES_KEY_1           (*(volatile unsigned int*)(KEY_STORE_BASE + 0x04))
#define AES_KEY_2           (*(volatile unsigned int*)(KEY_STORE_BASE + 0x08))
#define AES_KEY_3           (*(volatile unsigned int*)(KEY_STORE_BASE + 0x0C))
#define HMAC_KEY_0          (*(volatile unsigned int*)(KEY_STORE_BASE + 0x10))
#define HMAC_KEY_1          (*(volatile unsigned int*)(KEY_STORE_BASE + 0x14))
#define ROOT_KEY            (*(volatile unsigned int*)(KEY_STORE_BASE + 0x20))

#endif // SOC_MAP_H

