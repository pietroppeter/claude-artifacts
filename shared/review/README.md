# The review mode, shared

One copy of tabelline's review mode for every page of this repository that has a **✎ Review**
button, so they all have the same version. It will move to nimib; until then it comes from
[tabelline](https://github.com/pietroppeter/tabelline) (`docs/review.nim`, `docs/assets/review.js`),
copied unchanged.

- `review.nim`, `assets/review.js`: tabelline's, as they are at the commit in `VERSION`.
- `stile.nim`: the one function `review.nim` imports from tabelline's `docs/stile.nim` (`scoped`).
- `sync.sh`: copies all three again, from tabelline's `main` or a commit you give it.

Don't edit these files: change the review mode in tabelline, then run the sync. A page uses it
by putting this folder on its path in `src/config.nims` and calling `nbReview` after `nbInit`:

```nim
switch("path", thisDir() / ".." / ".." / "shared" / "review")   # config.nims
```

```nim
import review
nbInit
nbReview(tversion = 1, tpage = "my-page", tsource = "my-page/src/index.nim")
```

Pages that use it: `a-month-with-claude`, `nimconf-schedules`, `tabelline-forum-post`.

## Updating it

```sh
sh shared/review/sync.sh            # or: sh shared/review/sync.sh <tabelline commit>
```

Then rebuild each page above (its `src/README.md` says how), run the post-build tools of
AGENTS.md, and publish the pages that changed.
