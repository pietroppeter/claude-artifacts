# tea-in-nim page sources

The Elm Architecture (TEA) in Nim: what exists today (the [TEA catalog](https://tea.rinn7e.com/) has no Nim entry),
then TEA built from scratch with Nim 2.4's sum types, as a [nimib](https://github.com/pietroppeter/nimib) page whose
three demos run in the browser (Nim compiled to JS by nimib's `nbJsFromCode`). Tables by
[tabelline](https://pietroppeter.github.io/tabelline/).

- `tea.nim`: the page, writes `../index.html`. Build from this folder: `sh deps.sh && nim r -d:nimibQuiet tea.nim`
  with **Nim 2.4** first on the `PATH` (nimib calls `nim js` for the demos, and the page compiles its
  error snippets with `nim check`), and `libpcre3`. `deps.sh` pins nimib, tabelline and their dependencies into
  `$TEA_DEPS` (default `./deps`, not committed). Nim 2.4.2: `curl -L https://nim-lang.org/download/nim-2.4.2-linux_x64.tar.xz | tar xJ`.
- `tea/core.nim`: the types (`Attr`, `Html`, `Cmd`, `Sub`, `Program`), the `htmlFor(Msg)` helpers, `render` to a string. Both backends.
- `tea/browser.nim`: the runtime (JS only): dispatch, DOM patching by position, commands, subscriptions, the message log.
- `apps/counter.nim`, `apps/dice.nim`, `apps/stopwatch.nim`: the three programs, run natively in the page and live in the browser.
- `lib/blocks.nim`: the page's blocks (loop, demo, folded source, compile error, notes); `lib/style.nim`: every colour and rule.
- The review mode is tabelline's, from `shared/review/` at the root of the repository (`config.nims`).
- Then run the post-build tools of AGENTS.md.
