#!/bin/bash
#
# Master Build and Run Script
# Builds firmware and runs simulation
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Secure RISC-V SoC - Build & Run System      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# Step 1: Build firmware
echo -e "${BLUE}[Step 1/2] Building Firmware...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
cd software
make clean
make all
cd ..
echo -e "${GREEN}✓ Firmware build complete${NC}\n"

# Step 2: Run simulation
echo -e "${BLUE}[Step 2/2] Running Simulation...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
./scripts/simulate.sh

echo -e "\n${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Build & Run Complete!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo -e "  • View waveform: ${BLUE}gtkwave build/soc_simulation.vcd${NC}"
echo -e "  • Check disassembly: ${BLUE}cat build/firmware.dis${NC}"
echo -e "  • Modify firmware: ${BLUE}nano software/firmware/main.c${NC}"
echo -e ""

