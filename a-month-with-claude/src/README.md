# a-month-with-claude page sources

One article in three parts, made with [nimib](https://github.com/pietroppeter/nimib) and
[tabelline](https://github.com/pietroppeter/tabelline). The parts were first posts in tabelline's
devlog (7 Nov 2026) and moved here on 8 Nov 2026.

- `index.nim`: the nimib document that writes `../index.html`: the cover, then `include`s the parts.
- `part1.nim` (the month in seven acts), `part2.nim` (Operetta), `part3.nim` (skills).
- `mese.nim`: the hand-made selection: acts, moments, the nineteen parts of the way of working.
- `data/month-prs.tsv`: every PR and issue Pietro opened from 20 Sep to 7 Nov 2026, public
  repositories only (GitHub search API: `author:pietroppeter created:>2026-08-15 is:pr`, and `is:issue`;
  each repository's visibility checked, private ones dropped).
- `data/openspec.tsv`, `data/openspec-propose-head.yaml`: sizes of the OpenSpec skills and commands in
  tabelline's `.claude/`, and the top of one skill, as they were on 7 Nov 2026.
- `style.nim`: the page CSS (a theatre programme), inlined in place of nimib's theme; no remote fonts.
- The review mode (**✎ Review** under the programme) is the shared one in `shared/review/` at the
  root of the repository (`config.nims` puts it on the path).
- `deps.sh`: fetches tabelline, nimib and their dependencies at pinned commits into `deps/` (not
  committed); `config.nims` puts them on the path.

Needs Nim 2.x on `PATH` and libpcre (PCRE1). From the page folder:

```sh
sh src/deps.sh
nim c -r -d:release src/index.nim   # writes index.html
```
