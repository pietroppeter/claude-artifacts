# conda-for-nim page sources

Conda as Nim's package manager: how nimble, atlas and nimby work, modern conda for a newcomer,
an interactive race (`lib/race.js`), a proof of concept (`poc/`), a survey of Nim already in
conda (`data/`), other ecosystems, effort and next steps. A
[nimib](https://github.com/pietroppeter/nimib) page; tables by
[tabelline](https://pietroppeter.github.io/tabelline/).

- Build the page from this folder: `pixi run page` (Nim, gcc and pcre from conda-forge; runs
  `deps.sh` first), or `sh deps.sh && nim r -d:nimibQuiet index.nim` with a system Nim 2.2+
  and `libpcre3`. Writes `../index.html`. Then run the post-build tools of AGENTS.md.
- `poc/run.sh`: the whole PoC on linux-64, writing every terminal of the page to `poc/out/`.
  It bootstraps pixi and rattler-build from conda-forge with a static micromamba, runs
  `nimforge.nim` (packages.json + git tags + `.nimble` → `recipes/nim-*/recipe.yaml`), builds
  them into `poc/channel` with rattler-build, uses them from `poc/demo` (a nimib page), links
  zlib from conda-forge (`poc/zdemo`), packages nimby (`poc/apps/nimby`) and times nimble
  against pixi. `poc/feedstock.sh` builds Nim 2.4.2 with the `NIMBLE_DIR` activation
  (`poc/feedstock/nim`, about 10 minutes).
- `data/bioconda_nim.json`: the bioconda survey, from a sparse checkout of bioconda-recipes
  (recipes whose `meta.yaml` requires `nim` or whose `build.sh` runs `nim c`/`nimble`).
- `lib/style.nim`: every colour and rule (prefix.dev/pixi-inspired); `lib/blocks.nim`: the
  page's blocks; `lib/race.js`: the interactive, plain JavaScript.
- The review mode is tabelline's, from `shared/review/` at the root of the repository.
