#!/bin/sh
# Copies the review mode from pietroppeter/tabelline at a commit (default: main) into this folder,
# unchanged: docs/review.nim, docs/assets/review.js, and the one function review.nim takes from
# docs/stile.nim (`scoped`), into stile.nim. Writes the commit to VERSION.
#   sh shared/review/sync.sh [commit]
# Then rebuild every page that imports it (see README.md) and run the post-build tools.
set -e
here=$(cd "$(dirname "$0")" && pwd)
ref=${1:-main}
commit=$(git ls-remote https://github.com/pietroppeter/tabelline "$ref" | cut -f1 | head -1)
[ -n "$commit" ] || commit=$ref
raw=https://raw.githubusercontent.com/pietroppeter/tabelline/$commit
mkdir -p "$here/assets"
curl -fsSL "$raw/docs/review.nim" -o "$here/review.nim"
curl -fsSL "$raw/docs/assets/review.js" -o "$here/assets/review.js"
{
  echo "## Copied by sync.sh from pietroppeter/tabelline docs/stile.nim at $commit: the one"
  echo "## function review.nim imports from it. Do not edit; run sync.sh."
  echo "import std/strutils"
  echo
  curl -fsSL "$raw/docs/stile.nim" | awk '/^func scoped\*/{on=1} on&&/^[^ \t]/&&!/^func scoped\*/{exit} on'
} > "$here/stile.nim"
echo "$commit" > "$here/VERSION"
echo "review mode synced to tabelline $commit"
