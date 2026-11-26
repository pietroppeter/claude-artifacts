#!/bin/bash
# The whole proof of concept, start to finish, on linux-64. Every terminal on the page is a
# file in out/, written by this script. Run from this folder: bash run.sh
# Needs: curl, git, a C compiler only for the comparison with nimble (`nim` + `nimble` on PATH).
# Everything else (pixi, rattler-build, nim, gcc, zlib) comes from conda-forge.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
out=$here/out
tools=${CONDA_NIM_TOOLS:-$here/.tools}
work=${CONDA_NIM_WORK:-$here/.work}
export NO_COLOR=1 CLICOLOR=0 PIXI_COLOR=never TERM=dumb
mkdir -p "$out" "$work"

# Print a command, run it, keep what it printed; paths are shortened to stay readable.
term() {
  file=$1; shift
  { for cmd in "$@"; do
      printf '$ %s\n' "$cmd"
      sh -c "$cmd" 2>&1 || printf '(exit %s)\n' "$?"
    done; } | sed -e "s|$here|.|g" -e "s|$work|/tmp/w|g" -e "s|$HOME|~|g" \
      -e 's/\x1b\[[0-9;]*[a-zA-Z]//g' > "$out/$file"
  cat "$out/$file"
}

# 0. pixi and rattler-build, from conda-forge, with a static micromamba (no installer script)
if [ ! -x "$tools/bin/pixi" ]; then
  mkdir -p "$work/mm"
  curl -sL https://conda.anaconda.org/conda-forge/linux-64/micromamba-2.10.0-0.tar.bz2 | tar xj -C "$work/mm" bin/micromamba
  MAMBA_ROOT_PREFIX=$work/mm "$work/mm/bin/micromamba" create -y -q -p "$tools" -c conda-forge pixi rattler-build
fi
export PATH="$tools/bin:$PATH"
export PIXI_HOME="$work/pixi-home"
rm -rf "$PIXI_HOME"
# a fresh package cache: rebuilt packages keep their name and build string, and a cache that
# remembers the old hash refuses them
export RATTLER_CACHE_DIR="$work/rattler-cache"
rm -rf "$RATTLER_CACHE_DIR" "$here/channel"
TIMEFORMAT='%R s'
timed() { { time ( eval "$1" > /dev/null 2>&1 ) ; } 2>&1; }

# 1. Nim from conda-forge, today: a fresh pixi workspace
rm -rf "$work/hello" && mkdir -p "$work/hello"
printf 'echo "hello from Nim ", NimVersion, ", installed by conda"\n' > "$work/hello/hello.nim"
term 01-pixi-add-nim.txt \
  "cd $work/hello && pixi init --platform linux-64 . > /dev/null && pixi add nim" \
  "cd $work/hello && pixi run nim c -r --hints:off hello.nim" \
  "cd $work/hello && pixi run 'echo \$GCC'" \
  "cd $work/hello && pixi list | grep -E '^(nim|gcc_linux|sysroot|openssl|pcre) '"

# 2. The gap: no nim for osx-arm64 or win-64 on conda-forge
term 02-osx-arm64.txt \
  "cd $work/hello && pixi workspace platform add osx-arm64 | tail -4"

# 3. nimforge: packages.json + git tags + .nimble files -> recipe.yaml
[ -f "$here/packages.json" ] || curl -s https://raw.githubusercontent.com/nim-lang/packages/master/packages.json -o "$here/packages.json"
term 03-nimforge.txt \
  "cd $here && nim r --hints:off nimforge.nim nimib pixie" \
  "cd $here && ls recipes"

# 3b. a deeper tree, only for the race on the page (recipes written, not built)
term 03b-graphs.txt "cd $here && nim r --hints:off nimforge.nim --out:graphs fidget2 | wc -l"

# 4. rattler-build every recipe into a local channel; each test imports the module in a fresh env
term 04-rattler-build.txt \
  "cd $here && rattler-build build --recipe-dir recipes --output-dir channel -c ./channel -c conda-forge 2>&1 | grep -E 'Artifact:|all tests passed' | sed 's/^[ │╭╰─]*//' | sort | uniq -c | sed 's/^ *1 //'" \
  "cd $here && ls channel/noarch"

# 5. A pixi project that uses the channel: a nimib page, no nimble anywhere
rm -rf "$here/demo/.pixi" "$here/demo/pixi.lock"
term 05-demo.txt \
  "cd $here/demo && cat pixi.toml" \
  "cd $here/demo && pixi run page 2>&1 | grep -v Warning" \
  "cd $here/demo && grep -o 'no nimble involved' hello.html | head -1" \
  "cd $here/demo && pixi tree nim-nimib" \
  "cd $here/demo && pixi run 'echo \$NIMBLE_DIR; ls \$NIMBLE_DIR/pkgs2'"
term 05-lock.txt "cd $here/demo && grep -A13 '^- conda: .*nim-nimib-0.4.3' pixi.lock"

# 6. Timings: nimble against pixi, for nimib and its four dependencies
rm -rf "$work/nb"
nb_t=$(timed "cd $work && NIMBLE_DIR=$work/nb nimble install -y nimib@0.4.3")
rm -rf "$here/demo/.pixi" "$work/cold"
cold_t=$(timed "cd $here/demo && RATTLER_CACHE_DIR=$work/cold pixi install")
rm -rf "$here/demo/.pixi"
warm_t=$(timed "cd $here/demo && pixi install")
term 06-timings.txt \
  "nimble --version | head -1" \
  "echo 'nimble install -y nimib@0.4.3, empty NIMBLE_DIR:  $nb_t'" \
  "echo 'pixi install, empty package cache:              $cold_t'" \
  "echo 'pixi install, warm package cache:               $warm_t'" \
  "du -sh $here/demo/.pixi $work/cold"
rm -rf "$work/cold"

# 7. Nim + a C library from conda-forge: zlib, headers and .so in the env
term 07-zlib.txt \
  "cd $here/zdemo && cat pixi.toml" \
  "cd $here/zdemo && pixi run nim c --hints:off --nimcache:$work/zcache -o:$work/crc crc.nim && $work/crc" \
  "ldd $work/crc | grep libz"

# 8. A compiled Nim app as a conda package: nimby, installed by pixi global
term 08-nimby.txt \
  "cd $here && rattler-build build --recipe-dir apps/nimby --output-dir channel -c conda-forge 2>&1 | grep -E 'Artifact:|libgcc .*RE of' | sed 's/^[ │╭╰─]*//'" \
  "pixi global install -c $here/channel -c conda-forge nimby" \
  "$PIXI_HOME/bin/nimby --help | head -4"
