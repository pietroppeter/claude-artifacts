#!/bin/sh
# Fetches nimib, its dependencies and nanoarrow at pinned commits into
# $PUSCICA_DEPS (default ./deps, not committed); config.nims puts them on the path.
set -e
here=$(cd "$(dirname "$0")" && pwd)
deps=${PUSCICA_DEPS:-$here/deps}
mkdir -p "$deps"
while read -r name repo commit; do
  d="$deps/$name"
  if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null)" != "$commit" ]; then
    rm -rf "$d" && git init -q "$d"
    git -C "$d" fetch -q --depth 1 "https://github.com/$repo" "$commit"
    git -C "$d" checkout -q FETCH_HEAD
  fi
done <<DEPS
tabelline pietroppeter/tabelline 47ba07b659481d408ad7be66e6bec7ef6b4c911f
nimib pietroppeter/nimib 4ecc850178665244328e383f1cae488234fc8d1e
fusion nim-lang/fusion 562467452b32cb7a97410ea177f083e6d8405734
markdown soasme/nim-markdown 995405b78fb49b7658b7f0d94efe1b52f86c0a85
parsetoml NimParsers/parsetoml d297f5a81be2472905d367aa675dcbbca6e7a5d2
jsony treeform/jsony ce1ea84458c721947bd8e86ec065eeefab2656f1
arrow-nanoarrow apache/arrow-nanoarrow 9fad80292360d0f3978264c11ba865ccc94020d8
DEPS
# nanoarrow 0.9.0 as single C files (nanoarrow.c, nanoarrow_ipc.c, flatcc.c), compiled into the page
if [ ! -f "$deps/nanoarrow-bundle/src/nanoarrow_ipc.c" ]; then
  python3 "$deps/arrow-nanoarrow/ci/scripts/bundle.py" --output-dir "$deps/nanoarrow-bundle" --with-ipc --with-flatcc >/dev/null
fi
