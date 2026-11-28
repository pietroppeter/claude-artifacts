# marvdown-openparser page sources

Should nimib swap jsony, parsetoml and nim-markdown for George Lemon's openparser and marvdown?
What nimib uses each dependency for (and fusion), the two candidates measured against the
CommonMark spec, GitHub's extensions, the toml-test suite and real Markdown files, who makes
them and who depends on them, downstream impact, effort and a plan. A
[nimib](https://github.com/pietroppeter/nimib) page; tables by
[tabelline](https://pietroppeter.github.io/tabelline/).

- `index.nim`: the page, writes `../index.html`. Build from this folder:
  `sh deps.sh && nim r -d:nimibQuiet index.nim` (Nim 2.2, `libpcre3`). It reads every number from `data/`.
- `bench/`: the comparisons. `sh bench/deps.sh && sh bench/run.sh <folders with .md files>` rewrites
  `data/` (Nim >= 2.2.10 for openparser, `libpcre3` for nim-markdown, python3 only to reuse
  CommonMark's own `normalize.py`). The page was made with the corpus folders nimib, nimibook,
  tabelline, diagrammari, xoffy, skills and nblog checked out side by side.
  `cm_*.nim`/`gfm_*.nim`: Markdown on stdin, HTML on stdout, one per library and setting;
  `runspec.py`, `realworld.py`: the comparisons; `tt_*.nim`: toml-test; `tjson_op.nim`: nimib-like
  block round trip with openparser/json; `bench.nim`: speed; `cases.nim`: the side-by-side cards.
- `data/`: the results, plus `libs.tsv` (from the git history of each library),
  `orgs.tsv`, `dependents_own_orgs.tsv` (the nimble files of every repository of George Lemon's
  organizations, read on 28 Nov 2026) and `dependents_outside.tsv` (GitHub code search, checked by hand).
- `lib/blocks.nim`: the page's blocks (lede, notes, contents, chapters, scores, render cards);
  `lib/style.nim`: every colour and rule.
- The review mode is tabelline's, from `shared/review/` at the root of the repository (`config.nims`).
- Then run the post-build tools of AGENTS.md.
