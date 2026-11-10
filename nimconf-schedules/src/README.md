# nimconf-schedules page sources

Every NimConf schedule as tables, made with [nimib](https://github.com/pietroppeter/nimib) and
[tabelline](https://github.com/pietroppeter/tabelline).

- `index.nim`: the nimib document that writes `../index.html`.
- `nimconf.nim`: the editions (typed by hand: day, schedule page, playlists) and the procs that
  download and read the pages; the post shows them. Standard library only.
- `fetch.nim`: runs them for every edition and writes `data/`.
- `data/slots.tsv`: every row of every schedule (talk, break, end of track), from
  conf.nim-lang.org (`/2020/`, `/2021/`, `/2022/`, `/2024/`, and the root for 2026), read 10 Nov 2026.
- `data/videos.tsv`: every video of the NimConf playlists on YouTube, with its length, read the same day.
- `cache/`: the pages as downloaded, not committed (they carry the sites' analytics scripts,
  whose integrity hashes secret scanners flag); `data/` keeps everything read from them.
- Where the data is missing or does not agree is written in the page, *Where the data comes from*.
- `blocks.nim`: the page's custom blocks; `style.nim`: every colour and font, the two looks
  (Munari and NimConf); `fonts/`: Jost, Open Sans, Titillium Web (OFL, licenses beside them).
- The review mode is tabelline's, from `shared/review/` at the root of the repository (`config.nims`).
- `deps.sh`: fetches tabelline, nimib and their dependencies at pinned commits into `deps/` (not
  committed); `config.nims` puts them on the path.

Needs Nim 2.x on `PATH` and libpcre (PCRE1). From this folder:

```sh
sh deps.sh
nim r -d:ssl fetch.nim        # writes data/ (reads cache/ first)
nim r -d:release -d:ssl index.nim   # writes ../index.html
```

Then from the repository root run the post-build tools (see AGENTS.md).
