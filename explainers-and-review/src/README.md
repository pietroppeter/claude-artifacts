# explainers-and-review page sources

A short explainer: the way of working of tabelline (explainers in nimib, Operetta's parts, the
review mode) and how it applies to the playful repos, zogyn and parloku.

- `index.nim`: the nimib page that writes `../index.html`; `style.nim`: its look (a theatre
  programme, for Operetta) and its few blocks.
- It reuses nimconf-schedules' dependencies, and the shared review mode in `shared/review/`.

```sh
(cd ../../nimconf-schedules/src && sh deps.sh)
nim r -d:release index.nim
```

Then from the repository root run the post-build tools (see AGENTS.md).
