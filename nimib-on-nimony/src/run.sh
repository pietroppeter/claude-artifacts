#!/bin/sh
# Runs the experiment and writes its results to data/, which the page reads.
# NIMONY: a nimony checkout (default ./nimony), built with `nim c -r src/hastur/hastur build all` and
# `bin/hastur build jorogumo`; DEPS: the pinned deps of ../../nimony-evolution/src (its deps.sh).
set -u
here=$(cd "$(dirname "$0")" && pwd)
NIMONY=${NIMONY:-$here/nimony}; DEPS=${DEPS:-${NIMONY_EVO_DEPS:-$here/../../nimony-evolution/src/deps}}
nimony=$NIMONY/bin/nimony
out=$here/data; mkdir -p "$out"
git -C "$NIMONY" log -1 --format='%h %cs' > "$out/nimony_commit.txt"
$nimony --help 2>&1 | head -1 > "$out/nimony_version.txt"
nim -v | head -1 > "$out/nim_version.txt"
# 1. nimiboth: a small page built by both compilers must come out the same
cd "$here/t"
rm -f hello.html; nim r --hints:off hello.nim > /dev/null 2>&1 && mv hello.html "$out/hello_nim2.html"
rm -f hello.html; $nimony c -r hello.nim > /dev/null 2>&1 && mv hello.html "$out/hello_nimony.html"
cmp -s "$out/hello_nim2.html" "$out/hello_nimony.html" && echo same > "$out/hello_same.txt" || echo different > "$out/hello_same.txt"
# 2. the first errors of the real thing, one module at a time
P=""; for d in tabelline nanuq nimib fusion markdown parsetoml jsony; do P="$P -p:$DEPS/$d/src"; done
check() { # name dir file
  (cd "$2" && $nimony check $P "$3" 2>&1) | grep 'Error' | grep -v 'nifmake\|FAILURE' | head -4 | sed -e "s#$DEPS/##g" -e "s#$NIMONY/#nimony/#g" > "$out/check_$1.txt"
}
check page "${PAGE:-$here/../../nimony-evolution/src}" index.nim
check pathutils "$DEPS/nimib/src" nimib/pathutils.nim
check logging "$DEPS/nimib/src" nimib/logging.nim
check sugars "$DEPS/nimib/src" nimib/nimibSugars.nim
check markdown "$DEPS/markdown/src" markdown.nim
check jsony "$DEPS/jsony/src" jsony.nim
check tabelline "$DEPS/tabelline/src" tabelline/colors.nim
check parsetoml "$DEPS/parsetoml/src" parsetoml.nim
# 3. a small module, compiled by Nimony: its NIF at every stage, for the explorer
cd "$here/nif" && rm -rf nimcache && $nimony c -r sample.nim > "$out/sample_output.txt" 2>&1
mkdir -p "$out/nif"
for st in p s; do cp nimcache/*.$st.nif "$out/nif/sample.$st.nif"; done
for st in x c; do cp nimcache/c/*/$(ls nimcache/*.p.nif | sed 's#.*/##; s#\.p\.nif##').$st.nif "$out/nif/sample.$st.nif"; done
rm -rf nimcache sample
# 4. this page, built by both: which lines differ
cd "$here"
nim r --hints:off index.nim > /dev/null 2>&1 && cp ../index.html "$out/explainer_nim2.html"
wc -c < .nimiboth/nifx.js > "$out/js_bytes_nim2.txt"
$nimony c -r index.nim > /dev/null 2>&1 && cp ../index.html "$out/explainer_nimony.html"
wc -c < .nimiboth/nifx.js > "$out/js_bytes_nimony.txt"
noscript() { awk '/^<script>$/{s=1} !s{print} /^<\/script>$/{s=0}' "$1"; }   # the compiled JS differs, of course
noscript "$out/explainer_nim2.html" > "$out/a.html"; noscript "$out/explainer_nimony.html" > "$out/b.html"
diff "$out/a.html" "$out/b.html" | grep '^<' > "$out/explainer_diff.txt"
grep -c '' "$out/explainer_diff.txt" > "$out/explainer_difflines.txt"
rm -f "$out/a.html" "$out/b.html"
rm -f "$out/explainer_nim2.html" "$out/explainer_nimony.html"
echo done
