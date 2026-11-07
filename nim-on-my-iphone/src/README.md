# nim-on-my-iphone page sources

- `index.nim`: the [nimib](https://github.com/pietroppeter/nimib) document that writes `../index.html`. It cross-compiles a
  small `core.nim` with `--os:ios --cpu:arm64 --app:staticlib --noMain --compileOnly` in a temp folder (no Mac needed for
  that step) and shows what Nim generates.
- `platinum.css`: the Platinum (classic Mac OS) theme, inlined into the page.
- `pipeline.html`, `calendar.html`, `checklist.html`: the interactive widgets (build pipeline, 7-day signing calendar,
  setup checklist), inlined at compile time.
- `deps.sh`: fetches nimib and its dependencies at pinned commits into `deps/` (not committed).

Built with Nim 1.6.14 (Nim 2.x should work too). From the page folder:

```sh
sh src/deps.sh
nim r -d:release src/index.nim   # writes index.html
```
