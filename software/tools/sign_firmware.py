#!/usr/bin/env python3
"""
Firmware Signing Tool for Secure RISC-V SoC

Generates HMAC-SHA256 signature and creates signed firmware image.

Usage:
    sign_firmware.py <firmware.bin> <key_hex> <version> <output.bin>

Example:
    sign_firmware.py firmware.bin 0123456789ABCDEF... 1 firmware_signed.bin
"""

import sys
import struct
import hmac
import hashlib
from datetime import datetime

def sign_firmware(firmware_path, key_hex, version, output_path):
    """
    Signs firmware binary with HMAC-SHA256
    
    Args:
        firmware_path: Path to firmware.bin
        key_hex: HMAC key as hex string (64 chars = 256 bits)
        version: Firmware version number
        output_path: Path for signed firmware
    """
    print(f"\n{'='*60}")
    print(f"  Secure RISC-V SoC - Firmware Signing Tool")
    print(f"{'='*60}\n")
    
    # Read firmware binary
    try:
        with open(firmware_path, 'rb') as f:
            firmware_data = bytearray(f.read())
    except FileNotFoundError:
        print(f"ERROR: Firmware file '{firmware_path}' not found!")
        sys.exit(1)
    
    print(f"Input firmware: {firmware_path}")
    print(f"  Size: {len(firmware_data)} bytes")
    
    # Header will be at offset 0xFFC0 (65472)
    header_offset = 0xFFC0
    
    if len(firmware_data) > header_offset:
        print(f"\nERROR: Firmware too large!")
        print(f"  Current size: {len(firmware_data)} bytes")
        print(f"  Maximum size: {header_offset} bytes")
        print(f"  Overflow: {len(firmware_data) - header_offset} bytes")
        sys.exit(1)
    
    # Pad firmware with zeros up to header offset
    padding_needed = header_offset - len(firmware_data)
    firmware_data.extend(b'\x00' * padding_needed)
    print(f"  Padded to: {len(firmware_data)} bytes")
    
    # Create firmware header
    magic = 0xDEADBEEF
    length = len(firmware_data)
    entry_point = 0x00010000
    timestamp = int(datetime.now().timestamp())
    
    print(f"\nFirmware header:")
    print(f"  Magic:      0x{magic:08X}")
    print(f"  Version:    {version}")
    print(f"  Length:     {length} bytes")
    print(f"  Entry:      0x{entry_point:08X}")
    print(f"  Timestamp:  {timestamp} ({datetime.fromtimestamp(timestamp)})")
    
    # Pack header (without signature yet)
    # Format: magic, version, length, entry_point, timestamp, reserved[3]
    header = struct.pack('<IIIIII',
                        magic,
                        version,
                        length,
                        entry_point,
                        timestamp,
                        0)  # reserved[0]
    header += struct.pack('<II', 0, 0)  # reserved[1], reserved[2]
    
    # Calculate HMAC-SHA256 over firmware + header (without signature)
    try:
        key = bytes.fromhex(key_hex)
        if len(key) != 32:
            print(f"\nERROR: Key must be exactly 256 bits (64 hex chars)")
            print(f"  Provided: {len(key)*8} bits ({len(key_hex)} hex chars)")
            sys.exit(1)
    except ValueError:
        print(f"\nERROR: Invalid hex key format!")
        sys.exit(1)
    
    print(f"\nHMAC key:")
    print(f"  {key_hex}")
    
    # Data to sign = firmware + header (without signature field)
    data_to_sign = firmware_data + header
    
    print(f"\nCalculating HMAC-SHA256...")
    print(f"  Input data: {len(data_to_sign)} bytes")
    
    # Calculate HMAC
    mac = hmac.new(key, data_to_sign, hashlib.sha256).digest()
    
    print(f"  HMAC result: {mac.hex()}")
    
    # Append signature (8 x 32-bit words in little-endian)
    signature_words = []
    for i in range(8):
        word = struct.unpack('<I', mac[i*4:(i+1)*4])[0]
        signature_words.append(word)
        header += struct.pack('<I', word)
    
    print(f"\nSignature (8 x 32-bit words):")
    for i, word in enumerate(signature_words):
        print(f"  [{i}] = 0x{word:08X}")
    
    # Write signed firmware
    signed_firmware = firmware_data + header
    
    try:
        with open(output_path, 'wb') as f:
            f.write(signed_firmware)
    except IOError as e:
        print(f"\nERROR: Failed to write output file!")
        print(f"  {e}")
        sys.exit(1)
    
    print(f"\n{'='*60}")
    print(f"  ✓ Firmware signed successfully!")
    print(f"{'='*60}")
    print(f"Output: {output_path}")
    print(f"  Total size: {len(signed_firmware)} bytes")
    print(f"  Header offset: 0x{header_offset:04X}")
    print(f"  Header size: {len(header)} bytes")
    print(f"\n")

def main():
    if len(sys.argv) != 5:
        print("Usage: sign_firmware.py <firmware.bin> <key_hex> <version> <output.bin>")
        print("\nArguments:")
        print("  firmware.bin  - Input firmware binary")
        print("  key_hex       - HMAC-256 key (64 hex characters)")
        print("  version       - Firmware version number (integer)")
        print("  output.bin    - Output signed firmware")
        print("\nExample:")
        print("  sign_firmware.py firmware.bin \\")
        print("      0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF \\")
        print("      1 \\")
        print("      firmware_signed.bin")
        sys.exit(1)
    
    firmware_path = sys.argv[1]
    key_hex = sys.argv[2]
    version = int(sys.argv[3])
    output_path = sys.argv[4]
    
    sign_firmware(firmware_path, key_hex, version, output_path)

if __name__ == '__main__':
    main()

