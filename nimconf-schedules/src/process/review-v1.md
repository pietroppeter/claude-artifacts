# Review of “Every NimConf, in tables”, version 1

```yaml
format: nimib-review/3
title: "Every NimConf, in tables"
page: "https://7f492dfc-8377-4ba2-b612-474ab97fba3a.frame.claudeusercontent.com/_f/1794294833-814a/"
source: "nimconf-schedules/src/index.nim"
version: 1
exported: "2026-11-10T07:42:41.203Z"
comments: 6
```

## 1. On the whole page

Dark mode does not work

Screenshots: review-v1-1-1.jpg

## 2. In “Every NimConf, in tables”

> NimConf

Around it: “…ook: Munari is tabelline's own, ⟦NimConf⟧ is the one of conf.nim-lang.org…”

Let’s put NimConf mode as default

## 3. In “The first schedule”

> optCssTheme() makes the table read its colours and font from the page (--ink, --paper, --line, --primary, --font), so it changes with the look. fmtMarkdown renders the talk's [title](link); fmtDuration writes seconds as minutes; where picks rows by their values, here the breaks, which colsHide keeps in the data but out of sight.

Around it: “…20, lengths from YouTube. ⟦optCssTheme() makes the table read its colours and font from the page (--ink, --paper, --line, --primary, --font), so it changes with the look. fmtMarkdown renders the talk's [title](link); fmtDuration writes seconds as minutes; where picks rows by their values, here the breaks, which colsHide keeps in the data but out of sight.⟧ Sixteen talks, the first at…”

This card has a green line above we should pick a different color for this code explaining cards in dark mode

Screenshots: review-v1-3-1.jpg

## 4. In “Where the data comes from”

> Where the data is missing, or does not agree.

Around it: “… Social and Workflow blog ⟦Where the data is missing, or does not agree.⟧ The 2026 schedule is at the …”

Also warning card has to have a better color

Screenshots: review-v1-4-1.jpg

## 5. In “How this page is built”

> How this page is built

Around it: “…tes ../index.html, this page ⟦How this page is built⟧ The page is a nimib document,…”

Can you add also the original prompt? This document is made by a prompt on Claude code (phone) within nimib uses tabelline and iterated on with review mode. We could add the review copy and paste in the repo and add it here at every iteration (again as folded code). In this way you have the full process on how this was made (minus all the agents and skills and stuff that is in my Claude code but that is fair

## 6. In “How this page is built”

> nimconf.nim

Around it: “…small modules sit beside it: ⟦nimconf.nim⟧, the data: the editions and the…”

Add also below the sources of files with nbCodeFold of tabelline
