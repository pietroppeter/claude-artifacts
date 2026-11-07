# cartographer-nim page sources

- `carto.nim`: a minimal [Cartographer](https://github.com/BeppeTemp/cartographer)-style agentic wiki. Library plus an MCP
  server over stdio (`carto init <dir>`, `carto serve --kb <dir> [--repo name=path ...]`). Standard library and `git` only.
- `index.nim`: the [nimib](https://github.com/pietroppeter/nimib) document that writes `../index.html`. It builds a demo
  knowledge base and two code repos in a temp folder, runs the walkthrough, compiles `carto.nim`, and talks MCP to it.
  Code excerpts are read from `carto.nim` at build time. Dates are fixed (`CARTO_NOW`, `GIT_*_DATE`) so builds are reproducible.
- `style.nim`: page CSS (light and dark).
- `deps.sh`: fetches nimib and its dependencies at pinned commits into `deps/` (not committed).

Needs Nim 2.x (built with 2.2.4), `git`, and libpcre (PCRE1) for nimib. From the page folder:

```sh
sh src/deps.sh
nim c -r -d:release src/index.nim   # writes index.html
```
