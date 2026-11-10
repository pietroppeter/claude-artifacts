Hi, I just released tabelline 0.1, beautiful display tables for Nim:

https://pietroppeter.github.io/tabelline/

It follows R's [gt](https://gt.rstudio.com/) and Python's [Great Tables](https://posit-dev.github.io/great-tables/): the same parts of a table and the same verbs in camelCase, written in plain Nim. Tables render to HTML, text and Markdown, and go straight into a nimib page. The name comes from *le tabelline*, the times tables of Italian primary school.

On the site you find a Guide, a Book that ports the gt and Great Tables guides, stories told with tables (Milano Cortina 2026 and FOSDEM), the roadmap, a devlog and a design guide.

.. image:: https://raw.githubusercontent.com/pietroppeter/claude-artifacts/7141f2a1bc354e9230287fbc35c9772bfbabc0b2/tabelline-forum-post/src/shots/tabelline-parts.png

As a small celebration I put every NimConf schedule, 2020 to 2026, in tabelline tables:

https://pietroppeter.github.io/claude-artifacts/nimconf-schedules/

.. image:: https://raw.githubusercontent.com/pietroppeter/claude-artifacts/21b7dbded2ad7fea642453c413ac0e8a837ce9ab/tabelline-forum-post/src/shots/nimconf-2026.png

That page also has a review mode for nimib pages: press ✎ Review, select some text, comment, and export all the comments to paste to a coding agent.

Made with Claude, mostly from my phone.

I really enjoyed working on this: the reference API is beautiful and I think every language deserves a port of it! The moment I had the idea of the review mode (yesterday morning) it was pretty clear, and it was so much fun iterating on it while using it (see the devlog post: https://pietroppeter.github.io/tabelline/devlog/review-mode/).
