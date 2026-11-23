# nimib-on-nimony page sources

Can a [nimib](https://github.com/pietroppeter/nimib) page be compiled by [Nimony](https://github.com/nim-lang/nimony)?
It can't (23 Nov 2026, Nimony 0.6.3 at `5ed7415`), so this page is written with **nimiboth**, a minimal nimib that
Nim 2 and Nimony both compile, and the published page is built by Nimony. It has a NIF explorer compiled to
JavaScript by the page's compiler (`nbJsFromCode`).

- `index.nim`: the page, writes `../index.html`. It reads the experiment's results from `data/` (committed).
- `nimiboth/`: the library. `shim.nim` holds every difference between the compilers; `plugins/codesource.nim` is the
  Nimony template plugin that gives `nbCode` its source; `jsdom.nim` the DOM bindings for `nbJsFromCode`.
- `site/`: the page's blocks and theme. The review mode is the repository's `shared/review`, read at compile time.
- `t/hello.nim`: the test page built by both compilers; `nif/sample.nim`: the module the explorer shows.
- `run.sh`: runs the experiment again into `data/` (needs a Nimony checkout in `./nimony` or `$NIMONY`, and the
  nimony-evolution page's deps from its `deps.sh` for the `nimony check` table).

Build (with `nimony` on `PATH`, since `nbJsFromCode` calls `nimony j`):

```sh
git clone https://github.com/nim-lang/nimony && (cd nimony && nim c -r src/hastur/hastur build all && bin/hastur build jorogumo)
PATH=$PWD/nimony/bin:$PATH nimony c -r index.nim     # or: nim r index.nim (Nim 2.2, nbJs via nim js)
```

Then run the post-build tools of AGENTS.md.
