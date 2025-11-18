#!/bin/bash
#
# Native Ubuntu Setup Script for Secure RISC-V SoC
# Installs all required dependencies
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Secure RISC-V SoC - Ubuntu Setup            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please do not run this script as root${NC}"
   exit 1
fi

echo -e "${BLUE}[Step 1/3] Updating package lists...${NC}"
sudo apt-get update

echo -e "\n${BLUE}[Step 2/3] Installing build dependencies...${NC}"
sudo apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    cmake \
    ninja-build \
    vim \
    nano \
    less \
    tree \
    htop \
    dos2unix

echo -e "\n${BLUE}[Step 3/3] Installing RISC-V toolchain and Verilog tools...${NC}"
sudo apt-get install -y \
    gcc-riscv64-unknown-elf \
    binutils-riscv64-unknown-elf \
    verilator \
    iverilog \
    gtkwave

echo -e "\n${GREEN}✓ All dependencies installed!${NC}\n"

# Verify installations
echo -e "${BLUE}Verifying installations...${NC}\n"

# Check RISC-V toolchain
if command -v riscv64-unknown-elf-gcc &> /dev/null; then
    echo -e "${GREEN}✓ RISC-V GCC: $(riscv64-unknown-elf-gcc --version | head -n1)${NC}"
else
    echo -e "${RED}✗ RISC-V GCC not found${NC}"
fi

# Check Icarus Verilog
if command -v iverilog &> /dev/null; then
    echo -e "${GREEN}✓ Icarus Verilog: $(iverilog -v 2>&1 | head -n1)${NC}"
else
    echo -e "${RED}✗ Icarus Verilog not found${NC}"
fi

# Check GTKWave
if command -v gtkwave &> /dev/null; then
    echo -e "${GREEN}✓ GTKWave: $(gtkwave --version 2>&1 | head -n1)${NC}"
else
    echo -e "${RED}✗ GTKWave not found${NC}"
fi

# Check Verilator
if command -v verilator &> /dev/null; then
    echo -e "${GREEN}✓ Verilator: $(verilator --version)${NC}"
else
    echo -e "${RED}✗ Verilator not found${NC}"
fi

# Check Python
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✓ Python: $(python3 --version)${NC}"
else
    echo -e "${RED}✗ Python3 not found${NC}"
fi

echo -e "\n${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Setup Complete!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Make scripts executable: ${BLUE}chmod +x scripts/*.sh${NC}"
echo -e "  2. Run the build: ${BLUE}./scripts/build_and_run.sh${NC}"
echo -e ""

