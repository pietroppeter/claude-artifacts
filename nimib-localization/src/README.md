# nimib-localization page sources

Localizing nimib pages: a survey, three API sketches, and **lingua**, a prototype that this page
uses for itself (English, with an Italian catalog).

- `index.nim`: the nimib document that writes `../index.html`.
- `lingua.nim`: the prototype. Cuts the text of every `nbText` into chunks, looks each up in a
  gettext catalog (`<lang>.po`), draws every language with a switch in the header (or one file
  per language with `nbSaveEach`), and runs `nbEach` bodies once per language. Standard library
  and nimib only.
- `it.po`: the Italian catalog. The build adds new messages with an empty `msgstr` and moves
  unused ones to the `#~` entries at the end; fill the empty ones and build again. Entries
  marked `# machine` were translated by Claude and not reviewed: delete the mark when reviewed.
- `page.nim`: the page's blocks; its look is Munari, from `nimconf-schedules/src/style.nim`.
- The review mode is the shared one (`shared/review/`).
- `deps.sh`: fetches nimib, tabelline and their dependencies at pinned commits into `deps/`.

Needs Nim 2.x on `PATH` and libpcre (PCRE1). From this folder:

```sh
sh deps.sh
nim r -d:release index.nim     # writes ../index.html and updates it.po
```

Then from the repository root run the post-build tools (see AGENTS.md).
