# Review of “Every NimConf, in tables”, version 3

```yaml
format: nimib-review/3
title: "Every NimConf, in tables"
page: "https://7f492dfc-8377-4ba2-b612-474ab97fba3a.frame.claudeusercontent.com/_f/1794299176-026a/"
source: "nimconf-schedules/src/index.nim"
version: 3
exported: "2026-11-10T11:05:21.794Z"
comments: 5
```

## 1. On the whole page

It seems I cannot add a not to the footer. It is customary in nimib documents to show source of code, here we link to GitHub because we already embed index.nim but some way to communicate this to the user that knows about it should happen (or we just add a common show source as usual)

## 2. In “The first schedule”

> slots

Around it: “… already a table: let first = ⟦slots⟧.filterIt(it.year == 2020)[0 ..<…”

Let’s echo the slots too (first 3) so it is clear that is an object and not a dataframe or something

## 3. In “The first schedule”

> length of each video

Around it: “…e talk linked to its video, the ⟦length of each video⟧, and the breaks set apart. Each…”

Unclear how video length has been obtained

## 4. In “Every one-track schedule”

> any edition with one track

Around it: “…nes in a proc make the table of ⟦any edition with one track⟧, the four from 2020 to 2024, on…”

Let’s also mention that the buttons for editions are tabs and that all custom nimib blocks are also available at the end

## 5. In “Every one-track schedule”

> Edition

Around it: “… comes next. proc schedule(e: ⟦Edition⟧): Tabella = tabella(talks(e.y…”

Object Edition? I see it is in NimConf. Maybe early on we anticipate that all the code is below for reference and in the first part we focus only on tabelline related code
