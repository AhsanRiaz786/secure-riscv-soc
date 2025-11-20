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
#define CRYPTO_BASE         0x30000000
#define KEY_STORE_BASE      0x40000000    // Protected by MPU!

// UART Registers
#define UART_TX_REG         (*(volatile unsigned int*)(UART_BASE + 0x00))
#define UART_STATUS_REG     (*(volatile unsigned int*)(UART_BASE + 0x04))

#define UART_TX_BUSY        0x01

// Crypto Accelerator Registers
#define CRYPTO_CTRL         (*(volatile unsigned int*)(CRYPTO_BASE + 0x00))
#define CRYPTO_STATUS       (*(volatile unsigned int*)(CRYPTO_BASE + 0x04))
#define CRYPTO_MODE         (*(volatile unsigned int*)(CRYPTO_BASE + 0x08))
#define CRYPTO_MSG_ADDR     (*(volatile unsigned int*)(CRYPTO_BASE + 0x0C))
#define CRYPTO_MSG_LEN      (*(volatile unsigned int*)(CRYPTO_BASE + 0x10))
#define CRYPTO_KEY_0        (*(volatile unsigned int*)(CRYPTO_BASE + 0x14))
#define CRYPTO_KEY_1        (*(volatile unsigned int*)(CRYPTO_BASE + 0x18))
#define CRYPTO_KEY_2        (*(volatile unsigned int*)(CRYPTO_BASE + 0x1C))
#define CRYPTO_KEY_3        (*(volatile unsigned int*)(CRYPTO_BASE + 0x20))
#define CRYPTO_KEY_4        (*(volatile unsigned int*)(CRYPTO_BASE + 0x24))
#define CRYPTO_KEY_5        (*(volatile unsigned int*)(CRYPTO_BASE + 0x28))
#define CRYPTO_KEY_6        (*(volatile unsigned int*)(CRYPTO_BASE + 0x2C))
#define CRYPTO_KEY_7        (*(volatile unsigned int*)(CRYPTO_BASE + 0x30))
#define CRYPTO_HASH_0       (*(volatile unsigned int*)(CRYPTO_BASE + 0x40))
#define CRYPTO_HASH_1       (*(volatile unsigned int*)(CRYPTO_BASE + 0x44))
#define CRYPTO_HASH_2       (*(volatile unsigned int*)(CRYPTO_BASE + 0x48))
#define CRYPTO_HASH_3       (*(volatile unsigned int*)(CRYPTO_BASE + 0x4C))
#define CRYPTO_HASH_4       (*(volatile unsigned int*)(CRYPTO_BASE + 0x50))
#define CRYPTO_HASH_5       (*(volatile unsigned int*)(CRYPTO_BASE + 0x54))
#define CRYPTO_HASH_6       (*(volatile unsigned int*)(CRYPTO_BASE + 0x58))
#define CRYPTO_HASH_7       (*(volatile unsigned int*)(CRYPTO_BASE + 0x5C))

// Crypto Control Bits
#define CRYPTO_CTRL_START   (1 << 0)
#define CRYPTO_CTRL_RESET   (1 << 1)

// Crypto Status Bits
#define CRYPTO_STATUS_BUSY  (1 << 0)
#define CRYPTO_STATUS_DONE  (1 << 1)
#define CRYPTO_STATUS_ERROR (1 << 2)

// Crypto Modes
#define CRYPTO_MODE_SHA256      0
#define CRYPTO_MODE_HMAC_SHA256 1

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

