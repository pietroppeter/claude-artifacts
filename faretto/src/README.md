# faretto page sources

Pharo's liveness explained to a Nim programmer, and **faretto**, a toy live VM that runs the
type-checked NIF that [Nimony](https://github.com/nim-lang/nimony) writes. A
[nimib](https://github.com/pietroppeter/nimib) page; tables by
[tabelline](https://pietroppeter.github.io/tabelline/).

- `index.nim`: the page, writes `../index.html`. Build from this folder:
  `sh deps.sh && nim r -d:nimibQuiet index.nim` (Nim 2.2.4, `libpcre3`, and Nimony's `nimony`
  on the PATH or in `$NIMONY`: `git clone https://github.com/nim-lang/nimony && cd nimony &&
  nim c -r src/hastur/hastur build all`). Every faretto block runs at build time; the page also
  builds the command line VM and the playground's JavaScript, and times Nimony's native code.
- `faretto/nif.nim`: reads and writes NIF. `faretto/vm.nim`: the image (method dictionary by
  symbol, object table, globals, change log), the interpreter, inspector, `become`, MetaLinks,
  halt/restart, saving and loading the image as NIF; no `os`, so it also compiles to JS.
  `faretto/live.nim`: `nimony check` a module and load the `.s.nif` (`boot`, `accept`).
- `faretto.nim`: the command line VM, `faretto <image.nif> <proc> [args] [--save]`.
- `examples/lanterna.nim`: the lighthouse, an ordinary Nim module (it compiles with Nimony too).
- `lib/playground.nim`: the lighthouse in the page (`nim js`); `lib/build.nim`: build-time helpers;
  `lib/blocks.nim`: the page's blocks; `lib/style.nim`: every colour and rule.
- The review mode is tabelline's, from `shared/review/` at the root of the repository (`config.nims`).
- Then run the post-build tools of AGENTS.md.
