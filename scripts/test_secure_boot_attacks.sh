#!/bin/bash
#
# Automated secure-boot regression covering friendly boot plus three tamper cases.
# Usage:
#   ./scripts/test_secure_boot_attacks.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
LOG_DIR="$BUILD_DIR/secure_boot_attacks"
GOOD_BIN="$BUILD_DIR/firmware.bin.signed"

mkdir -p "$LOG_DIR"
cd "$REPO_ROOT"

function make_hex() {
    local bin_path="$1"
    echo "⮑ Updating firmware.hex from $(basename "$bin_path")"
    python3 software/tools/bin2hex.py "$bin_path" hardware/mem_init/firmware.hex 16384
}

function run_sim() {
    local label="$1"
    local log="$LOG_DIR/${label// /_}.log"
    echo ""
    echo "================================================"
    echo "Running simulation: $label"
    echo "Log: $log"
    echo "================================================"
    scripts/simulate.sh | tee "$log"
}

echo "================================================"
echo "Secure Boot Attack Regression"
echo "Root: $REPO_ROOT"
echo "Logs: $LOG_DIR"
echo "================================================"

echo ""
echo "[1/5] Building boot ROM + firmware"
pushd software >/dev/null
make all
popd >/dev/null

echo ""
echo "[2/5] Baseline (signed firmware should boot)"
make_hex "$GOOD_BIN"
run_sim "baseline_signed_ok"

echo ""
echo "[3/5] Attack #1: Bit-flip inside firmware payload"
BITFLIP_BIN="$BUILD_DIR/firmware_bitflip.bin"
python3 - "$GOOD_BIN" "$BITFLIP_BIN" <<'PY'
import sys, pathlib
src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
data = bytearray(src.read_bytes())
if len(data) < 512:
    raise SystemExit("Firmware image too small to flip bits.")
data[256] ^= 0x01
dst.write_bytes(data)
print(f"Flipped byte 256 in {dst.name}")
PY
make_hex "$BITFLIP_BIN"
run_sim "attack_bitflip_bad_sig"

echo ""
echo "[4/5] Attack #2: Corrupt firmware header magic"
HEADER_BAD_BIN="$BUILD_DIR/firmware_bad_magic.bin"
python3 - "$GOOD_BIN" "$HEADER_BAD_BIN" <<'PY'
import sys, struct, pathlib
src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
data = bytearray(src.read_bytes())
# Header starts at 0xFFC0 relative to firmware base.
hdr_offset = 0xFFC0
if len(data) < hdr_offset + 4:
    raise SystemExit("Firmware image missing header.")
data[hdr_offset:hdr_offset+4] = (0xBAADF00D).to_bytes(4, "little")
dst.write_bytes(data)
print(f"Wrote BAD magic 0xBAADF00D into header of {dst.name}")
PY
make_hex "$HEADER_BAD_BIN"
run_sim "attack_bad_magic"

echo ""
echo "[5/5] Attack #3: Strip signature (all zeros)"
ZERO_SIG_BIN="$BUILD_DIR/firmware_zero_sig.bin"
python3 - "$GOOD_BIN" "$ZERO_SIG_BIN" <<'PY'
import sys, pathlib
src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
data = bytearray(src.read_bytes())
hdr_offset = 0xFFC0
sig_offset = hdr_offset + 0x20
sig_len = 32
if len(data) < sig_offset + sig_len:
    raise SystemExit("Firmware image missing signature.")
for i in range(sig_offset, sig_offset + sig_len):
    data[i] = 0
dst.write_bytes(data)
print(f"Zeroed signature region in {dst.name}")
PY
make_hex "$ZERO_SIG_BIN"
run_sim "attack_zero_sig"

echo ""
echo "Restoring known-good firmware image"
make_hex "$GOOD_BIN"

echo ""
echo "All tests complete. Logs available under: $LOG_DIR"
