#!/bin/sh
# Fetches the Nim dependencies at pinned commits into $APPALETTE_DEPS
# (default ./deps, not committed); config.nims puts them on the path.
#   chroma:   treeform/chroma, colors and CIEDE2000 (chroma/distance.nim)
#   naffprop: pietroppeter/naffprop, affinity propagation (src/naffprop/ap.nim)
# naffprop's matrix.nim gets a small patch so that it also compiles to JS
# (patches/naffprop-matrix-js.patch), for the in-browser demo.
set -e
here=$(cd "$(dirname "$0")" && pwd)
deps=${APPALETTE_DEPS:-$here/deps}
mkdir -p "$deps"
while read -r name repo commit; do
  d="$deps/$name"
  if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null)" != "$commit" ]; then
    rm -rf "$d" && git init -q "$d"
    git -C "$d" fetch -q --depth 1 "https://github.com/$repo" "$commit"
    git -C "$d" checkout -q FETCH_HEAD
    if [ -f "$here/patches/$name-matrix-js.patch" ]; then
      git -C "$d" apply "$here/patches/$name-matrix-js.patch"
    fi
  fi
done <<DEPS
chroma treeform/chroma 08b0d65590221bb964544fd9badf29a146b9091a
naffprop pietroppeter/naffprop a25a6834069436cbd1c124c01b37fadfda1e00fd
DEPS
