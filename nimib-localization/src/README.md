# nimib-localization page sources

Localizing nimib pages: a survey, three API sketches, and **lingua**, a prototype that this page
uses for itself (English, with an Italian catalog).

- `index.nim`: the nimib document that writes `../index.html`.
- `lingua.nim`: the prototype. Cuts the text of every `nbText` into chunks, looks each up in a
  gettext catalog (`<lang>.po`), draws every language with a switch in the header (or one file
  per language with `nbSaveEach`), and runs `nbEach` bodies once per language. Standard library
  and nimib only.
- `messages.pot`: the template, every message of the page with its key; `index.nim` writes it.
- `it.nim`: the translation notes, a nimib page written by Claude (`../notes-it.html`): the
  conventions, the glossary, the choices, and every message's Italian by its key. Building it
  writes `it.po`; it says which messages have no translation. Reviewing the Italian is reviewing
  this page; once a round is applied, `nb.useNotes("it", reviewed = true)` drops `# machine`.
- `notes.nim`: the blocks of the notes (`nbMsg`, `nbChoice`, `nbNotesCheck`, `nbPoFile`, `nbSaveNotes`).
- `it.po`: the Italian catalog, written by `it.nim`. Don't edit it by hand.
- `process/`: the review rounds, as exported.
- `page.nim`: the page's blocks; its look is Munari, from `nimconf-schedules/src/style.nim`.
- The review mode is the shared one (`shared/review/`).
- `deps.sh`: fetches nimib, tabelline and their dependencies at pinned commits into `deps/`.

Needs Nim 2.x on `PATH` and libpcre (PCRE1). From this folder:

```sh
sh deps.sh
nim r -d:release index.nim     # writes ../index.html and messages.pot
nim r -d:release it.nim        # writes ../notes-it.html and it.po
nim r -d:release index.nim     # again, with the new catalog
```

Then from the repository root run the post-build tools (see AGENTS.md); `notes-it.html` is not an
`index.html`, so give it to them by name:
`python3 tools/codeblocks.py nimib-localization/notes-it.html` and
`node tools/phonecheck.js nimib-localization/notes-it.html`.
