## The draft of the post that announces tabelline 0.1 on the Nim forum, with the review mode.
## The post itself is `post.md` (what is pasted in the forum); this page shows it and writes
## ../index.html. Build: see README.md.
import std/os
import nimib except md
import page, vendor/review

const srcDir = currentSourcePath().parentDir

nbInit
nb.doc.filename = srcDir.parentDir / "index.html"
nb.usePage("tabelline on the Nim forum", "A draft of the post that announces tabelline 0.1 on the Nim forum.")
nbReview(tversion = 3, tpage = "tabelline-forum-post", tsource = "tabelline-forum-post/src/post.md")

nbTitle "Draft · 10 November 2026", "tabelline on the Nim forum", """
The post that announces [tabelline](https://pietroppeter.github.io/tabelline/) 0.1 on the Nim
forum: first as it will look, then the text to paste. Comment on it with **✎ Review**.
"""
nbVersion 3, "10 November 2026, after the second review"

nbNote """
**Title:** tabelline: beautiful display tables for Nim · **Category:** Project Showcase. The two images are
in this page's branch, linked by commit, so their addresses keep working after the merge.
"""

nbText "## The post"
nbPost "post.md"

nbText "## The text to paste"
nbPaste "post.md"

nbText """
## To check before posting

- **Images**: the forum takes `.. image:: url` (reStructuredText). If it shows the line instead
  of the image, use a plain link.
- **Links**: gt and Great Tables are Markdown links. If the forum shows the brackets, use bare URLs.
"""

nbText """
## The reviews

Each review round, as exported, and what it changed.
"""
nbRound "process/review-v1.md", "Review of version 1: four comments. Version 2 is much shorter (the details stay in the pages), says *beautiful display tables*, and links gt and Great Tables."

nbRound "process/review-v2.md", "Review of version 2: two comments. Version 3 drops the line on Francesco and shows tabelline at desktop width with *Show the parts* on, its legend included."

nbSave
