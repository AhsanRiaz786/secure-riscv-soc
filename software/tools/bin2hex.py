#!/usr/bin/env python3
"""
Convert binary file to hex format for Verilog $readmemh
"""

import sys
import os

def bin2hex(bin_file, hex_file, num_words=None):
    """Convert binary to hex format"""
    
    with open(bin_file, 'rb') as f:
        data = f.read()
    
    # Pad to word boundary
    if len(data) % 4 != 0:
        data += b'\x00' * (4 - (len(data) % 4))
    
    # Calculate number of words
    actual_words = len(data) // 4
    
    if num_words is None:
        num_words = actual_words
    
    print(f"Binary size: {len(data)} bytes ({actual_words} words)")
    print(f"Output size: {num_words} words")
    
    with open(hex_file, 'w') as f:
        # Write actual data
        for i in range(0, len(data), 4):
            if i // 4 < num_words:
                word = data[i:i+4]
                # Little endian
                word_val = (word[0] | (word[1] << 8) | 
                           (word[2] << 16) | (word[3] << 24))
                f.write(f"{word_val:08x}\n")
        
        # Pad with zeros if needed
        for i in range(actual_words, num_words):
            f.write("00000000\n")
    
    print(f"Generated: {hex_file}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: bin2hex.py <input.bin> <output.hex> [num_words]")
        sys.exit(1)
    
    bin_file = sys.argv[1]
    hex_file = sys.argv[2]
    num_words = int(sys.argv[3]) if len(sys.argv) > 3 else None
    
    if not os.path.exists(bin_file):
        print(f"Error: {bin_file} not found")
        sys.exit(1)
    
    bin2hex(bin_file, hex_file, num_words)

