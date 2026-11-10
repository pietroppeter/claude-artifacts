#!/bin/sh
# Fetches nimib, tabelline and their dependencies at pinned commits into
# $NIMCONF_DEPS (default ./deps, not committed); config.nims puts them on the path.
set -e
here=$(cd "$(dirname "$0")" && pwd)
deps=${NIMCONF_DEPS:-$here/deps}
mkdir -p "$deps"
while read -r name repo commit; do
  d="$deps/$name"
  if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null)" != "$commit" ]; then
    rm -rf "$d" && git init -q "$d"
    git -C "$d" fetch -q --depth 1 "https://github.com/$repo" "$commit"
    git -C "$d" checkout -q FETCH_HEAD
  fi
done <<DEPS
tabelline pietroppeter/tabelline 4657f10804d622590d97c66c0aca69923f026a2c
nimib pietroppeter/nimib 7cfe29cefd76b5110a0c7798f540b8c693b065cf
fusion nim-lang/fusion 0b0a0273b8df860cd54e3fcca7bb4c617244ac77
markdown soasme/nim-markdown 5a7a7bafd1da23b25332316a7b888e6586f4177a
parsetoml NimParsers/parsetoml d297f5a81be2472905d367aa675dcbbca6e7a5d2
jsony treeform/jsony bb647e1ca21af25ffdc423bcb96feeeeae963ca2
DEPS
