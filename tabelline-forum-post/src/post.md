Hi, I just released the first version of tabelline, great tables for Nim:

https://github.com/pietroppeter/tabelline

tabelline makes display tables: tables meant to be read by people, with a header, a stub, row groups, spanners over columns, formatted numbers, colours and footnotes. It follows R's gt and Python's Great Tables, with the same parts of a table and the same verbs in camelCase (`tab_header` is `tabHeader`), written in plain Nim (nothing is wrapped). A table renders to HTML, to text and to Markdown, and `nbTable` puts it in a nimib page. The library needs only the standard library. The name comes from *le tabelline*, the times tables we learn in Italian primary school.

.. image:: https://raw.githubusercontent.com/pietroppeter/claude-artifacts/21b7dbded2ad7fea642453c413ac0e8a837ce9ab/tabelline-forum-post/src/shots/tabelline-home.png

A small example, with the text output of `echo t`:

```nim
import tabelline, tabelline/datasets

let t = tabella(planets(), rownameCol = "planet", groupnameCol = "type"):
  tabHeader md("The **planets**"), "of the Solar System"
  colsHide ["density", "gravity", "day_length", "distance", "orbital_period", "mean_temp", "rings"]
  tabSpanner "Size", ["mass", "diameter"]
  fmtNumber "mass", decimals = 3, dropTrailingZeros = true
  fmtInteger "diameter"
  tabFootnote "As of 2024.", loc.columnLabels("moons")
  tabSourceNote "NASA Planetary Fact Sheet"
echo t                 # a text table, below
t.save "planets.html"  # the HTML table, standalone
```

```
              The planets
          of the Solar System
┌─────────┬───────┬──────────┬─────────┐
│         │       Size       │         │
│         │  mass │ diameter │ moons^1 │
╞═════════╪═══════╪══════════╪═════════╡
│ Terrestrial                          │
├┄┄┄┄┄┄┄┄┄┼┄┄┄┄┄┄┄┼┄┄┄┄┄┄┄┄┄┄┼┄┄┄┄┄┄┄┄┄┤
│ Mercury │  0.33 │    4,879 │       0 │
│ Venus   │  4.87 │   12,104 │       0 │
│ Earth   │  5.97 │   12,756 │       1 │
│ Mars    │ 0.642 │    6,792 │       2 │
├─────────┼───────┼──────────┼─────────┤
│ Gas giant                            │
├┄┄┄┄┄┄┄┄┄┼┄┄┄┄┄┄┄┼┄┄┄┄┄┄┄┄┄┄┼┄┄┄┄┄┄┄┄┄┤
│ Jupiter │ 1,898 │  142,984 │      95 │
│ Saturn  │   568 │  120,536 │     146 │
├─────────┼───────┼──────────┼─────────┤
│ Ice giant                            │
├┄┄┄┄┄┄┄┄┄┼┄┄┄┄┄┄┄┼┄┄┄┄┄┄┄┄┄┄┼┄┄┄┄┄┄┄┄┄┤
│ Uranus  │  86.8 │   51,118 │      28 │
│ Neptune │   102 │   49,528 │      16 │
└─────────┴───────┴──────────┴─────────┘
1 As of 2024.
NASA Planetary Fact Sheet
```

0.1 has the basics of gt, from the data to the footer: 21 formats (from `fmtNumber` and `fmtPercent` to `fmtBytes` and `fmtDuration`, plus `fmt` with a proc of your own), styles at every location of a table (summary rows aside), `dataColor`, 56 options and 14 `opt*` presets. One thing that is not from gt is `optCssTheme()`: the table takes its colours and its font from the CSS variables of the page, so it follows the theme of the page it is in. Not there yet: summary rows and merged columns (0.2), formats in every locale (0.3), nanoplots (0.4). The API can still change before 1.0.

Docs are here: https://pietroppeter.github.io/tabelline/

There you find a Guide that explains gt and Great Tables from zero and then tabelline step by step, a Book that ports the gt and Great Tables guides page by page (the original next to the Nim version), a first story (the 2026 Winter Olympics and Paralympics of Milano Cortina, in tables), a Roadmap, a Feature map that compares tabelline with gt feature by feature, a devlog and the specs.

The whole idea was inspired by my friend Francesco, who also suggested that I announce it on the gt Discord, which I did this morning.

As a small celebration I put every NimConf schedule, from 2020 to 2026, in tabelline tables:

https://pietroppeter.github.io/claude-artifacts/nimconf-schedules/

It starts from the simplest table (a seq of objects is already a table) and goes up to the two tracks of NimConf 2026. A switch at the top changes the look between tabelline's own (Munari) and a dark one after conf.nim-lang.org, and every table follows it (that is `optCssTheme()` at work). The Nim code that downloaded the schedules and the YouTube playlists is in the page, standard library only. If a schedule or a video is wrong or missing, tell me.

.. image:: https://raw.githubusercontent.com/pietroppeter/claude-artifacts/21b7dbded2ad7fea642453c413ac0e8a837ce9ab/tabelline-forum-post/src/shots/nimconf-2026.png

One more thing I had fun building along the way: a review mode for nimib pages. On a published page you press **✎ Review**, select some text, write a comment (or the words that should replace it), and at the end you export all the comments as Markdown with a small YAML block, ready to paste to a coding agent. I review mostly on my phone, and this replaced a lot of "in the third paragraph, the sentence that starts with...". The NimConf page has it (try the ✎ Review button), and the devlog post explains how it works:

https://pietroppeter.github.io/tabelline/devlog/review-mode/

For now it lives in tabelline's docs (a Nim module and a script); it is written so that it can move to nimib.

As with nanuq, everything was made with Claude in a Claude project, mostly from my phone: one thread building each release, one using it on a real subject (the stories), one porting the gt and Great Tables guides to the book.

Feedback is very welcome, especially from people who use gt or Great Tables, and on the API while it can still change.
