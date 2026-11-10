# tabelline-forum-post page sources

The Nim forum post that announces tabelline 0.1, with the review mode.

- `post.md`: the post, as it is pasted in the forum (Markdown fences, `.. image::` for images).
- `index.nim`: the nimib page that shows it and writes `../index.html`; `page.nim`: its blocks.
- `docs_table.nim`: the code in the post that makes its Markdown table (`nim r -p:<tabelline>/src docs_table.nim`); its output is pasted in `post.md`.
- `shots/`: the two screenshots the post links (by commit, on raw.githubusercontent.com).
- It reuses nimconf-schedules' dependencies and style (Munari), and the shared review mode in `shared/review/` (`config.nims`).

```sh
(cd ../../nimconf-schedules/src && sh deps.sh)
nim r -d:release index.nim
```

Then from the repository root run the post-build tools (see AGENTS.md).
