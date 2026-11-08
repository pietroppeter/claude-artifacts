## A month of building with Claude, as data: the acts of the month and the parts of the way of
## working that grew in it. Used by parts one and two of the article.
##
## The raw data is `data/month-prs.tsv`: every pull request and issue Pietro opened on
## GitHub from 20 September to 7 November 2026, in public repositories only (private ones are
## left out, by name and by count). It was made with GitHub's search API:
##
##     gh api -X GET search/issues -f q="author:pietroppeter created:>2026-08-15 is:pr" --paginate
##
## (and the same with `is:issue`). Everything else here is a selection, made by hand from it.

import std/[os, strutils, tables]
import tabelline

const monthTsv* = currentSourcePath().parentDir / "data" / "month-prs.tsv"

type
  Act* = object
    key*, name*, english*, dates*, story*, moment*: string
    repos*: seq[string]          ## the projects of the act, by repository name
  Part* = object
    key*, name*, plain*, does*: string
    born*: string                ## repository where it first appeared
    pr*: int                     ## the pull request that brought it
    date*: string
    act*: string

const gh* = "https://github.com/"

func repoUrl*(repo: string): string =
  gh & (if '/' in repo: repo else: "pietroppeter/" & repo)

func prUrl*(repo: string, n: int): string = repoUrl(repo) & "/pull/" & $n

const acts*: seq[Act] = @[
  Act(key: "ouverture", name: "Ouverture", english: "overture", dates: "20–22 Sep",
      story: "A bug in Knuth's long division in nim-lang/bigints, fixed by Claude and checked by Pietro.",
      moment: "[*\"Fix was produced by Claude… My effort was to review, understand and validate.\"*](https://github.com/nim-lang/bigints/pull/151)",
      repos: @["nim-lang/bigints"]),
  Act(key: "toulouse", name: "Atto primo", english: "act one: Toulouse", dates: "4–8 Oct",
      story: "At the Agile Lab Nomads in Toulouse, Nim meets Python: `uv add nimlang` puts a Nim compiler in any Python project, and libraries ship as wheels.",
      moment: "[naffprop](https://github.com/pietroppeter/naffprop): affinity propagation in Nim, on PyPI, with an animated explainer",
      repos: @["uv-add-nimlang", "nimpy-numpy", "naffprop", "not1d", "uv-add-nimlang-lib-demo", "blog", "nimib"]),
  Act(key: "intermezzo", name: "Intermezzo", english: "interlude: the talk", dates: "24–28 Oct",
      story: "Slides for *Sailing Seas of Scientific Nim*, planned with OpenSpec; the first pages in claude-artifacts; the State of NimibLand.",
      moment: "[a talk planned as specs](https://github.com/pietroppeter/talk-sailing-seas-scientific-nim/pull/7): OpenSpec with a schema of its own",
      repos: @["talk-sailing-seas-scientific-nim", "claude-artifacts"]),
  Act(key: "nanuq", name: "Atto secondo", english: "act two: nanuq", dates: "27 Oct – 2 Nov",
      story: "The talk paused for Polars in Nim: six releases in six days, each with a design post, an explainer on real data and chapters of a book of ports.",
      moment: "[a coverage map of Polars](https://github.com/pietroppeter/nanuq/pull/60): what is there and what is not, as a page",
      repos: @["nanuq", "nanuq-book", "nanuq-more", "nanuqy", "tomd"]),
  Act(key: "officina", name: "Atto terzo", english: "act three: the workshop", dates: "31 Oct – 7 Nov",
      story: "From nanuq came cicak, a REPL for Nim, with benchmarks; then cadero, a small CAD in Nim, to plan the furniture of a room, in Italian.",
      moment: "[a 3D viewer written in Nim](https://github.com/pietroppeter/cadero/pull/11), compiled to JavaScript in a nimib page",
      repos: @["cicak", "cicak-app", "cadero"]),
  Act(key: "giochi", name: "Atto quarto", english: "act four: games", dates: "4–6 Nov",
      story: "Parloku, a word puzzle to play with the fingers, and zogyn, the declarative dragging it is made with, both first tried as artifacts.",
      moment: "[specs whose drag scenarios run and animate](https://github.com/pietroppeter/parloku/pull/11)",
      repos: @["parloku", "zogyn", "puzzlepaw"]),
  Act(key: "finale", name: "Finale", english: "finale", dates: "7 Nov",
      story: "tabelline, great tables for Nim, and diagrammari, diagrams that Mermaid reads; a FOSDEM proposal. And a name for the way of working: Operetta.",
      moment: "[the talk's tables, redone with tabelline](https://github.com/pietroppeter/talk-sailing-seas-scientific-nim/pull/27)",
      repos: @["tabelline", "diagrammari", "diagrammari-py", "all-systems-nim"]),
]

func actOf*(repo, date: string): string =
  ## The act a pull request belongs to: by its project when it has one, else by its date.
  let name = repo.replace("pietroppeter/", "")
  for a in acts:
    if name in a.repos and a.key notin ["intermezzo"] and name notin ["blog", "nimib", "claude-artifacts"]:
      return a.key
  if name == "talk-sailing-seas-scientific-nim": return "intermezzo"
  if date < "2026-10-01": "ouverture"
  elif date < "2026-10-21": "toulouse"
  elif date < "2026-10-27": "intermezzo"
  elif date < "2026-11-02": "nanuq"
  elif date < "2026-11-04": "officina"
  elif date < "2026-11-07": "giochi"
  else: "finale"

