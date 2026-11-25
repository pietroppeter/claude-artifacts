# futureverse-nim page sources

Henrik Bengtsson's R futureverse (future, future.apply, furrr, progressr, parallelly, futurize),
explained to a Nim programmer by building a toy version, `fv`, and running every example on it
when the page is built. A [nimib](https://github.com/pietroppeter/nimib) page; tables by
[tabelline](https://pietroppeter.github.io/tabelline/).

- `index.nim`: the page, writes `../index.html`. Build from this folder:
  `sh deps.sh && sh deps-r.sh && nim r -d:nimibQuiet index.nim` (Nim 2.2.4, `libpcre3`, and R with
  `Rscript` on the PATH, e.g. `apt-get install r-base-core`; built with R 4.3.3). The R blocks run at
  build time too (`nbR` in `lib/blocks.nim`): `deps-r.sh` installs future, futurize, future.apply,
  progressr, progressify and parallelly from CRAN into `$FV_RLIB` (default `./deps/Rlib`). `deps.sh` pins nimib,
  tabelline, malebolgia, taskpools and their dependencies into `$FV_DEPS` (default `./deps`, not committed).
  The page calls `fvServe()` before `nbInit`: the `processes` plan starts the page binary itself as its workers.
- `fv.nim`: the toy. `plan(sequential() | threads(n) | processes(n))`, `futureMap(xs, f, seed, progress)`,
  `say`, `gauss`, `dice`, `registerTask`, `fvServe`, `availableCores`, the `futurize` and `transpiled` macros and `|>`.
- `examples/tasks.nim`: the four tasks the page maps (registered for worker processes).
- `lib/blocks.nim`: the page's blocks (prompt, notes, R code, steps, compile errors, sources); `lib/style.nim`: every colour and rule.
- The review mode is tabelline's, from `shared/review/` at the root of the repository (`config.nims`).
- Then run the post-build tools of AGENTS.md.
