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
#define ANTI_REPLAY_BASE    0x50000000    // Anti-replay protection

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

// Anti-Replay Protection Registers
// Monotonic Counter (0x50000000 - 0x5000000F)
#define COUNTER_VALUE       (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x00))
#define COUNTER_CTRL        (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x04))
#define COUNTER_LOCK        (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x08))
#define COUNTER_STATUS      (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x0C))

// Nonce Generator (0x50000010 - 0x5000001F)
#define NONCE_VALUE         (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x10))
#define NONCE_SEED          (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x14))
#define NONCE_CTRL          (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x18))
#define NONCE_STATUS        (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x1C))

// Anti-Replay Engine (0x50000020 - 0x5000003F)
#define REPLAY_LAST_COUNTER (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x20))
#define REPLAY_CHECK_COUNTER (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x24))
#define REPLAY_CHECK_NONCE  (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x28))
#define REPLAY_VALIDATE     (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x2C))
#define REPLAY_STATUS       (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x30))
#define REPLAY_CACHE_SIZE   (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x34))
#define REPLAY_CTRL         (*(volatile unsigned int*)(ANTI_REPLAY_BASE + 0x38))

// Counter Control Bits
#define COUNTER_CTRL_INCREMENT  (1 << 0)
#define COUNTER_CTRL_LOAD       (1 << 1)
#define COUNTER_LOCK_MAGIC      0xDEAD10CC

// Counter Status Bits
#define COUNTER_STATUS_LOCKED   (1 << 0)
#define COUNTER_STATUS_OVERFLOW (1 << 1)

// Nonce Control Bits
#define NONCE_CTRL_ENABLE       (1 << 0)
#define NONCE_CTRL_ADVANCE      (1 << 1)

// Nonce Status Bits
#define NONCE_STATUS_READY      (1 << 0)

// Replay Status Bits
#define REPLAY_STATUS_VALID        (1 << 0)
#define REPLAY_STATUS_REPLAY       (1 << 1)
#define REPLAY_STATUS_BAD_COUNTER  (1 << 2)
#define REPLAY_STATUS_BAD_NONCE    (1 << 3)
#define REPLAY_STATUS_READY        (1 << 4)

// Replay Control Bits
#define REPLAY_CTRL_RESET_CACHE (1 << 0)
#define REPLAY_CTRL_RESET_STATE (1 << 1)

#endif // SOC_MAP_H

