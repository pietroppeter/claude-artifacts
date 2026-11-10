Hi, I just released tabelline 0.1, beautiful display tables for Nim:

https://github.com/pietroppeter/tabelline

It follows R's [gt](https://gt.rstudio.com/) and Python's [Great Tables](https://posit-dev.github.io/great-tables/): the same parts of a table and the same verbs in camelCase, written in plain Nim. Tables render to HTML, text and Markdown, and go straight into a nimib page. The name comes from *le tabelline*, the times tables of Italian primary school, and the idea from my friend Francesco.

.. image:: https://raw.githubusercontent.com/pietroppeter/claude-artifacts/21b7dbded2ad7fea642453c413ac0e8a837ce9ab/tabelline-forum-post/src/shots/tabelline-home.png

Docs, with a Guide, a Book that ports the gt and Great Tables guides, and the roadmap: https://pietroppeter.github.io/tabelline/

As a small celebration I put every NimConf schedule, 2020 to 2026, in tabelline tables:

https://pietroppeter.github.io/claude-artifacts/nimconf-schedules/

.. image:: https://raw.githubusercontent.com/pietroppeter/claude-artifacts/21b7dbded2ad7fea642453c413ac0e8a837ce9ab/tabelline-forum-post/src/shots/nimconf-2026.png

That page also has a review mode for nimib pages: press ✎ Review, select some text, comment, and export all the comments to paste to a coding agent. How it works: https://pietroppeter.github.io/tabelline/devlog/review-mode/

Made with Claude, mostly from my phone. Feedback is welcome, especially from gt and Great Tables users.
