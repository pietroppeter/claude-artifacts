## Every NimConf schedule, in tables: a nimib page with tabelline. Writes ../index.html.
## The data is in data/ (written by fetch.nim); the procs that read the pages are in nimconf.nim,
## and the page shows them. See README.md for how to build it.
import std/[os, strutils, strformat, sequtils, algorithm, options, tables, sets]
import nimib except md
import tabelline, tabelline/nimib
import nimconf, blocks, vendor/review

const srcDir = currentSourcePath().parentDir

nbInit
nb.doc.filename = srcDir.parentDir / "index.html"
nb.usePage("Every NimConf, in tables",
           "Every schedule of NimConf, the online Nim conference, 2020 to 2026, as tables made with tabelline.")
nbReview(tversion = 4, tsource = "nimconf-schedules/src/index.nim")

let slots = readSlots(srcDir / "data" / "slots.tsv")
let videos = readVideos(srcDir / "data" / "videos.tsv")
var length: Table[string, int]      # video id: seconds
for v in videos: length[v.id] = v.seconds

func day(e: Edition): string =
  let (y, m, d) = (e.date[0 .. 3], e.date[5 .. 6].parseInt, e.date[8 .. 9].parseInt)
  &"""{d} {["January", "February", "March", "April", "May", "June", "July", "August", "September",
             "October", "November", "December"][m - 1]} {y}"""

nbTitle "10 November 2026 · a small celebration of [tabelline](https://pietroppeter.github.io/tabelline/)",
  "Every NimConf, in tables",
  """
NimConf is the Nim community's own conference: online, free, talks recorded beforehand and
premiered on YouTube while their speakers answer questions in the chat. There have been five,
and each published its schedule as a table. Here they all are again, made with
[tabelline](https://pietroppeter.github.io/tabelline/), the display tables for Nim that just
reached 0.1: from the simplest table to the two tracks of 2026, then where the data comes
from, and the Nim code that downloaded it.
"""

nbVersion 4, "10 November 2026, after the third review"
nbEditions editions.mapIt(($it.year, it.day.rsplit(' ', 1)[0]))

nbText: """
Five editions, from June 2020 to June 2026: three in June, two in October, and none in 2023
or 2025. Every one of them starts on a Saturday morning, UTC. The switch at the top of the
page changes the look: **NimConf**, the one you see first, is the look of
[conf.nim-lang.org](https://conf.nim-lang.org/); **Munari** is tabelline's own. Every table
follows it.

## The first schedule

The data of this page is a list of *slots*: a talk, a break, or the end of a track, each with
the edition, the track, its starting time in UTC, a title, the speakers and the id of its
video on YouTube. It is a Nim object, and the data is a plain `seq[Slot]`, read from
`data/slots.tsv`:
"""

nbNote("""
This part is about tabelline's code. What it uses from the data (the types `Slot` and
`Edition`, the list `editions`, the table `length` of the videos) comes from `nimconf.nim`,
explained in *How the data was downloaded*; every file of the page is folded at the end, in
*The source files*, for reference.
""")

nbCode:
  for s in slots[0 ..< 3]: echo s

nbText: """
A sequence of objects is already a table:
"""

nbCode:
  let first = slots.filterIt(it.year == 2020)[0 ..< 4]
  nbTable tabella(first)

nbText: """
That is all it takes: `tabella` turns any sequence of objects (or named tuples) into a table,
one column per field, and `nbTable` puts it in the page. It is honest and plain. A schedule
wants a bit more: a title, only the columns a reader needs, the talk linked to its video, the
length of each video (read from each edition's YouTube playlist, see step 6 of *How the data was
downloaded*: `length` maps a video's id to its seconds), and the breaks set apart. Each of
those is one verb, the same verbs as
R's [gt](https://gt.rstudio.com/) and Python's [Great Tables](https://posit-dev.github.io/great-tables/),
in camelCase:
"""

nbCode:
  type Talk = object
    kind, start, talk, speakers: string
    length: Option[int]          # seconds; none for a break

  func link(s: Slot): string =
    ## the title, linked to its video, in Markdown
    let title = s.title.replace("*", "\\*")       # Nim*AI is not emphasis
    if s.video.len == 0: title else: &"[{title}](https://youtu.be/{s.video})"

  proc talks(year: int, track = ""): seq[Talk] =
    for s in slots:
      if s.year != year or s.track != track: continue
      result.add Talk(kind: s.kind, start: s.start, talk: s.link, speakers: s.speakers,
                      length: (if s.video in length: some(length[s.video]) else: none(int)))

  let t2020 = tabella(talks(2020)):
    optCssTheme()
    optRowStriping()
    tabHeader "NimConf 2020", editions[0].day
    colsHide "kind"
    colsLabel {"start": "UTC", "talk": "Talk", "speakers": "Speaker", "length": "Video"}
    fmtMarkdown "talk"
    fmtDuration "length", outputUnits = ["minutes"]
    tabStyle style.text(color = "var(--muted)", style = "italic"),
      loc.body(rows = where(it["kind"] == "break"))
    tabSourceNote md("[conf.nim-lang.org/2020](https://conf.nim-lang.org/2020/), lengths from YouTube.")
  nbTable t2020

