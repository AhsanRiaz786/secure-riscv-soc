/*
 * Firmware Header Format
 * 
 * Defines the structure of signed firmware images.
 * The header is placed at a fixed offset from the start of firmware.
 */

#ifndef FIRMWARE_HEADER_H
#define FIRMWARE_HEADER_H

#include <stdint.h>

//=================================================================
// Firmware Header Structure
//=================================================================
typedef struct {
    uint32_t magic;              // 0xDEADBEEF - identifies valid header
    uint32_t version;            // Firmware version (for anti-rollback)
    uint32_t length;             // Firmware length in bytes
    uint32_t entry_point;        // Entry point address (0x00010000)
    uint32_t timestamp;          // Build timestamp
    uint32_t reserved[3];        // Reserved for future use
    uint32_t signature[8];       // HMAC-SHA256 signature (256 bits = 8 x 32-bit words)
} __attribute__((packed)) firmware_header_t;

//=================================================================
// Constants
//=================================================================
#define FW_HEADER_MAGIC     0xDEADBEEF
#define FW_HEADER_OFFSET    0xFFC0    // Place header at end of 64KB firmware space
                                       // 0x00010000 + 0xFFC0 = 0x0001FFC0

//=================================================================
// Helper Macros
//=================================================================
#define FIRMWARE_BASE       0x00010000
#define FW_HEADER_ADDR      (FIRMWARE_BASE + FW_HEADER_OFFSET)

// Get pointer to firmware header
#define GET_FW_HEADER()     ((firmware_header_t*)FW_HEADER_ADDR)

#endif // FIRMWARE_HEADER_H