proc monthData*(): TableData =
  ## The pull requests and issues of the month, with the act each belongs to.
  result = readCsv(monthTsv, sep = '\t')
  var act: seq[Value]
  for i in 0 ..< result.nrows:
    act.add toValue(actOf($result["repo", i], $result["created", i]))
  result.addColumn("act", act)

proc prsByAct*(): OrderedTable[string, int] =
  let d = monthData()
  for a in acts: result[a.key] = 0
  for i in 0 ..< d.nrows: result[$d["act", i]] += 1

# The parts of the way of working, in the order they appeared. `born` and `pr` point to the pull
# request where each one first shows up in the month's titles; some were there before, in a
# smaller form.
const parts*: seq[Part] = @[
  Part(key: "setup", name: "Cloud setup", plain: "a script that installs Nim and the dependencies in a fresh sandbox",
       does: "Claude Code runs in throwaway containers, so every repo can set itself up.",
       born: "talk-sailing-seas-scientific-nim", pr: 4, date: "4 Oct", act: "toulouse"),
  Part(key: "pages", name: "Pages from CI", plain: "CI builds the pages; no HTML is committed",
       does: "Every merge publishes; a pull request can be previewed.",
       born: "blog", pr: 13, date: "4 Oct", act: "toulouse"),
  Part(key: "disclosure", name: "AI disclosure", plain: "a line in the README saying how AI was used",
       does: "Readers know what they are looking at.",
       born: "uv-add-nimlang-lib-demo", pr: 2, date: "6 Oct", act: "toulouse"),
  Part(key: "explainer", name: "Explainer", plain: "a nimib page that explains the idea, with things that move",
       does: "Thinking happens in a page someone else can read.",
       born: "naffprop", pr: 5, date: "7 Oct", act: "toulouse"),
  Part(key: "artifact", name: "Artifact first", plain: "a claude-artifacts page before there is a repo",
       does: "A quick sketch on the phone; the repo comes when the idea holds.",
       born: "claude-artifacts", pr: 1, date: "24 Oct", act: "intermezzo"),
  Part(key: "openspec", name: "Specs (OpenSpec)", plain: "every agreed behaviour written down, changed by proposals",
       does: "Claude and Pietro agree before building; the specs stay true after.",
       born: "talk-sailing-seas-scientific-nim", pr: 7, date: "26 Oct", act: "intermezzo"),
  Part(key: "skills", name: "Skills", plain: "instructions an agent loads when it needs them",
       does: "Tried once for nimib and set aside; the next part to grow.",
       born: "nimib", pr: 264, date: "28 Oct", act: "intermezzo"),
  Part(key: "devlog", name: "Devlog", plain: "dated posts, not updated afterwards",
       does: "The story of the decisions, told while they are fresh.",
       born: "nanuq", pr: 10, date: "27 Oct", act: "nanuq"),
  Part(key: "backlog", name: "Backlog", plain: "ideas go in BACKLOG.md, not straight into work",
       does: "Nothing is lost, and nothing starts by accident.",
       born: "nanuq", pr: 4, date: "27 Oct", act: "nanuq"),
  Part(key: "examples", name: "Runnable specs", plain: "spec examples that run against the code when the pages are built",
       does: "A spec that lies breaks the build.",
       born: "nanuq", pr: 43, date: "31 Oct", act: "nanuq"),
  Part(key: "design", name: "Design post", plain: "a post per release: what was chosen and why",
       does: "The release explained to its future users, and to Pietro.",
       born: "nanuq", pr: 45, date: "31 Oct", act: "nanuq"),
  Part(key: "useit", name: "Use-it explainer", plain: "the release used on a subject with real data",
       does: "Finds what is missing, awkward or broken, as a user would.",
       born: "nanuq", pr: 38, date: "31 Oct", act: "nanuq"),
  Part(key: "book", name: "Book of ports", plain: "the reference library's own tutorials, ported, the original beside",
       does: "Proves the library on code written by others.",
       born: "nanuq-book", pr: 1, date: "31 Oct", act: "nanuq"),
  Part(key: "coverage", name: "Coverage map", plain: "the reference library's features, one by one, with their status",
       does: "Says what is missing, and what each release adds.",
       born: "nanuq", pr: 60, date: "1 Nov", act: "nanuq"),
  Part(key: "bench", name: "Benchmarks", plain: "measured runs, with a results page",
       does: "Claims about speed come with numbers.",
       born: "cicak", pr: 11, date: "1 Nov", act: "officina"),
  Part(key: "look", name: "A look of its own", plain: "a theme chosen for the project",
       does: "Each project is recognisable at a glance.",
       born: "cadero", pr: 2, date: "2 Nov", act: "officina"),
  Part(key: "living", name: "Living documents", plain: "pages kept true as the code changes, listed first in the devlog",
       does: "The current state is always one page away.",
       born: "cicak", pr: 15, date: "6 Nov", act: "officina"),
  Part(key: "agents", name: "AGENTS.md", plain: "the working rules for any coding agent, in the repo",
       does: "Every new session starts knowing the house rules.",
       born: "claude-artifacts", pr: 7, date: "6 Nov", act: "giochi"),
  Part(key: "threads", name: "Three threads", plain: "every release built, used and ported, in three threads at once",
       does: "The use and the ports feed the build while it happens.",
       born: "tabelline", pr: 8, date: "7 Nov", act: "finale"),
]

func part*(key: string): Part =
  for p in parts:
    if p.key == key: return p
  raise newException(KeyError, "no part " & key)

func actName*(key: string): string =
  for a in acts:
    if a.key == key: return a.name
  key