nbNote("""
`optCssTheme()` makes the table read its colours and font from the page (`--ink`, `--paper`,
`--line`, `--primary`, `--font`), so it changes with the look, and `optRowStriping()` shades
every other row, as conf.nim-lang.org does. The plain table above has neither, so it stays
white whatever the look. `fmtMarkdown` renders the talk's
`[title](link)`; `fmtDuration` writes seconds as minutes; `where` picks rows by their values,
here the breaks, which `colsHide` keeps in the data but out of sight.
""", nkCode)

nbText: """
Sixteen talks, the first at 11:00 UTC and the last at 20:45, with two coffee breaks and a
lunch break between them: the first NimConf was a long day. The breaks have no starting time
because the page gave them none.

## Every one-track schedule

The table for 2020 is a few lines; the same lines in a proc make the table of any edition with
one track, the four from 2020 to 2024. The buttons above the table are tabs, one per edition:
`nbTabs` is one of this page's own blocks, in `blocks.nim` (folded at the end with the other
files). 2026 had two tracks at once and needs another table: it comes next.
"""

nbCode:
  proc schedule(e: Edition): Tabella =
    tabella(talks(e.year)):
      optCssTheme()
      optRowStriping()
      tabHeader &"NimConf {e.year}", e.day
      colsHide "kind"
      colsLabel {"start": "UTC", "talk": "Talk", "speakers": "Speaker", "length": "Video"}
      fmtMarkdown "talk"
      fmtDuration "length", outputUnits = ["minutes"]
      tabStyle style.text(color = "var(--muted)", style = "italic"),
        loc.body(rows = where(it["kind"] == "break"))
      tabSourceNote md(&"[{e.page[8 .. ^1]}]({e.page}), lengths from YouTube.")

let oneTrack = editions.filterIt(it.playlists.len == 1)
nbTabs oneTrack.mapIt($it.year), "NimConf editions":
  for e in oneTrack:
    nbTable schedule(e)

nbText: """
Andreas Rumpf speaks at every edition, near the start, and his talks follow Nim: ARC/ORC in
2020, the Zen of Nim in 2021, Nim 2 in 2022, then NIF and the road to Nim 3.

## Two tracks: NimConf 2026

In 2026 there were so many talks that NimConf ran two tracks at once, *Projects* and *Social
and Workflow*, each its own YouTube playlist. Its page is a different table: one row per
starting time, one column per track, the speaker written before the title. The data keeps one
slot per talk, with its track; turning the tracks into columns is a few lines of Nim, and
tabelline puts a spanner over them:
"""

nbCode:
  type Row = object
    start, projects, social: string

  let year = editions[^1]
  var rows: seq[Row]
  for s in slots.filterIt(it.year == 2026):
    if rows.len == 0 or rows[^1].start != s.start: rows.add Row(start: s.start)
    let cell = if s.kind != "talk": &"*{s.title}*"
               elif s.speakers.len == 0: s.link
               else: &"{s.link} · *{s.speakers}*"
    if s.track == "Projects": rows[^1].projects = cell else: rows[^1].social = cell

  let t2026 = tabella(rows):
    optCssTheme()
    optRowStriping()
    tabHeader "NimConf 2026", year.day & " · two tracks"
    colsLabel {"start": "UTC", "projects": "Projects", "social": "Social and Workflow"}
    tabSpanner "Tracks", cols("projects", "social")
    fmtMarkdown ["projects", "social"]
    colsWidth {"start": "3.4em"}
    tabSourceNote md("[conf.nim-lang.org](https://conf.nim-lang.org/), videos matched by title in the two playlists.")
  nbTable t2026

nbNote("""
`tabSpanner` puts one label over several columns; `cols("projects", "social")` picks them by
name. The cell is Markdown again: the linked title, then the speaker in italics. An empty
cell is a track with nothing starting at that time.
""", nkCode)

nbText: """
Twenty-one videos (the welcome among them) between 11:00 and 16:50 UTC, the most of any
NimConf.

## Five editions side by side

With every slot in one list, a table can count across the editions: how many talks and
speakers each had, how long its videos run in all, and its longest talk.
"""

