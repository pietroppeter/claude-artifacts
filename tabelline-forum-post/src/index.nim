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
nbReview(tversion = 1, tpage = "tabelline-forum-post", tsource = "tabelline-forum-post/src/post.md")

nbTitle "Draft · 10 November 2026", "tabelline on the Nim forum", """
The post that announces [tabelline](https://pietroppeter.github.io/tabelline/) 0.1 on the Nim
forum: first as it will look, then the text to paste. Comment on it with **✎ Review**.
"""
nbVersion 1

nbNote """
**Title:** tabelline: great tables for Nim · **Category:** Project Showcase. The two images are
in this page's branch, linked by commit, so their addresses keep working after the merge.
"""

nbText "## The post"
nbPost "post.md"

nbText "## The text to paste"
nbPaste "post.md"

nbText """
## To check before posting

- **Francesco**: the post names him by first name only. Add his GitHub handle if he is happy to be tagged.
- **Images**: the forum takes `.. image:: url` (reStructuredText). If it shows the line instead
  of the image, use a plain link.
- **How it was made**: the nanuq post gave tokens, hours and days. Add them here too, if you
  have them for tabelline.
"""

nbSave
