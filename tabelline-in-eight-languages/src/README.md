# tabelline-in-eight-languages page sources

tabelline's devlog post *tabelline in eight languages* (`docs/devlog/polyglot.nim` in
[tabelline](https://github.com/pietroppeter/tabelline), PR #96), as one file, with Pietro's Bluesky
post about it first: the result of a one-shot experiment, published as it came out.

- `build.nim`: builds the post in a tabelline checkout with `-d:singleFile` (style, fonts and
  tabelline's review mode inlined), points its relative links at tabelline's site, adds the
  image, and writes `../index.html`.
- `bluesky.jpg`: the screenshot of the Bluesky post (resized), inlined as a data URL.

The review mode is the one tabelline's build puts in its pages, not `shared/review/`: the page
is tabelline's own, and comments on it go to its source there.

The page is the post as the thread first wrote it, at tabelline commit `954eae1` (its code then in
`experiments/polyglot/`; it moved to tabelline-polyglot the same day, and the post was corrected).
To rebuild the same page, build from that commit:

```sh
git -C ../../../tabelline checkout 954eae1   # a tabelline checkout, after its tools/setup.sh
nim r build.nim ../../../tabelline
```

Then from the repository root run the post-build tools (see AGENTS.md).
