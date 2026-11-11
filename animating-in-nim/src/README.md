# animating-in-nim page sources

The research explainer on animation for zogyn and parloku: how parloku moves today, the building
blocks (easing, tweens, springs, smoothing, constraints, timelines), declarative animation, the
libraries on the web and in game engines, the people, and a shortlist for Nim proofs of concept.

- `index.nim`: the nimib page that writes `../index.html`. Blocks in `nbCodeAnd(nbJsFromCode)`
  run natively at build time (their outputs) and are also compiled with `nim js` for the demos.
- `style.nim`: the look (an animator's desk: peg bar, timing charts, blue and red pencil) and the
  page's blocks.
- It reuses nimconf-schedules' dependencies, and the shared review mode in `shared/review/`.

```sh
(cd ../../nimconf-schedules/src && sh deps.sh)
nim r -d:release index.nim     # run from this folder: nim js reads config.nims here
```

Then from the repository root run the post-build tools (see AGENTS.md).
