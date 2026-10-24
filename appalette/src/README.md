# appalette page sources

The page is built from Nim compiled to JS: affinity propagation from
[naffprop](https://github.com/pietroppeter/naffprop) and CIEDE2000 from
[chroma](https://github.com/treeform/chroma), both fetched at pinned commits
by `deps.sh` (naffprop's `matrix.nim` gets `patches/naffprop-matrix-js.patch`
so it compiles to JS).

To rebuild, with Nim 2.2 on PATH (e.g. `pip install nimlang`):

```sh
sh deps.sh
python3 tools/build_demo.py   # writes demo/site/index.html
```

Then wrap `demo/site/fragment.html` as `../index.html` (the root CLAUDE.md
says how). `images/` holds the example images, already resized; sources and
licenses are in `images/sources.json` (all public domain or CC0).

The full project (command-line tool, tests, Python cross-checks, research
notes) is not published yet.