nbCode:
  type Summary = object
    edition: int
    day: string
    talks, speakers: int
    video: int
    longest: string

  var summary: seq[Summary]
  for e in editions:
    let mine = slots.filterIt(it.year == e.year and it.kind == "talk")
    var people: HashSet[string]
    for s in mine:
      for p in s.speakers.people: people.incl p
    let timed = mine.filterIt(it.video in length)
    let long = timed.sortedByIt(-length[it.video])[0]
    summary.add Summary(edition: e.year, day: e.day.rsplit(' ', 1)[0], talks: mine.len,
                        speakers: people.len, video: timed.mapIt(length[it.video]).foldl(a + b),
                        longest: &"{long.title} ({length[long.video] div 60} min)")

  let editionsTable = tabella(summary, rownameCol = "edition"):
    optCssTheme()
    optRowStriping()
    tabHeader "Five NimConfs", "2020 to 2026"
    fmtDuration "video", outputUnits = ["hours", "minutes"]
    colsHide "day"
    colsLabel {"talks": "Talks", "speakers": "Speakers", "video": "Video", "longest": "Longest talk"}
    tabStyle style.text(weight = "bold"), loc.body(cols("talks"), rows = where(it["edition"].toFloat == 2026))
    tabFootnote "Andreas Rumpf's opening talks count, the welcome videos without a speaker too.",
      loc.columnLabels(cols("talks"))
  nbTable editionsTable

nbText: """
Six to six and a half hours of video at each of the first three editions, four and a half in
2024. 2026 has the most talks and the most video, but the shortest talks: 21 minutes on
average, against 25 to 33 before. Some people came back:
"""

nbCode:
  var times: Table[string, Table[int, int]]       # speaker: edition: talks
  for s in slots.filterIt(it.kind == "talk"):
    for p in s.speakers.people:
      times.mgetOrPut(p, initTable[int, int]()).mgetOrPut(s.year, 0) += 1

  type Speaker = object
    speaker: string
    y2020, y2021, y2022, y2024, y2026: Option[int]
    editions, talks: int

  var returning: seq[Speaker]
  for p, by in times:
    if by.len < 2: continue
    func at(y: int): Option[int] = (if y in by: some(by[y]) else: none(int))
    returning.add Speaker(speaker: p, y2020: at(2020), y2021: at(2021), y2022: at(2022),
                          y2024: at(2024), y2026: at(2026), editions: by.len,
                          talks: toSeq(by.values).foldl(a + b))
  returning = returning.sortedByIt((-it.editions, -it.talks, it.speaker))

  let speakersTable = tabella(returning, rownameCol = "speaker"):
    optCssTheme()
    optRowStriping()
    tabHeader "Who came back", "speakers at two editions or more, in bold at all five"
    colsLabelWith(proc (s: string): string = s.replace("y", ""))
    tabSpanner "Talks at", startsWith("y")
    colsHide ["editions", "talks"]
    tabStyle style.text(weight = "bold", color = "var(--primary-text)"),
      loc.body(rows = where(it["editions"].toFloat == 5))
    tabStyle style.text(weight = "bold", color = "var(--primary-text)"),
      loc.stub(rows = where(it["editions"].toFloat == 5))
    colsAlign alCenter, startsWith("y")
  nbTable speakersTable

nbNote("""
`Option[int]` fields are missing values when they are `none`, and a missing value shows as an
empty cell. `colsLabelWith` relabels every column with a proc (`y2020` is `2020`), `startsWith`
picks columns by a prefix, and a style can name a colour of the page (`var(--primary-text)`),
so it changes with the look.
""", nkCode)

nbText: """
Andreas Rumpf spoke at all five, Andre von Houck (treeform) at all five too, and Peter
Munch-Ellingsen at four. Names are spelled in different ways from one page to the next (Hugo
Granstrom and Granström, Trayambak Ray and Rai): a small table by hand,
`sameSpeaker` in `nimconf.nim`, says which spellings are the same person.

## Where the data comes from

Every schedule is a page of [conf.nim-lang.org](https://conf.nim-lang.org/): one per past
edition (`/2020/`, `/2021/`, `/2022/`, `/2024/`), and the latest at the root. Every video is in
a playlist of the [Nim channel on YouTube](https://www.youtube.com/@nimprogramminglanguage3130/playlists),
one per edition and two for 2026. The days are on the pages and in the Nim blog's
announcements.
"""

