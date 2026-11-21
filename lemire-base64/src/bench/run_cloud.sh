#!/bin/bash
# Lemire's mimebench, plus Nim, on whatever this machine has.
# Usage: ./run_cloud.sh > results_cloud_runN.txt
set -e
PIN=${PIN:-"taskset -c 2"}
uname -srm; grep -m1 "model name" /proc/cpuinfo; g++ --version | head -1; head -1 expected.txt
$PIN ./build/bench_cpp
$PIN build/gobench
$PIN build/zigbench 2>&1
env -u _JAVA_OPTIONS $PIN java -cp build Bench 2>&1 | grep -v JAVA_TOOL
$PIN node bench.mjs
$PIN bun bench.mjs
$PIN php bench.php
$PIN python3 bench.py
(cd nim && $PIN ./bench_nim)
