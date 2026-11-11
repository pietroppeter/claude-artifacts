# tabelline in the browser

A Lustre app in Gleam that builds its tables with tabelline compiled to JavaScript (`nim js`).
Built from [tabelline-polyglot](https://github.com/pietroppeter/tabelline-polyglot)
`lustre/demo/` (commit fba254c, PR #4) with tabelline at bcdd2d6 (tabelline PR #99):

```sh
# in a tabelline-polyglot checkout, tabelline in deps/
nim r lustre/demo/build.nim        # writes lustre/demo/dist/index.html
# then, in this repository
POLYGLOT=../tabelline-polyglot nim r tabelline-in-the-browser/src/build.nim
```

`build.nim` puts the demo in `index.html` with *The code, explained* under the app: the Gleam
(and the JavaScript and Nim beneath it) read from the sources, so the page shows what runs.

Then run the post-build tools of this repository (`tools/codeblocks.py`, `tools/backlink.py`).
Once the demo is on tabelline-polyglot's own Pages, this copy can link there.