nbCode:
  type Source = object
    edition: int
    schedule, playlists, announced: string

  const blog = {2020: "2020/06/19/NimConf", 2021: "2021/06/11/nim-conference",
                2022: "2022/10/21/nim-conference", 2024: "2024/10/23/nimconf-2024",
                2026: "2026/04/07/nimconf-2026"}.toTable
  var sources: seq[Source]
  for e in editions:
    var lists: seq[string]
    for (track, id) in e.playlists:
      let name = if track.len > 0: track else: "playlist"
      lists.add &"[{name}](https://www.youtube.com/playlist?list={id})"
    sources.add Source(edition: e.year, schedule: &"[{e.page[25 .. ^1]}]({e.page})",
                       playlists: lists.join(" · "),
                       announced: &"[blog](https://nim-lang.org/blog/{blog[e.year]}.html)")

  let sourcesTable = tabella(sources, rownameCol = "edition"):
    optCssTheme()
    optRowStriping()
    tabHeader "Sources", "read on 10 November 2026"
    colsLabel {"schedule": "Schedule", "playlists": "YouTube", "announced": "Announced"}
    fmtMarkdown ["schedule", "playlists", "announced"]
  nbTable sourcesTable

nbNote("""
**Where the data is missing, or does not agree.**

- The 2026 schedule is at the root of conf.nim-lang.org, and links no video: each talk's video
  was found in the two playlists by its title. All 21 were found. When the next NimConf takes
  the root, 2026 will probably move to `/2026/`; what was read is kept in `data/slots.tsv`.
- The breaks of 2020 to 2024 have no starting time on their pages, so they have none here.
- In 2022 the schedule links *Polymorph* to a video that YouTube no longer finds
  (`QHSHtFRw0CQ`); the playlist has the talk as `zCHZ0l7nLA0`, and this page links that one.
- Lengths are those YouTube showed on 10 November 2026 on the playlists' pages.
- There was no NimConf in 2023 or 2025. Before NimConf there was one Nim event in person, a
  two-day workshop with Andreas Rumpf in Kyiv, 14 and 15 November 2015
  ([announced on the blog](https://nim-lang.org/blog/2015/10/16/first-nim-conference.html));
  its page (on nimworkshop.splashthat.com) could not be read from here, and no schedule of it
  was found.
""", nkGap)

nbText: """
## How the data was downloaded

All of it is Nim, standard library only, in [`nimconf.nim`](https://github.com/pietroppeter/claude-artifacts/tree/main/nimconf-schedules/src/nimconf.nim);
[`fetch.nim`](https://github.com/pietroppeter/claude-artifacts/tree/main/nimconf-schedules/src/fetch.nim)
runs it and writes the two files of `data/`. The code shown below is the code in that file,
read from it when this page was built. From the simplest piece up:

### 1. The editions, by hand

Five facts are typed in, not downloaded: for each edition, its day, the page of its schedule
and its playlists. Everything else is read from those pages.
"""

nbSource "nimconf.nim", "editions"

nbText: """
### 2. Download a page, once

`download` gets a page with `std/httpclient` and keeps a copy in `cache/`, so the page is read
from the network only the first time (and this page can run the code below while it is
built). The proxy line is there because this was written in a sandbox whose traffic goes
through one.
"""

nbSource "nimconf.nim", "download"

nbText: """
### 3. Read a piece of HTML

The pages are small and regular, so there is no HTML parser: three procs on strings are enough.
`between` yields every piece of text between two markers (every `<tr>` of a table, every
`<td>` of a row), `plain` strips the tags from a piece and decodes the usual entities, and
`dropComments` removes the `<!-- ... -->` of a page.
"""

nbSource "nimconf.nim", "between", "plain", "dropComments"

nbText: """
`dropComments` matters for one page: the 2026 page keeps the whole 2024 schedule inside a
comment, under its own, and without it the 2024 talks would be read twice.

### 4. One track: 2020 to 2024

The four older pages share one layout: a `<table>` after the heading `id="time-schedule"`, one
row per talk with three cells (*Talk name* with its video link, *Starting time*, *Presenter*),
and a break as a row with one cell.
"""

nbSource "nimconf.nim", "scheduleTable", "oneTrack", "videoId"

nbCode:
  let page2020 = download(editions[0].page)
  for s in oneTrack(2020, scheduleTable(page2020))[0 ..< 3]:
    echo s.start, "  ", s.title, " · ", s.speakers, " · ", s.video

nbText: """
### 5. Two tracks: 2026

The 2026 table has a header that names its tracks, then one row per starting time and one
cell per track, empty when nothing starts. Each cell writes *Speaker: Title*, so the speaker is
everything before the first colon (`Andreas Rumpf:NIF, Nimony, Nim 3` has no space after
it). `schedule` picks the reader by the header of the table.
"""

