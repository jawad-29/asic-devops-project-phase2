#!/bin/bash

set -e

echo "================================="
echo "Running RTL Simulation"
echo "================================="

echo "Compiling RTL and testbench..."

iverilog -o sim.vvp \
    src/counter.v \
    TestBench/counter_tb.v

echo "Compilation successful."
echo "Running simulation..."

vvp sim.vvp

echo "================================="
echo "RTL Simulation Completed"
echo "================================="
