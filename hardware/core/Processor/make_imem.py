# usage: python3 make_imem.py test.bin > imem_inits.v
import sys
b = open(sys.argv[1],"rb").read()
for i in range(0, len(b), 4):
    w = b[i:i+4]
    if len(w) < 4:
        w = w + b'\x00'*(4-len(w))
    val = int.from_bytes(w, byteorder='little')  # little-endian for RISC-V
    print(f"    memory[{i//4}] = 32'h{val:08x};")
