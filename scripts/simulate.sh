#!/bin/bash
#
# Simulation Script for Secure RISC-V SoC
# Compiles Verilog and runs testbench with Icarus Verilog
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Secure RISC-V SoC - Simulation${NC}"
echo -e "${BLUE}================================================${NC}\n"

# Project paths
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RTL_DIR="$PROJECT_ROOT/hardware/rtl"
TB_DIR="$PROJECT_ROOT/hardware/tb"
MEM_INIT_DIR="$PROJECT_ROOT/hardware/mem_init"
BUILD_DIR="$PROJECT_ROOT/build"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo -e "${GREEN}Project root: $PROJECT_ROOT${NC}"
echo -e "${GREEN}Build directory: $BUILD_DIR${NC}\n"

# Check for required files
echo -e "${BLUE}[1/4] Checking memory initialization files...${NC}"
mkdir -p "$MEM_INIT_DIR"
if [ ! -f "$MEM_INIT_DIR/boot_rom.hex" ]; then
    echo -e "${YELLOW}Warning: boot_rom.hex not found, creating empty file${NC}"
    echo "" > "$MEM_INIT_DIR/boot_rom.hex"
fi
if [ ! -f "$MEM_INIT_DIR/firmware.hex" ]; then
    echo -e "${YELLOW}Warning: firmware.hex not found, creating empty file${NC}"
    echo "" > "$MEM_INIT_DIR/firmware.hex"
fi

# Copy memory files to build directory
cp "$MEM_INIT_DIR"/*.hex . 2>/dev/null || true
echo -e "${GREEN}✓ Memory files ready${NC}\n"

# Compile Verilog
echo -e "${BLUE}[2/4] Compiling Verilog sources...${NC}"
iverilog -g2012 \
    -o soc_sim.vvp \
    -s tb_soc_top \
    -I"$RTL_DIR" \
    "$TB_DIR/tb_soc_top.v" \
    "$RTL_DIR/top/soc_top.v" \
    "$RTL_DIR/cpu/picorv32.v" \
    "$RTL_DIR/memory/boot_rom.v" \
    "$RTL_DIR/memory/instruction_mem.v" \
    "$RTL_DIR/memory/data_mem.v" \
    "$RTL_DIR/peripherals/uart.v"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Compilation successful${NC}\n"
else
    echo -e "${RED}✗ Compilation failed${NC}"
    exit 1
fi

# Run simulation
echo -e "${BLUE}[3/4] Running simulation...${NC}"
echo -e "${BLUE}================================================${NC}\n"

vvp soc_sim.vvp

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✓ Simulation completed${NC}\n"
else
    echo -e "\n${RED}✗ Simulation failed${NC}"
    exit 1
fi

# Check for VCD file
echo -e "${BLUE}[4/4] Checking outputs...${NC}"
if [ -f "soc_simulation.vcd" ]; then
    VCD_SIZE=$(du -h soc_simulation.vcd | cut -f1)
    echo -e "${GREEN}✓ Waveform file generated: soc_simulation.vcd ($VCD_SIZE)${NC}"
    echo -e "${YELLOW}  View with: gtkwave $BUILD_DIR/soc_simulation.vcd${NC}"
fi

echo -e "\n${BLUE}================================================${NC}"
echo -e "${GREEN}Simulation complete!${NC}"
echo -e "${BLUE}================================================${NC}\n"

# List generated files
echo -e "${BLUE}Generated files:${NC}"
ls -lh *.vvp *.vcd 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""