#!/bin/sh
# Fetches the Nim dependencies at pinned commits into $NIMANIM_AFFINITY_DEPS
# (default ./deps, not committed); config.nims puts them on the path.
#   nimanim + cairo: the animation (src/scene.nim). nimanim gets
#     patches/nimanim-write-fix.patch, which fixes write() (see the page).
#   nimib + fusion, markdown, parsetoml, jsony: the page (src/index.nim).
set -e
here=$(cd "$(dirname "$0")" && pwd)
deps=${NIMANIM_AFFINITY_DEPS:-$here/deps}
mkdir -p "$deps"
while read -r name repo commit; do
  d="$deps/$name"
  if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null)" != "$commit" ]; then
    rm -rf "$d" && git init -q "$d"
    git -C "$d" fetch -q --depth 1 "https://github.com/$repo" "$commit"
    git -C "$d" checkout -q FETCH_HEAD
    if [ -f "$here/patches/$name-write-fix.patch" ]; then
      git -C "$d" apply "$here/patches/$name-write-fix.patch"
    fi
  fi
done <<DEPS
nimanim himanshm/nimanim 378a4596c630b24d7f9a68c426261e76744fccd4
cairo nim-lang/cairo 87c56bfce4be5ed978a8a7520503d0e76a7995dd
nimib pietroppeter/nimib cf850ee33409859a22b03ed15792a17b12056406
fusion nim-lang/fusion 562467452b32cb7a97410ea177f083e6d8405734
markdown soasme/nim-markdown 995405b78fb49b7658b7f0d94efe1b52f86c0a85
parsetoml NimParsers/parsetoml d297f5a81be2472905d367aa675dcbbca6e7a5d2
jsony treeform/jsony ce1ea84458c721947bd8e86ec065eeefab2656f1
DEPS
