#!/bin/bash

set -e

echo "================================================"
echo "RUNNING DESIGN QUALITY & SAFETY CHECKS"
echo "================================================"

echo ""
echo "----- Basic Design Checks -----"

if [ ! -f "src/counter.v" ]; then
    echo "[FAIL] RTL source file not found."
    exit 1
fi
echo "[PASS] RTL source file exists."

if [ ! -f "TestBench/counter_tb.v" ]; then
    echo "[FAIL] Testbench not found."
    exit 1
fi
echo "[PASS] Testbench exists."

if grep -q "posedge rst" src/counter.v; then
    echo "[PASS] Reset path detected in RTL."
else
    echo "[FAIL] Reset path not detected."
    exit 1
fi

if grep -q "output reg \[3:0\] count" src/counter.v; then
    echo "[PASS] Counter output width is 4 bits."
else
    echo "[FAIL] Unexpected counter output width."
    exit 1
fi

echo ""
echo "----- ISO 26262-Inspired Safety Checks -----"

if grep -q "always @(posedge clk or posedge rst)" src/counter.v; then
    echo "[PASS] Synchronous clock and asynchronous reset structure detected."
else
    echo "[FAIL] Expected clock/reset structure not detected."
    exit 1
fi

if grep -q "count <= 4'b0000" src/counter.v; then
    echo "[PASS] Defined reset state detected."
else
    echo "[FAIL] Defined reset state not detected."
    exit 1
fi

if grep -q "count <= count + 1'b1" src/counter.v; then
    echo "[PASS] Deterministic counter increment logic detected."
else
    echo "[FAIL] Expected counter behavior not detected."
    exit 1
fi

if grep -q "PASS:" TestBench/counter_tb.v; then
    echo "[PASS] Explicit verification evidence detected in testbench."
else
    echo "[FAIL] Verification evidence not detected."
    exit 1
fi

echo ""
echo "================================================"
echo "DESIGN QUALITY & SAFETY CHECKS PASSED"
echo "================================================"
echo ""
echo "NOTE: These are ISO 26262-inspired safety checks."
echo "They do not constitute formal ISO 26262 compliance."
