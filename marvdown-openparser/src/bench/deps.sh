#!/bin/sh
# The libraries compared and the test suites, at pinned commits, into $MO_BENCH_DEPS
# (default ./deps, not committed); config.nims puts the libraries on the path.
set -e
here=$(cd "$(dirname "$0")" && pwd)
deps=${MO_BENCH_DEPS:-$here/deps}
mkdir -p "$deps"
while read -r name repo commit; do
  d="$deps/$name"
  if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null)" != "$commit" ]; then
    rm -rf "$d" && git init -q "$d"
    git -C "$d" fetch -q --depth 1 "https://github.com/$repo" "$commit"
    git -C "$d" checkout -q FETCH_HEAD
  fi
done <<DEPS
marvdown openpeeps/marvdown 6af1ac0ce2a63ffc5251778b1de9a092dd8f32f2
openparser openpeeps/openparser a60cce612b6ebc21be47da0f25300d4f8e611eb4
nimsimd guzba/nimsimd dd27017fbfd1c6c00d37776a8f5d322bf6c5a83b
nimcypher nimbase/nimcypher ea6722f209a9dcd7202b6ce336229e5953a9206a
dynasm nimbase/dynasm-nim 58f401a253bfab7f4542f9cd258d98fc305919c8
markdown soasme/nim-markdown 995405b78fb49b7658b7f0d94efe1b52f86c0a85
jsony treeform/jsony ce1ea84458c721947bd8e86ec065eeefab2656f1
parsetoml NimParsers/parsetoml d297f5a81be2472905d367aa675dcbbca6e7a5d2
commonmark-spec commonmark/commonmark-spec 8a5f7646e9f67c3004f023d262b3e6b596afc2ed
cmark-gfm github/cmark-gfm 7fe8904ee31fa24b772ae565c4908b1394850de6
toml-test toml-lang/toml-test 96fd088448ec0f4d9f061c730ed7854399c46faf
DEPS
