## Part one: the month in seven acts (from tabelline's devlog, 7 Nov 2026).
const bar = "var(--rosso)"   # the curtain red of the page
let d = monthData()
var repos: CountTable[string]
for i in 0 ..< d.nrows: repos.inc $d["repo", i]
let byAct = prsByAct()

nbText: &"""
Since Opus 5.5 came out, Pietro has been writing open source with Claude, mostly from his phone.
From 20 September to 7 November that made **{d.nrows} pull requests and issues** in
**{repos.len} public repositories**, his own and a few of others. That is too much to show, and
this article does not try: no dashboard, no grid, no chart of every day. It picks.

It picks three things: the acts the month falls into, one moment from each act, and the parts
of a way of working that each act added. The last are the point. They are what the second part
puts together and names: [Operetta](#part-two).

This is also the first time tabelline is used on real data, by its own *use it* thread for 0.1
(see the [roadmap](https://pietroppeter.github.io/tabelline/roadmap/)): every table below is a tabelline table, and what it was
missing is at the end.

### Seven acts

An operetta is a light opera: an overture, a few acts, an interlude, a finale, songs between
spoken parts. The month had that shape.
"""

block:
  type ActRow = object
    act, story: string
    prs: int
  var rows: seq[ActRow]
  for a in acts:
    rows.add ActRow(act: &"**{a.name}**<br>{a.english}<br>{a.dates}",
                    story: &"{a.story}<br>**One moment:** {a.moment}", prs: byAct[a.key])
  let t = tabella(rows, rownameCol = "act"):
    tabHeader "The month in seven acts", "20 September to 7 November 2026"
    colsLabel {"story": "what happened", "prs": "PRs"}
    fmtMarkdown ["act", "story"]
    fmtBar "prs", color = bar, width = "2.5em", showValue = true
    colsWidth {"act": "24%"}
    tabFootnote "Pull requests and issues opened in the act, public repositories only.", loc.columnLabels("prs")
    tabSourceNote md("From GitHub's search API; the selection of acts and moments is by hand.")
  nbTable t

nbText: """
Two things stand out. The busiest act is nanuq, Polars for Nim, which went from a first proof
of concept to 0.6 in six days. And the acts overlap: the talk ran under everything, and the
workshop and the games shared the same week. A thread for each piece of work, in a project for
each subject, is what made that possible: Claude carries one task while Pietro reads another.

Where the work went, repository by repository, is the one count worth showing. Here it is in
the three languages of tabelline's explainers: Nim with tabelline, Python with Great Tables, R
with gt.
"""

nbTabs(python = """
import polars as pl
from great_tables import GT

prs = pl.read_csv("data/month-prs.tsv", separator="\t", quote_char=None)
top = (prs.with_columns(pl.col("repo").str.replace("pietroppeter/", ""))
          .group_by("repo").len("prs")
          .sort("prs", descending=True).head(7))
(GT(top, rowname_col="repo")
    .tab_header("Where the work went", "the seven busiest of 30 repositories")
    .cols_label(prs="PRs and issues")
    .fmt_nanoplot("prs", plot_type="bar"))
""", r = """
library(gt)
library(dplyr)

prs <- read.delim("data/month-prs.tsv", quote = "")
top <- prs |>
  mutate(repo = sub("pietroppeter/", "", repo)) |>
  count(repo, name = "prs", sort = TRUE) |>
  head(7)
gt(top, rowname_col = "repo") |>
  tab_header("Where the work went", "the seven busiest of 30 repositories") |>
  cols_label(prs = "PRs and issues") |>
  fmt_nanoplot(prs, plot_type = "bar")
"""):
  nbCode:
    let prs = readCsv(monthTsv, sep = '\t')
    var counts: CountTable[string]
    for i in 0 ..< prs.nrows:
      counts.inc ($prs["repo", i]).replace("pietroppeter/", "")
    counts.sort()
    var top: seq[tuple[repo: string, prs: int]]
    for repo, n in counts:
      if top.len < 7: top.add (repo, n)
    let t = tabella(top, rownameCol = "repo"):
      tabHeader "Where the work went", "the seven busiest of 30 repositories"
      colsLabel {"prs": "PRs and issues"}
      fmtBar "prs", color = "var(--rosso)", width = "9em"
  nbTable t

nbText: """
Six of the seven were started in these seven weeks. The talk is the exception: started in
August, it is the one piece of work that runs through the whole month.

### What grew

The month's real output is not in the counts. In every act a problem came up, a part of the way
of working was made to solve it, and the next project copied it. Here is each part where it
first shows up, in a pull request title:
"""

block:
  type PartRow = object
    act, part, what, born: string
  var rows: seq[PartRow]
  for p in parts:
    var label = ""
    for a in acts:
      if a.key == p.act: label = &"{a.name} · {a.english}"
    rows.add PartRow(act: label, part: &"**{p.name}**", what: p.plain,
                     born: &"[{p.born.replace(\"talk-sailing-seas-scientific-nim\", \"talk\")}#{p.pr}]({prUrl(p.born, p.pr)})<br>{p.date}")
  let t = tabella(rows, rownameCol = "part", groupnameCol = "act"):
    tabHeader "The parts of a way of working", "where each first appears"
    colsLabel {"what": "what it is", "born": "first in"}
    fmtMarkdown ["part", "born"]
    colsWidth {"part": "26%", "born": "24%"}
    tabFootnote "Tried for nimib (closed, kept for later), and the subject of the third part.", loc.stub(rows = where(it["part"] == "**Skills**"))
    tabSourceNote md("Some parts existed earlier in a smaller form; this is where they first get a pull request of their own.")
  nbTable t

