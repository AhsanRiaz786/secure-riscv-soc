#!/bin/bash
#
# Anti-Replay Attack Test Suite
# Tests various replay attack scenarios
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
LOGS_DIR="$BUILD_DIR/anti_replay_tests"

echo "================================================"
echo "Anti-Replay Attack Regression Test Suite"
echo "Root: $PROJECT_ROOT"
echo "Logs: $LOGS_DIR"
echo "================================================"
echo ""

# Create logs directory
mkdir -p "$LOGS_DIR"

#=================================================================
# Test 1: Build firmware with anti-replay test
#=================================================================
echo "[1/5] Building anti-replay test firmware"
echo ""

cd "$PROJECT_ROOT/software"
make clean > /dev/null 2>&1
make all

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

echo ""

#=================================================================
# Test 2: Run baseline test (valid operations)
#=================================================================
echo "[2/5] Baseline: Valid counter and nonce operations"
echo ""

cd "$PROJECT_ROOT"
./scripts/simulate.sh > "$LOGS_DIR/baseline.log" 2>&1

if grep -q "ANTI-REPLAY PROTECTION: ACTIVE" "$LOGS_DIR/baseline.log"; then
    echo -e "${GREEN}✓ Baseline test passed${NC}"
else
    echo -e "${RED}✗ Baseline test failed${NC}"
    echo "Check log: $LOGS_DIR/baseline.log"
fi
echo ""

#=================================================================
# Test 3: Verify counter increments are working
#=================================================================
echo "[3/5] Counter Test: Monotonic property"
echo ""

if grep -q "Monotonic Counter - Monotonic Property" "$LOGS_DIR/baseline.log" && \
   grep -q "Counter rejected decrement" "$LOGS_DIR/baseline.log"; then
    echo -e "${GREEN}✓ Counter monotonic property verified${NC}"
else
    echo -e "${RED}✗ Counter test failed${NC}"
fi
echo ""

#=================================================================
# Test 4: Verify nonce uniqueness
#=================================================================
echo "[4/5] Nonce Test: Uniqueness check"
echo ""

if grep -q "Nonce Generator - Uniqueness" "$LOGS_DIR/baseline.log" && \
   grep -q "All nonces are unique" "$LOGS_DIR/baseline.log"; then
    echo -e "${GREEN}✓ Nonce uniqueness verified${NC}"
else
    echo -e "${RED}✗ Nonce test failed${NC}"
fi
echo ""

#=================================================================
# Test 5: Verify replay detection
#=================================================================
echo "[5/5] Replay Attack Test: Detection and blocking"
echo ""

if grep -q "REPLAY ATTACK BLOCKED" "$LOGS_DIR/baseline.log"; then
    echo -e "${GREEN}✓ Replay attack successfully blocked${NC}"
else
    echo -e "${RED}✗ Replay attack not detected${NC}"
fi

if grep -q "OLD COUNTER REJECTED" "$LOGS_DIR/baseline.log"; then
    echo -e "${GREEN}✓ Old counter values rejected${NC}"
else
    echo -e "${RED}✗ Old counter test failed${NC}"
fi
echo ""

#=================================================================
# Summary
#=================================================================
echo "================================================"
echo "Test Summary"
echo "================================================"
echo ""

# Count test results
TOTAL_TESTS=8
PASSED_TESTS=0

grep -q "TEST 1.*PASS" "$LOGS_DIR/baseline.log" && PASSED_TESTS=$((PASSED_TESTS+1))
grep -q "TEST 2.*PASS" "$LOGS_DIR/baseline.log" && PASSED_TESTS=$((PASSED_TESTS+1))
grep -q "TEST 3.*PASS" "$LOGS_DIR/baseline.log" && PASSED_TESTS=$((PASSED_TESTS+1))
grep -q "TEST 4.*PASS" "$LOGS_DIR/baseline.log" && PASSED_TESTS=$((PASSED_TESTS+1))
grep -q "TEST 5.*PASS" "$LOGS_DIR/baseline.log" && PASSED_TESTS=$((PASSED_TESTS+1))
grep -q "TEST 6.*PASS" "$LOGS_DIR/baseline.log" && PASSED_TESTS=$((PASSED_TESTS+1))
grep -q "TEST 7.*PASS" "$LOGS_DIR/baseline.log" && PASSED_TESTS=$((PASSED_TESTS+1))
grep -q "TEST 8.*PASS" "$LOGS_DIR/baseline.log" && PASSED_TESTS=$((PASSED_TESTS+1))

echo "Tests passed: $PASSED_TESTS / $TOTAL_TESTS"
echo ""

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ALL TESTS PASSED ✓                    ║${NC}"
    echo -e "${GREEN}║  Anti-Replay Protection: OPERATIONAL   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "Your SoC is protected against:"
    echo "  ✓ Replay attacks (packet capture + replay)"
    echo "  ✓ Out-of-order attacks (old counter values)"
    echo "  ✓ Nonce reuse attacks"
    echo "  ✓ Counter manipulation"
    echo ""
    echo "Flipper Zero style attacks: BLOCKED! 🛡️"
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  SOME TESTS FAILED ✗                   ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "Check logs in: $LOGS_DIR/"
    exit 1
fi

echo ""
echo "Full test log: $LOGS_DIR/baseline.log"
echo ""


