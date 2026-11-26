## The draft of the post that announces tabelline 0.1 on the Nim forum, with the review mode.
## The post itself is `post.md` (what is pasted in the forum); this page shows it and writes
## ../index.html. Build: see README.md.
import std/os
import nimib except md
import page, review

const srcDir = currentSourcePath().parentDir

nbInit
nb.doc.filename = srcDir.parentDir / "index.html"
nb.usePage("tabelline on the Nim forum", "The post that announced tabelline 0.1 on the Nim forum, and how it was written.")
nbReview(tpage = "tabelline-forum-post", tsource = "tabelline-forum-post/src/post.md")

nbTitle "10 November 2026", "tabelline on the Nim forum", """
The post that announced [tabelline](https://pietroppeter.github.io/tabelline/) 0.1 on the Nim
forum, as the forum shows it, then its source, and the review rounds that shaped it with
**✎ Review**.
"""
nbVersion()

nbNote """
**Posted** on 10 November 2026: [tabelline: beautiful display tables in Nim](https://forum.nim-lang.org/t/14280),
in Project Showcase. The text below is the post as it is on the forum; the images are in this
page's branch, linked by commit.
"""

nbText "## The post"
nbPost "post.md", "tabelline: beautiful display tables in Nim", "Project Showcase", "pietroppeter"

nbText "## Its source"
nbPaste "post.md"

nbText """
## What the forum showed

- Markdown tables and links work, and `.. image::` with `:width:` works.
- Colours don't pass: `toMarkdown` drops every style (Markdown has none), and the forum shows no
  HTML colour (an inline `span` and the `raw` directive were both tried). Emoji do pass.
"""

nbText """
## The reviews

Each review round, as exported, and what it changed.
"""
nbRound "process/review-v1.md", "Review of version 1: four comments. Version 2 is much shorter (the details stay in the pages), says *beautiful display tables*, and links gt and Great Tables."

nbRound "process/review-v2.md", "Review of version 2: two comments. Version 3 drops the line on Francesco and shows tabelline at desktop width with *Show the parts* on, its legend included."
nbRound "process/review-v3.md", "Review of version 3: two comments. Version 4 links the docs at the top (GitHub is linked from there), lists the stories, the devlog and the design guide, ends with your paragraph on why you enjoyed it, and says the review mode will move to nimib."
nbText "Version 5 is Pietro's own edit of version 4 (what display tables are, the plans, the looks, the name), with a third image: the Guide's first table in the quaderno look."

nbText "Version 6 is Pietro's second edit, with the docs as a Markdown table made by tabelline (`docs_table.nim`, beside the post; its output is pasted in `post.md`)."

nbText "Version 7 is the post as Pietro published it on the forum, with his last edits."

nbSave
