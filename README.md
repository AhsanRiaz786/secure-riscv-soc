# Secure RISC-V SoC for Smart Lock System

<div align="center">

**A hardware-secured System-on-Chip (SoC) implementation featuring comprehensive security features for IoT applications**

[![RISC-V](https://img.shields.io/badge/RISC--V-RV32I-green.svg)](https://riscv.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Verilog](https://img.shields.io/badge/HDL-Verilog-orange.svg)](https://www.verilog.com/)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Security Features](#security-features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Building the Project](#building-the-project)
  - [Running Simulations](#running-simulations)
- [Project Structure](#project-structure)
- [Memory Map](#memory-map)
- [Usage Examples](#usage-examples)
- [Testing](#testing)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)
- [Credits](#credits)

---

## 🎯 Overview

This project implements a **Secure RISC-V SoC** designed for smart lock and IoT applications. The system provides hardware-assisted security features to protect against common attack vectors including firmware tampering, replay attacks, and unauthorized memory access.

### Project Goals

- **Hardware-enforced security** through dedicated security modules
- **Secure boot** with cryptographic firmware verification
- **Memory protection** to prevent unauthorized access to sensitive data
- **Anti-replay protection** for secure communication protocols
- **Production-ready** implementation suitable for IoT devices

### Target Applications

- Smart locks and access control systems
- IoT devices requiring secure firmware updates
- Embedded systems with security requirements
- Research and education in hardware security

---

## ✨ Key Features

### 1. **Memory Protection Unit (MPU)**
- Hardware-enforced memory access control
- Region-based protection (Boot ROM, Firmware, Data, Key Store)
- Prevents unauthorized reads/writes to protected regions
- Privilege level enforcement

### 2. **Secure Boot**
- HMAC-SHA256 firmware verification
- Hardware cryptographic accelerator
- Tamper detection and prevention
- Only signed firmware can execute

### 3. **Anti-Replay Protection**
- Hardware monotonic counter (32-bit, lockable)
- LFSR-based nonce generator
- Nonce cache to prevent reuse
- Counter progression validation
- Blocks replay and out-of-order attacks

### 4. **Cryptographic Accelerator**
- SHA-256 hash computation
- HMAC-SHA256 message authentication
- Hardware-accelerated for performance
- Memory-mapped peripheral interface

### 5. **Key Store**
- Protected memory region for cryptographic keys
- MPU-enforced access control
- Machine-mode only access
- Prevents key exfiltration

---

## 🏗️ Architecture

### System Block Diagram

```
┌─────────────────────────────────────────────────────────┐
│                  Secure RISC-V SoC                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐        ┌──────────────────┐           │
│  │  PicoRV32    │◄──────►│  Memory Bus      │           │
│  │  CPU (RV32I) │        │                  │           │
│  └──────────────┘        └──────────────────┘           │
│         │                          │                    │
│         │                          ▼                    │
│         │                ┌─────────────────┐            │
│         │                │      MPU        │            │
│         │                │  (Protection)   │            │
│         │                └─────────────────┘            │
│         │                          │                    │
│         ▼                          ▼                    │
│  ┌──────────────────────────────────────────┐           │
│  │         Memory Subsystem                 │           │
│  │  • Boot ROM (4KB)   • Inst Mem (64KB)    |           │
│  │  • Data Mem (64KB)  • Key Store (256B)   |           │
│  └──────────────────────────────────────────┘           │
│                                                         │
│  ┌──────────────────────────────────────────┐           │
│  │      Security Modules                    │           │
│  │  • Crypto Accelerator  • Anti-Replay     │           │
│  │  • Monotonic Counter   • Nonce Generator │           │
│  └──────────────────────────────────────────┘           │
│                                                         │
│  ┌──────────────┐                                       │
│  │     UART     │  (Debug Console)                      │
│  └──────────────┘                                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Core Components

1. **CPU**: PicoRV32 (RISC-V RV32I ISA)
2. **Memory**: Boot ROM, Instruction Memory, Data Memory
3. **Security**: MPU, Crypto Accelerator, Anti-Replay Engine
4. **Peripherals**: UART for debug output
5. **Interconnect**: Memory-mapped bus architecture

---

## 🔒 Security Features

### Memory Protection Unit (MPU)

The MPU enforces hardware-level memory access control:

- **Boot ROM Protection**: Read-only, execute-only
- **Firmware Protection**: Read/execute only (prevents modification)
- **Key Store Protection**: Machine-mode only access
- **Region Isolation**: Strict boundaries between memory regions

**Attack Prevention**: Prevents firmware modification, key exfiltration, and code injection.

### Secure Boot

The secure boot process ensures only authenticated firmware executes:

1. Boot ROM loads HMAC key from protected Key Store
2. Crypto accelerator calculates HMAC-SHA256 of firmware
3. Compares with signature stored in firmware header
4. Boots firmware only if signature matches
5. Halts system if verification fails

**Attack Prevention**: Blocks tampered firmware, malware injection, and unauthorized code execution.

### Anti-Replay Protection

Protects against replay and out-of-order packet attacks:

- **Monotonic Counter**: Hardware counter that only increments
- **Nonce Generator**: LFSR-based unique nonce generation
- **Nonce Cache**: Tracks recent nonces to detect reuse
- **Counter Validation**: Ensures counter always progresses forward

**Attack Prevention**: Blocks replay attacks, out-of-order packets, and nonce reuse.

### Cryptographic Accelerator

Hardware-accelerated cryptographic operations:

- **SHA-256**: FIPS 180-4 compliant hash function
- **HMAC-SHA256**: Keyed-hash message authentication
- **Memory Interface**: Reads data directly from memory
- **Status Registers**: Polling interface for completion

**Benefits**: Fast cryptographic operations without CPU overhead.

---

## 🚀 Getting Started

### Prerequisites

> **💡 Tip**: If you prefer not to install tools manually, use the Docker Setup section below. The Docker image includes all required tools pre-installed.

#### Required Tools

1. **RISC-V Toolchain**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install gcc-riscv64-unknown-elf
   
   # macOS (Homebrew)
   brew tap riscv/riscv
   brew install riscv-gnu-toolchain
   ```

2. **Verilog Simulator (Icarus Verilog)**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install iverilog
   
   # macOS
   brew install icarus-verilog
   ```

3. **Python 3** (for build scripts)
   ```bash
   # Usually pre-installed, verify with:
   python3 --version
   ```

4. **Make** (build automation)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install build-essential
   ```

#### Optional Tools

- **GTKWave**: Waveform viewer for debugging
  ```bash
  sudo apt-get install gtkwave  # Linux
  brew install gtkwave          # macOS
  ```

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd secure-riscv-soc
   ```

2. **Verify toolchain installation**
   ```bash
   riscv64-unknown-elf-gcc --version
   iverilog -v
   python3 --version
   ```

3. **Build the project**
   ```bash
   cd software
   make all
   ```

### Docker Setup (Recommended)

For a consistent development environment across all platforms, you can use Docker. This avoids manual installation of dependencies.

#### Option 1: Pull Pre-built Image (Fastest)

Pull the pre-built Docker image from Docker Hub:

```bash
docker pull ahsanriaz8000/secure-riscv-soc:latest
```

Then run the container:

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  ahsanriaz8000/secure-riscv-soc:latest \
  /bin/bash
```

#### Option 2: Using Docker Compose (Recommended)

1. **Start the development container**
   ```bash
   docker-compose up -d
   ```

2. **Enter the container**
   ```bash
   docker-compose exec riscv-soc bash
   ```

3. **Build and run simulations**
   ```bash
   cd software
   make all
   cd ..
   ./scripts/simulate.sh
   ```

#### Option 3: Build from Dockerfile

Build the Docker image locally:

```bash
docker build -t secure-riscv-soc:latest .
```

Then run it:

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  secure-riscv-soc:latest \
  /bin/bash
```

#### Docker Benefits

- ✅ **No manual toolchain setup** - All tools pre-installed
- ✅ **Consistent environment** - Same tools on Linux, macOS, Windows
- ✅ **Isolated workspace** - No conflicts with system packages
- ✅ **Easy sharing** - Same image works for all team members

#### Stopping the Docker Container

If using docker-compose:

```bash
docker-compose down
```

If running manually:

```bash
# Just exit the container (--rm flag auto-removes it)
exit
```

### Building the Project

#### Build Boot ROM and Firmware

```bash
cd software
make all
```

This will:
- Compile the secure boot ROM
- Compile and sign the application firmware
- Generate memory initialization files (`*.hex`)

#### Build Outputs

- `build/boot.elf` - Boot ROM ELF file
- `build/boot.bin` - Boot ROM binary
- `build/firmware.elf` - Firmware ELF file
- `build/firmware.bin.signed` - Signed firmware binary
- `hardware/mem_init/boot_rom.hex` - Boot ROM memory initialization
- `hardware/mem_init/firmware.hex` - Firmware memory initialization

#### Clean Build

```bash
cd software
make clean
make all
```

### Running Simulations

#### Quick Test (Anti-Replay Feature)

```bash
./scripts/test_anti_replay_quick.sh
```

This script:
- Builds the firmware
- Runs the simulation
- Verifies all tests pass
- Shows progress indicators

#### Full Simulation

```bash
./scripts/simulate.sh
```

This will:
- Compile all Verilog sources
- Run the testbench
- Generate waveform file (`soc_simulation.vcd`)
- Display UART output

#### View Waveforms (Optional)

```bash
gtkwave build/soc_simulation.vcd
```

#### Run Specific Tests

**MPU Test:**
```bash
cd software
# Edit Makefile: Change FW_SRCS to test_mpu.c
make clean all
cd ..
./scripts/simulate.sh
```

**Secure Boot Test:**
```bash
cd software
# Edit Makefile: Change FW_SRCS to test_secure_boot.c
make clean all
cd ..
./scripts/simulate.sh
```

**Anti-Replay Test:**
```bash
cd software
# Edit Makefile: Change FW_SRCS to test_anti_replay.c
make clean all
cd ..
./scripts/test_anti_replay_quick.sh
```

---

## 📁 Project Structure

```
secure-riscv-soc/
│
├── hardware/
│   ├── rtl/                    # RTL (Register Transfer Level) code
│   │   ├── cpu/
│   │   │   └── picorv32.v      # PicoRV32 CPU core
│   │   ├── memory/
│   │   │   ├── boot_rom.v      # Boot ROM (4KB)
│   │   │   ├── instruction_mem.v  # Instruction memory (64KB)
│   │   │   └── data_mem.v      # Data memory (64KB)
│   │   ├── peripherals/
│   │   │   └── uart.v          # UART peripheral
│   │   ├── security/           # Security modules
│   │   │   ├── mpu.v           # Memory Protection Unit
│   │   │   ├── sha256.v        # SHA-256 hash core
│   │   │   ├── hmac_sha256.v   # HMAC-SHA256 implementation
│   │   │   ├── crypto_accelerator.v  # Crypto accelerator
│   │   │   ├── monotonic_counter.v   # Monotonic counter
│   │   │   ├── nonce_gen.v     # Nonce generator (LFSR)
│   │   │   └── anti_replay.v   # Anti-replay engine
│   │   └── top/
│   │       └── soc_top.v       # Top-level SoC integration
│   │
│   ├── tb/                     # Testbenches
│   │   ├── tb_soc_top.v        # Main SoC testbench
│   │   └── anti_replay_tb.v    # Anti-replay unit testbench
│   │
│   ├── mem_init/               # Memory initialization files
│   │   ├── boot_rom.hex        # Boot ROM initialization
│   │   └── firmware.hex        # Firmware initialization
│   │
│   └── constraints/            # FPGA timing constraints (future)
│
├── software/
│   ├── boot/                   # Boot ROM source
│   │   ├── boot_secure.S       # Secure boot implementation
│   │   └── boot.ld             # Boot ROM linker script
│   │
│   ├── firmware/               # Application firmware
│   │   ├── start.S             # Firmware entry point
│   │   ├── firmware.ld         # Firmware linker script
│   │   ├── test_mpu.c          # MPU test suite
│   │   ├── test_secure_boot.c  # Secure boot test
│   │   └── test_anti_replay.c  # Anti-replay test suite
│   │
│   ├── common/                 # Shared code
│   │   ├── soc_map.h           # Memory map definitions
│   │   ├── firmware_header.h   # Firmware header structure
│   │   ├── uart.h              # UART interface
│   │   └── uart.c              # UART implementation
│   │
│   ├── tools/                  # Build tools
│   │   ├── bin2hex.py          # Binary to hex converter
│   │   └── sign_firmware.py    # Firmware signing tool
│   │
│   └── Makefile                # Build automation
│
├── scripts/                    # Automation scripts
│   ├── simulate.sh             # Main simulation script
│   ├── test_anti_replay_quick.sh  # Quick anti-replay test
│   ├── test_replay_attacks.sh     # Replay attack scenarios
│   └── test_secure_boot_attacks.sh # Secure boot attack tests
│
├── build/                      # Build outputs (git-ignored)
│   ├── *.elf                   # Compiled ELF files
│   ├── *.bin                   # Binary files
│   ├── *.hex                   # Hex files
│   └── *.vvp                   # Compiled simulation
│
├── docs/                       # Documentation
│   ├── diagrams/               # Architecture diagrams
│   └── specifications/         # Design specifications
│
├── .gitignore                  # Git ignore rules
└── README.md                   # This file
```

---

## 🗺️ Memory Map

| Address Range | Size | Description | Access |
|--------------|------|-------------|--------|
| `0x00000000` - `0x00000FFF` | 4KB | Boot ROM | Read/Execute only |
| `0x00010000` - `0x0001FFFF` | 64KB | Instruction Memory | Read/Execute only |
| `0x10000000` - `0x1000FFFF` | 64KB | Data Memory | Read/Write/Execute |
| `0x20000000` - `0x200000FF` | 256B | UART | Read/Write |
| `0x30000000` - `0x300000FF` | 256B | Crypto Accelerator | Read/Write |
| `0x40000000` - `0x400000FF` | 256B | Key Store | Machine-mode only |
| `0x50000000` - `0x500000FF` | 256B | Anti-Replay Protection | Read/Write |

### Peripheral Registers

See `software/common/soc_map.h` for complete register definitions.

---

## 💡 Usage Examples

### Writing Firmware

Example firmware that uses the security features:

```c
#include "soc_map.h"
#include "uart.h"

void main(void) {
    uart_puts("Secure SoC Firmware\n");
    
    // Access protected Key Store (will trap if not privileged)
    // volatile unsigned int key = *((unsigned int*)KEY_STORE_BASE);
    
    // Use anti-replay protection
    COUNTER_VALUE = 0;
    REPLAY_CHECK_COUNTER = 1;
    REPLAY_CHECK_NONCE = 0x12345678;
    REPLAY_VALIDATE = 1;
    
    // Wait for validation
    while (!(REPLAY_STATUS & REPLAY_STATUS_READY));
    
    if (REPLAY_STATUS & REPLAY_STATUS_VALID) {
        uart_puts("Packet validated\n");
    }
}
```

### Signing Firmware

Firmware must be signed before it can boot:

```bash
cd software
python3 tools/sign_firmware.py \
    build/firmware.bin \
    0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF \
    1 \
    build/firmware.bin.signed
```

### Testing Security Features

**Test MPU Protection:**
```bash
# Edit software/Makefile: Set FW_SRCS to test_mpu.c
cd software && make clean all && cd ..
./scripts/simulate.sh | grep -E "TEST|PASS|FAIL|TRAP"
```

**Test Secure Boot:**
```bash
# Edit software/Makefile: Set FW_SRCS to test_secure_boot.c
cd software && make clean all && cd ..
./scripts/simulate.sh | grep -E "SECURE BOOT|OK|BAD"
```

**Test Anti-Replay:**
```bash
./scripts/test_anti_replay_quick.sh
```

---

## 🧪 Testing

### Test Suites

1. **MPU Test Suite** (`test_mpu.c`)
   - Normal memory access
   - Key Store protection (should trap)
   - UART peripheral access

2. **Secure Boot Test** (`test_secure_boot.c`)
   - Boot success verification
   - Firmware header validation

3. **Anti-Replay Test Suite** (`test_anti_replay.c`)
   - 8 comprehensive tests:
     - Monotonic counter increment
     - Monotonic property (reject decrements)
     - Counter lock mechanism
     - Nonce uniqueness
     - Valid packet acceptance
     - Replay attack blocking
     - Old counter rejection
     - Valid sequence acceptance

### Running Tests

**Quick Test:**
```bash
./scripts/test_anti_replay_quick.sh
```

**All Tests:**
```bash
# MPU Tests
cd software
sed -i 's/FW_SRCS = .*/FW_SRCS = firmware\/start.S common\/uart.c firmware\/test_mpu.c/' Makefile
make clean all && cd .. && ./scripts/simulate.sh

# Secure Boot Tests
cd software
sed -i 's/FW_SRCS = .*/FW_SRCS = firmware\/start.S common\/uart.c firmware\/test_secure_boot.c/' Makefile
make clean all && cd .. && ./scripts/simulate.sh

# Anti-Replay Tests
./scripts/test_anti_replay_quick.sh
```

### Expected Test Results

All tests should pass:
- ✅ MPU: Key Store access traps (security working)
- ✅ Secure Boot: Firmware verifies and boots
- ✅ Anti-Replay: All 8 tests pass, attacks blocked

---

## 📚 Documentation

### Key Documentation Files

- **This README**: Project overview and quick start
- **Source Code Comments**: Inline documentation in Verilog/C files
- **Header Files**: `soc_map.h`, `firmware_header.h` contain register definitions

### Understanding the Code

1. **Start with**: `hardware/rtl/top/soc_top.v` - System integration
2. **Security modules**: `hardware/rtl/security/` - All security features
3. **Boot process**: `software/boot/boot_secure.S` - Secure boot implementation
4. **Memory map**: `software/common/soc_map.h` - All addresses and registers

### Architecture Details

- **MPU**: See `hardware/rtl/security/mpu.v` for protection logic
- **Secure Boot**: See `software/boot/boot_secure.S` for boot sequence
- **Anti-Replay**: See `hardware/rtl/security/anti_replay.v` for validation logic

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature`
3. **Make your changes**: Follow existing code style
4. **Add tests**: Ensure all tests pass
5. **Commit changes**: Write clear commit messages
6. **Push to branch**: `git push origin feature/your-feature`
7. **Create Pull Request**: Describe your changes

### Code Style

- **Verilog**: Follow existing naming conventions
- **C Code**: Use consistent indentation (4 spaces)
- **Comments**: Document complex logic
- **Test Coverage**: Add tests for new features

### Areas for Contribution

- Additional security features
- Performance optimizations
- Documentation improvements
- Test coverage expansion
- FPGA synthesis support

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/AhsanRiaz786/secure-riscv-soc/LICENSE) file for details.

---

## 👥 Credits

### Project Authors

- Developed as part of CS339 Computer Architecture course
- Secure RISC-V SoC for Smart Lock System

### Acknowledgments

- **PicoRV32**: CPU core by Claire Wolf ([GitHub](https://github.com/YosysHQ/picorv32))
- **RISC-V Foundation**: Open ISA specification
- **Icarus Verilog**: Open-source Verilog simulator

### References

- RISC-V Instruction Set Manual
- FIPS 180-4 (SHA-256 specification)
- RFC 2104 (HMAC specification)
- Hardware security best practices

---

## 📞 Support

For questions, issues, or contributions:

1. **Check Documentation**: Read this README and code comments
2. **Review Issues**: Check existing GitHub issues
3. **Create Issue**: Report bugs or request features
4. **Contact**: Reach out to project maintainers

---

## 🎓 Educational Use

This project is suitable for:

- Computer Architecture courses
- Hardware Security education
- RISC-V ISA learning
- SoC design projects
- Security research

---

## 🔮 Future Enhancements

Potential improvements:

- [ ] AES encryption/decryption support
- [ ] True Random Number Generator (TRNG)
- [ ] Anti-rollback protection
- [ ] FPGA synthesis support
- [ ] Additional test coverage
- [ ] Performance optimizations
- [ ] Power management features

---

<div align="center">

**Built with ❤️ for secure IoT applications**

[Report Bug](https://github.com/AhsanRiaz786/secure-riscv-soc/issues) · [Request Feature](https://github.com/AhsanRiaz786/secure-riscv-soc/issues) · [Documentation](https://github.com/AhsanRiaz786/secure-riscv-soc/README.md)

</div>

