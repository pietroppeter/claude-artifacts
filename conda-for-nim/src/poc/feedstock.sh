#!/bin/sh
# Nim 2.4.2 from source with conda's compilers, plus the NIMBLE_DIR activation: the change the
# conda-forge feedstock needs. Takes about 10 minutes (koch boot + tools). Writes out/09-feedstock.txt.
# Run after run.sh (same tools): sh feedstock.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
tools=${CONDA_NIM_TOOLS:-$here/.tools}
work=${CONDA_NIM_WORK:-$here/.work}
export PATH="$tools/bin:$PATH" NO_COLOR=1 CLICOLOR=0 TERM=dumb
export RATTLER_CACHE_DIR="$work/rattler-cache-feedstock"
cd "$here"
rattler-build build --recipe-dir feedstock --output-dir channel -c conda-forge > "$work/feedstock.log" 2>&1
{
  printf '$ rattler-build build --recipe-dir feedstock --output-dir channel -c conda-forge\n'
  grep -E 'Artifact:|NIMBLE_DIR|nim --version|Nim Compiler Version|nimble v|hello|all tests passed' "$work/feedstock.log" |
    sed -e 's/^[ │╭╰─]*//' -e "s|$here|.|g" | grep -v '^+ export' | head -20
  printf '$ pixi exec -c ./channel -c conda-forge --spec "nim==2.4.2" -- sh -c '\''nim --version | head -1; echo $NIMBLE_DIR'\''\n'
  pixi exec -c "$here/channel" -c conda-forge --spec "nim==2.4.2" -- sh -c 'nim --version | head -1; echo $NIMBLE_DIR' 2>&1 |
    sed -e "s|$HOME|~|g"
} > out/09-feedstock.txt
cat out/09-feedstock.txt
