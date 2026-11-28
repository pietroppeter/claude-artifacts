#!/bin/sh
# Runs every comparison of the page and writes ../data/. Needs Nim >= 2.2.10 (openparser asks for it),
# libpcre3 (nim-markdown's std/re), python3 (only to reuse CommonMark's own HTML normalizer).
#   sh deps.sh && sh run.sh [folders with .md files for the real-world corpus]
set -e
here=$(cd "$(dirname "$0")" && pwd); cd "$here"
deps=${MO_BENCH_DEPS:-$here/deps}; data=$here/../data
mkdir -p bin
for f in cm_nimmd gfm_nimmd cm_marv gfm_marv tt_parsetoml tt_optoml tjson_op bench; do
  nim c -d:release -o:bin/$f $f.nim
done
nim r cases.nim
# CommonMark 0.31.2 (655 examples) and the GFM extensions (22), normalized as cmark's own tests do
python3 "$deps/commonmark-spec/test/spec_tests.py" --spec "$deps/commonmark-spec/spec.txt" --dump-tests > spec.json
python3 "$deps/cmark-gfm/test/spec_tests.py" --spec "$deps/cmark-gfm/test/spec.txt" --dump-tests 2>/dev/null |
  python3 -c "import json,sys; json.dump([x for x in json.load(sys.stdin) if 'extension' in x['section']], sys.stdout)" > gfm_ext.json
MO_BENCH_DEPS="$deps" python3 runspec.py spec.json bin/cm_nimmd bin/cm_marv > "$data/commonmark.tsv"
MO_BENCH_DEPS="$deps" python3 runspec.py gfm_ext.json bin/gfm_nimmd bin/gfm_marv > "$data/gfm.tsv"
# real-world corpus: every .md file of 1 KB or more in the folders given
if [ $# -gt 0 ]; then
  find "$@" -name '*.md' -size +1k -not -path '*/deps/*' -not -path '*/node_modules/*' -not -path '*/.git/*' > corpus.txt
  MO_BENCH_DEPS="$deps" python3 realworld.py corpus.txt bin/gfm_nimmd bin/gfm_marv > "$data/realworld.tsv"
fi
# TOML: the toml-test suite, TOML 1.0 and 1.1 file lists
{ printf "library\tspec\tvalid accepted\tvalid\tinvalid rejected\tinvalid\n"
  for lib in parsetoml optoml; do for v in 1.0.0 1.1.0; do
    printf "%s\t%s\t%s\n" $lib $v "$(bin/tt_$lib "$deps/toml-test/tests" files-toml-$v)"; done; done; } > "$data/toml.tsv"
bin/tjson_op > "$data/json_roundtrip.txt"
# two spec examples that make nim-markdown raise an IndexDefect (and stop a nimib page build)
for x in '[link](foo(and(bar))' '[a](<b)c>'; do
  printf '%s\t%s\n' "$x" "$(printf '%s\n' "$x" | bin/gfm_nimmd 2>&1 | tail -1)"
done > "$data/crash.tsv"
printf "file\tKB\tnim-markdown ms\tmarvdown ms\n" > "$data/speed.tsv"
for f in "$deps/markdown/README.md" "$deps/marvdown/README.md" "$deps/cmark-gfm/README.md" "$deps/toml-test/README.md"; do
  bin/bench "$f" >> "$data/speed.tsv"
done
