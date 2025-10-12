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
#define KEY_STORE_BASE      0x40000000    // Future

// UART Registers
#define UART_TX_REG         (*(volatile unsigned int*)(UART_BASE + 0x00))
#define UART_STATUS_REG     (*(volatile unsigned int*)(UART_BASE + 0x04))

#define UART_TX_BUSY        0x01

#endif // SOC_MAP_H

