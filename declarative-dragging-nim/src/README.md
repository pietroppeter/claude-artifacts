# declarative-dragging-nim page sources

- `index.nim`: the [nimib](https://github.com/pietroppeter/nimib) document that writes `../index.html`.
  Engine and model blocks use `nbCodeAnd(nbJsFromCode)`: they run natively at build time (the printed
  outputs and the filmstrip) and are also compiled with `nim js` into the page's script.
- `style.nim`: the page CSS, inlined in place of nimib's default theme (no external stylesheets).
- `deps.sh`: fetches nimib and its dependencies at pinned commits into `deps/` (not committed);
  `config.nims` puts them on the path.

Needs Nim 2.x (built with 2.2.4) on `PATH` (nimib calls `nim js`) and libpcre (PCRE1) for `std/re`. From the page folder:

```sh
sh src/deps.sh
nim c -r -d:release src/index.nim   # writes index.html
```

Gotcha: nimib ships `nbJsFromCode` bodies through the AST's `repr`, which drops the parentheses around
inline `if` expressions used as arguments (`f(if a: b else: c)`), so the JS build fails. Bind them with `let` first.
