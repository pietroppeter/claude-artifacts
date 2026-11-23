# nimony-evolution page sources

How [Nimony](https://github.com/nim-lang/nimony), the compiler that becomes Nim 3, evolved: from the NIR survey of
2023 to avoidtemps (22 Nov 2026), told from the Nim forum threads, the repo history (commit `36bde262`) and Araq's blog,
with every term explained in a card where it first shows up. A [nimib](https://github.com/pietroppeter/nimib) page;
tables by [tabelline](https://pietroppeter.github.io/tabelline/).

- `index.nim`: the page, writes `../index.html`. Build: `sh deps.sh && nim r index.nim` (Nim 2.2, `libpcre3`).
  `deps.sh` pins nimib, tabelline and their dependencies into `$NIMONY_EVO_DEPS` (default `./deps`, not committed).
- `lib/blocks.nim`: the page's blocks (term cards, timeline events, the pipeline, notes, quotes, chapters);
  `lib/style.nim`: every colour and rule.
- The review mode is tabelline's, from `shared/review/` at the root of the repository (`config.nims`).
- Then run the post-build tools of AGENTS.md.
