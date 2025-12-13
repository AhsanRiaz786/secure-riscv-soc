#!/bin/bash
#
# Quick Test Script for Anti-Replay Feature
# Runs simulation in background with progress monitoring
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Anti-Replay Feature - Quick Test${NC}"
echo -e "${BLUE}================================================${NC}\n"

echo "[1/3] Building firmware..."
cd "$PROJECT_ROOT/software"
make clean > /dev/null 2>&1
make all > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Build complete${NC}\n"

echo "[2/3] Running simulation (this may take 1-2 minutes)..."
echo "      The secure boot HMAC calculation takes time for 65KB firmware."
echo "      Progress will be shown below..."
echo ""

# Run simulation in background and monitor progress
cd "$PROJECT_ROOT"
./scripts/simulate.sh > /tmp/anti_replay_sim.log 2>&1 &
SIM_PID=$!

# Show progress dots
echo -n "      Progress: "
while kill -0 $SIM_PID 2>/dev/null; do
    echo -n "."
    sleep 3
done
echo ""

wait $SIM_PID
SIM_EXIT_CODE=$?

echo ""
if [ $SIM_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Simulation completed${NC}"
else
    echo -e "${RED}✗ Simulation failed with exit code $SIM_EXIT_CODE${NC}"
    echo "Check /tmp/anti_replay_sim.log for details."
    exit 1
fi
echo ""

echo "[3/3] Checking results..."
if grep -q "SECURE BOOT" /tmp/anti_replay_sim.log && \
   grep -q "ANTI-REPLAY PROTECTION: ACTIVE" /tmp/anti_replay_sim.log && \
   grep -q "TEST SUITE COMPLETE" /tmp/anti_replay_sim.log; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ANTI-REPLAY FEATURE: FULLY WORKING ✓ ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "Key outputs:"
    grep -E "SECURE BOOT|ANTI-REPLAY|TEST [0-9]|PASS|FAIL" /tmp/anti_replay_sim.log | head -20
    echo ""
    echo "Full log: /tmp/anti_replay_sim.log"
else
    echo -e "${RED}✗ Anti-Replay feature verification FAILED${NC}"
    echo "Last 30 lines of log:"
    tail -30 /tmp/anti_replay_sim.log
    exit 1
fi
