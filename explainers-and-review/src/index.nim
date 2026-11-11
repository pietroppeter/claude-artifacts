## A short explainer: tabelline's way of working (explainers in nimib, Operetta's parts, the review
## mode) and how it applies to the playful repos, zogyn and parloku. Writes ../index.html.
import std/os
import nimib
import style, review

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.usePage("Explainers, review mode and the playful repos",
           "How tabelline works (an explainer for every task, Operetta's parts, the review mode) and what it means for zogyn and parloku.")
nbReview(tversion = 1, tpage = "explainers-and-review", tsource = "explainers-and-review/src/index.nim")

nbTitle "11 November 2026 · overture", "Explainers, review mode, and the playful repos", """
What I read in tabelline before starting the animation research: every piece of work gets a
page that explains it, the page is reviewed on the phone with **✎ Review**, and the rest of
the repo keeps the page true. Then what that means for zogyn and parloku.
"""
nbVersion 1

nbNote """
**In one line.** *The explainer is where the thinking happens; every other part keeps it true*
(from [Operetta, a first sketch](../a-month-with-claude/index.html#part-two)). This page is itself
an explainer for one task, and it has the review mode: tap **✎ Review**, select words, comment,
**Export**, paste in the thread.
"""

nbText: """
## What I saw in tabelline

[tabelline](https://pietroppeter.github.io/tabelline/) (great tables for Nim) is the most
complete example of the way of working, and the place where it is changing fastest.

- **An explainer before the code.** *The Great Explainer* (`docs/explainer.nim`) says what gt
  and Great Tables are, how they work inside, who uses them, and builds a first tabelline step
  by step. It is the site's Guide and is *kept up to date*: a living page.
- **Three threads for every release.** One builds it, one *uses it* on real data (a story told
  in tables), one ports reference code. The two documents find what the code misses: calls users
  write all the time, names that read badly, a bug in a corner.
- **Living pages and dated posts.** The guide, the specs, the feature map and the roadmap are
  kept up to date; a devlog post is dated and never rewritten. A big design change starts as a
  devlog post.
- **Specs with examples that run.** Every requirement about the API has a ```` ```nim ```` block
  and the ```` ```text ```` it prints, checked by `tools/specexamples.nim`. A spec that lies
  breaks the build.
- **Blocks, not HTML.** A page is Markdown, nimib's blocks and the project's own blocks; CSS and
  colours live in one style module, and `tools/drift.nim` fails a page that grows HTML.

These are the parts of **Operetta** ([part two of A month with Claude](../a-month-with-claude/index.html#part-two)):
not a template, a list of small parts (Scena, Prove, Partitura, ...) a project picks from.
claude-artifacts is the *Prove* part, *Artifact first*: a quick page on the phone before there
is a repo.

## The review mode, the new piece

Reviewing a page on a phone used to mean screenshot, chat, back to the page, wait for the
artifact to load, again for every comment. The review mode puts the comments on the page:

1. **✎ Review** opens it. The page shows its *Version N* (the number of commits that changed
   its source).
2. Select a few words and tap **Comment ✓**, or write a **Page note** with nothing selected.
   Notes are kept in the browser as you type, and can hold a pasted screenshot.
3. **‹** and **›** go through the comments; **Export** gives one text: a YAML block
   (`format: nimib-review/5`, the page, its source file, version and commit) and one Markdown
   section per comment, with the quoted words and the words around them.
4. That text is pasted in the chat, and the agent follows the skill `nimib-review`: find each
   quote in the notebook, check what changed since that commit, make the change, close the round.

Today it lives in tabelline (`docs/review.nim`, `docs/assets/review.js`). claude-artifacts uses
one shared copy of it in `shared/review/`, synced from tabelline, never edited here. It is written
as one module in English so it can move to nimib as it is, with a release; then every nimib page,
zogyn's and parloku's included, gets it with one line, `nbReview()`.

## How it applies to the playful repos
"""

nbText: """
| Part | parloku today | zogyn today | Next step |
|---|---|---|---|
| Artifact first | yes: previews as artifacts before every merge | the port began as `declarative-dragging-nim` here | keep: research and POCs start here |
| Explainer | `spiega`, the builder how-to, the devlog posts | the docs page (`docs/src/index.nim`) | zogyn gets an explainer of animation; each POC gets one |
| Living pages and devlog | garden pages (living) and dated devlog posts | none | zogyn: a devlog, starting with the animation POCs |
| Specs that run | OpenSpec, with ```` ```drag ```` scenarios played by `specdrag.nim` | tests only | zogyn: runnable examples, as tabelline's spec examples, when the API settles |
| Blocks, not HTML | partly: `style.nim` holds the look | the docs style module | follow nimib-blocks in new pages |
| Review mode | none yet | none yet | on every new page now (shared copy); on all pages once it is in nimib |
"""

nbText: """
Three things follow for this thread and the ones after it:

- **Every task gets its explainer, with the review mode on.** The animation research is a nimib
  page with things that move, written in Nim compiled to JavaScript, and so is each proof of
  concept. Each page shows its version, so a review round is easy to follow.
- **Research first, then a shortlist, then one thread per approach.** As tabelline's three
  threads, each POC thread owns one page and reports what it found back to the research page,
  which is the living one. The POC pages are dated, like devlog posts.
- **zogyn stays a library.** Animation, if it lands, is a zogyn module (draggable things that
  also move well); parloku's snakes and dances are its first users, not part of it.
"""

nbText: """
## Where to read more

- [The Great Explainer](https://pietroppeter.github.io/tabelline/explainer/), tabelline's guide.
- [Review mode](https://pietroppeter.github.io/tabelline/devlog/review-mode/), the devlog post
  reviewed with itself, round by round.
- [Three threads for every release](https://pietroppeter.github.io/tabelline/devlog/three-threads/).
- [A month with Claude](../a-month-with-claude/index.html), with Operetta in part two.
- Next: [Animating things in Nim](../animating-in-nim/index.html), the research explainer this
  page leads to.
"""

nbSave