nbSource "nimconf.nim", "splitSpeaker", "tracks", "schedule"

nbCode:
  let page2026 = download(editions[^1].page)
  for s in schedule(2026, page2026)[0 ..< 4]:
    echo s.start, "  ", s.track, " | ", s.title, " · ", s.speakers

nbText: """
### 6. The videos: YouTube's playlists

A playlist page of YouTube carries its data as JSON inside the page: one `lockupViewModel` per
video, with the video's id, its title and the length written on its thumbnail. Splitting the
page on that key and reading three strings out of each piece gives every video, with no API key;
`jsonText` reads a JSON string where it starts (a title can hold `\u0026` for `&`).
"""

nbSource "nimconf.nim", "playlistVideos", "jsonText", "seconds"

nbCode:
  let projects = download("https://www.youtube.com/playlist?list=" & editions[^1].playlists[0][1])
  for v in projects.playlistVideos(editions[^1].playlists[0][1])[0 ..< 3]:
    echo v.id, "  ", v.seconds div 60, " min  ", v.title

nbText: """
### 7. Match the 2026 talks to their videos

The 2026 schedule links no video, so each talk looks for one in its edition's playlists: the
title as YouTube writes it, without the speaker and the *(NimConf 2026)*, must start the
schedule's title or be started by it, ignoring case, spaces and punctuation. *Why I Nim* is
the video of *Why I Nim - a love letter to a technology that changed my life*, and
*Nimib v0.4, internals ref-actoring* of *Nimib v0.4 - internals ref-actoring*.
"""

nbSource "nimconf.nim", "videoTalk", "matchVideo"

nbText: """
### 8. All of it

`fetch.nim` runs the steps for every edition and writes `data/slots.tsv` (87 rows: every talk,
break and end of track) and `data/videos.tsv` (73 videos), each with a first line that says
where and when it was read:

```sh
cd nimconf-schedules/src
sh deps.sh                  # tabelline, nimib and their dependencies, pinned
nim r -d:ssl fetch.nim      # writes data/; delete cache/ to read the pages again
nim r -d:release index.nim  # writes ../index.html, this page
```

## How this page is built

The page is a [nimib](https://github.com/pietroppeter/nimib) document, `index.nim`: Markdown,
code that runs when the page is built (its output is under it), and tables made with
[tabelline](https://pietroppeter.github.io/tabelline/), which renders each to HTML with its
own scoped style. Three small modules sit beside it:

- `nimconf.nim`, the data: the editions and the procs above.
- `blocks.nim`, the blocks the page uses besides nimib's: the title, the cards of the editions,
  the notes, the tabs of the schedules, and the code read from a file (`nbSource`).
- `style.nim`, every colour and font: the two looks as six values each (paper, ink, primary,
  secondary, warning, success), the rest mixed from them, and the fonts inlined (Jost for
  Munari; Open Sans and Titillium Web, the fonts of conf.nim-lang.org, for NimConf). The
  NimConf look is the same rules under `html[data-look="nimconf"]`: the site's `#1e202a`
  background, its yellow `#ffe953`, its `#2b2e3b` rows and its `»` before every item.

The review mode (**✎ Review** under the lede) is tabelline's, copied into `vendor/`: select
some text, comment on it, and export the comments for the next round of this page. Nothing on
the page is loaded from elsewhere: it is one file, and it works offline.

### The prompt and the reviews

This page was asked for in three short messages, written on a phone to Claude Code in a project
that has Pietro's skills and rules (those are not copied here). Claude found the data, wrote the
code and the page, and published it; Pietro read it on his phone and commented with the review
mode. Each export is kept as it was pasted, followed by what changed in the next version (a
review can also end with no changes). In order:
"""

nbFoldCode "process/prompt.md", "The prompt, 10 November 2026"
nbFoldCode "process/review-v1.md", "Review of version 1: six comments"
nbFoldCode "process/changes-v2.md", "Version 2: what changed"
nbFoldCode "process/review-v2.md", "Review of version 2: three comments"
nbFoldCode "process/changes-v3.md", "Version 3: what changed"
nbFoldCode "process/review-v3.md", "Review of version 3: five comments"
nbFoldCode "process/changes-v4.md", "Version 4: what changed"

nbText: """
### The source files

Every file the page is made of, as it is:
"""

nbFoldCode "index.nim", tid = "source"
for file in ["nimconf.nim", "fetch.nim", "blocks.nim", "style.nim", "deps.sh", "config.nims"]:
  nbFoldCode file

nbText: """
Congratulations to tabelline on its 0.1, and thanks to everyone who gave a talk at NimConf. 👑
"""

nbSave