nbText: """
Read top to bottom, the table tells how the way of working was built: first what any repo needs
when it is made in throwaway cloud sessions (a setup script, pages built by CI, a line saying
AI was used), then places to think in (explainers, artifacts), then ways to agree with Claude
before building (specs, a backlog, proposals in their own PRs), and last the parts that only a
library growing toward a reference needs (a coverage map, a book of ports, design posts, three
threads per release).

### How the work went

Behind the tables there is one loop, and it is the same in every act:

1. **An idea becomes a page.** An explainer, often a claude-artifacts page made on the phone:
   the affinity propagation animation, the diagrams history, declarative dragging. Reading a
   page is how Pietro thinks with Claude.
2. **The page becomes a repo** when the idea holds. zogyn and diagrammari started as
   artifacts; parloku as a notebook.
3. **The repo grows living documents**: an explainer, the specs, a coverage map, a roadmap.
   They say how things are *now*, and are rebuilt on every push.
4. **The devlog keeps the story**: dated posts, written while the decisions are fresh.
5. **Previews close the loop**: a published page, read on the phone, with a link to the exact
   part that changed. Nothing reaches `main` without a "go".

### What it leaves

Two questions, each with a part of its own:

- **Can the parts be picked, rather than all copied?** nanuq used almost every one; cadero, a
  furniture plan, needed few; a talk needs different ones. The second part,
  [Operetta, a first sketch](#part-two), lists the parts as modules and says which to pick
  for what.
- **What are skills, and where do they go?** They were tried once and set aside. The third part,
  [Skills, from the beginning](#part-three), starts from the simplest idea and ends with what
  Operetta could do with them.

### What tabelline was missing

This part used tabelline as a user would, and sent what it found to the thread that builds 0.1:
"""

block:
  type Gap = object
    what, how: string
  let rows = @[
    Gap(what: "No TSV reader that leaves quotes alone",
        how: "`readCsv(sep = '\\t')` works, but a `\"` in the middle of a title starts a quoted field and the quotes vanish (`next to \"live\"` reads `next to live`). Python needs `quote_char=None`, R `quote = \"\"`."),
    Gap(what: "No count or group-by",
        how: "Expected: tabelline is not a data frame library. A `CountTable` did the job; with nanuq it would be one line."),
    Gap(what: "Small Markdown, no HTML",
        how: "`fmtMarkdown` knows `<br>` but escapes any other tag (a `<small>` showed as text); an `html()` cell format would help. It also turned `~` and `^` into sub- and superscripts even with a space inside: fixed in 0.1 (#10)."),
    Gap(what: "Markdown in a group label",
        how: "Row group labels come from the data as plain text; `fmtMarkdown` reaches cells, not groups, so act names stay plain."),
    Gap(what: "No nanoplot for single values",
        how: "`fmtBar` covers it here. Great Tables and gt draw a single value as a bar with `fmt_nanoplot(plot_type=\"bar\")`, planned for 0.4."),
    Gap(what: "A colour from the page",
        how: "`fmtBar(color = \"var(--blu, var(--pen))\")` works because the colour goes into a style attribute, so a page's CSS variables reach it. Worth saying so in the docs."),
  ]
  let t = tabella(rows, rownameCol = "what"):
    tabHeader "Gaps found by this part"
    colsLabel {"how": ""}
    fmtMarkdown "how"
    colsWidth {"what": "30%"}
  nbTable t

nbText: """
### How this article is built

The page is a nimib notebook, `docs/devlog/month_of_building.nim`, built with the others by
`nim r -d:release docs/all.nim`. Its data comes in three layers:

- **The raw data** is `docs/devlog/data/month-prs.tsv`: one line per pull request or issue that
  Pietro opened between 20 September and 7 November, with its date, repository, number, state
  and title. It comes from GitHub's search API (`author:pietroppeter`, once with `is:pr` and
  once with `is:issue`). Search also returns private repositories, so each repository's
  visibility was checked and the private ones were dropped before the file was written.
- **The selection** is `docs/mese.nim`, written by hand: the seven acts (name, dates, story, one
  moment, the repositories that belong to it) and the nineteen parts (what each is, and the
  pull request where it first appears). `actOf` puts every pull request in an act: by its
  repository when that belongs to one act, by its date otherwise.
- **The tables** are tabelline: each `tabella(rows, ...)` call takes a `seq` of Nim objects or
  tuples, one field per column. `rownameCol` makes the stub, `groupnameCol` the row groups,
  and `fmtMarkdown` turns `**bold**`, links and `<br>` in the cells into HTML. The bars are
  `fmtBar`, coloured with the page's own CSS variables. `tabella` is a macro: it makes the table
  with `initTabella`, then reads its indented body one line at a time, so that `tabHeader
  "Title"` becomes `t = t.tabHeader("Title")`. The rest is plain Nim: the verbs are procs.

Nothing is fetched while the page is built: the TSV is in the repository, so the page builds
offline and the same way every time.
"""

