## Should nimib swap jsony, parsetoml and nim-markdown for George Lemon's openparser and marvdown?
## Every number on the page comes from data/, written by bench/run.sh (see bench/ and README.md).
## Build: sh deps.sh && nim r index.nim   (writes ../index.html; MO_DEPS moves the deps folder)
import std/[os, strformat, strutils, json, sequtils]
import nimib
import tabelline, tabelline/nimib
import lib/blocks
import lib/style as pagestyle   # (as: tabelline exports a `style` too)
import review          # tabelline's review mode, from claude-artifacts shared/review (unchanged copy)

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.title = "marvdown and openparser for nimib?"
nb.useExplainerStyle
nbReview(tpage = "marvdown-openparser", tsource = "marvdown-openparser/src/index.nim")

# ---------------------------------------------------------------- data, at build time
let data = currentSourcePath().parentDir / "data"
proc tsv(name: string): seq[seq[string]] =
  ## The rows of data/<name>, header left out.
  let lines = readFile(data / name).strip.splitLines
  for line in lines[1 .. ^1]: result.add line.split('\t')

let cm = tsv("commonmark.tsv")
let gfm = tsv("gfm.tsv")
let rw = tsv("realworld.tsv")[0]
let toml = tsv("toml.tsv")
let speed = tsv("speed.tsv")
let crash = tsv("crash.tsv")
let libs = tsv("libs.tsv")
let cases = parseJson(readFile(data / "cases.json"))
let ownOrgs = readFile(data / "dependents_own_orgs.tsv").strip.splitLines.mapIt(it.split('\t'))
let outside = tsv("dependents_outside.tsv")
let orgs = tsv("orgs.tsv")

proc total(rows: seq[seq[string]], col: int): int =
  for r in rows: result += parseInt(r[col])
let
  cmN = total(cm, 1)
  cmNow = total(cm, 2)
  cmNew = total(cm, 3)
  gfmN = total(gfm, 1)
  gfmNow = total(gfm, 2)
  gfmNew = total(gfm, 3)
  rwFiles = parseInt(rw[0])
  rwSame = parseInt(rw[1])
func pct(a, b: int): string = $int(100 * a / b + 0.5) & "%"
proc tomlRow(lib, v: string): seq[int] =
  for r in toml:
    if r[0] == lib and r[1] == v: return r[2 .. 5].mapIt(parseInt(it))
let
  pt10 = tomlRow("parsetoml", "1.0.0")
  op10 = tomlRow("optoml", "1.0.0")
  pt11 = tomlRow("parsetoml", "1.1.0")
  op11 = tomlRow("optoml", "1.1.0")
let opOwn = ownOrgs.filterIt(it[1] == "openparser").len
let mdOwn = ownOrgs.filterIt(it[1] == "marvdown").len

const
  nimibRepo = "https://github.com/pietroppeter/nimib/blob/7118b3a8fa112757b7d76ffcb5251a6478cbfcfd/"
  marv = "https://github.com/openpeeps/marvdown"
  op = "https://github.com/openpeeps/openparser"

# ---------------------------------------------------------------- the page
nbText: "# marvdown and openparser for nimib?"

nbLede: """
nimib turns Markdown into HTML with nim-markdown, reads `nimib.toml` with parsetoml and
writes its blocks as JSON with jsony. George Lemon's **marvdown** (Markdown) and **openparser**
(JSON, TOML and 28 other formats) could replace all three. This page measures what would change,
from the simplest dependency to the hardest, and says who makes the new libraries and who uses them.
"""
nbVersion(1, "28 Nov 2026")

nbTldr: &"""
- **Fusion** is used for one thing: `captureStdout` (`src/nimib/capture.nim`) calls
  `duplicate` and `duplicateTo` from `fusion/ioutils`, two wrappers of the C calls `dup` and `dup2`.
  About twenty lines of Nim replace it, and nimib loses a dependency.
- **TOML: openparser is better than parsetoml.** On the official toml-test suite (TOML 1.0) it
  accepts all {op10[1]} valid files and rejects all {op10[3]} invalid ones; parsetoml accepts
  {pt10[0]} of {pt10[1]} and rejects {pt10[2]} of {pt10[3]}. parsetoml had no commit in the last year.
- **JSON: no reason to move.** jsony works, is maintained and used by 200+ packages;
  openparser can do the same job, but its hooks have another signature, so every block with a
  custom hook (and tabelline's book, which reads nimib's JSON) would have to change.
- **Markdown: marvdown is not ready.** On CommonMark's {cmN} examples it gets {cmNew} right
  ({pct(cmNew, cmN)}), nim-markdown {cmNow} ({pct(cmNow, cmN)}). On {rwFiles} real Markdown files
  of the nimib repositories only {rwSame} render the same. It drops lists that follow a paragraph
  and swallows the rest of a page after an inline `<img>`. It is 10 times faster and needs no PCRE.
- **The PCRE problem has a cheaper fix**: port nim-markdown's 82 regular expressions to
  nim-regex (two use back references and need a few lines of code each), and fix the two
  inputs that crash it, found on the way.
- **Who**: George Lemon publishes alone, at a very high pace, in the OpenPeeps org and six
  others; {opOwn} of his own repositories use openparser, and two outside them (by Jaremy Creechley
  and David Krause). Nobody outside uses marvdown yet.
"""

nbToc @[
  ("started", "How this page started"),
  ("today", "What nimib depends on today"),
  ("fusion", "Fusion: one module, two C calls"),
  ("who", "George Lemon and OpenPeeps"),
  ("users", "Who depends on openparser and marvdown"),
  ("toml", "TOML: parsetoml or openparser"),
  ("json", "JSON: jsony or openparser"),
  ("markdown", "Markdown: nim-markdown or marvdown"),
  ("pcre", "The PCRE problem, and a cheaper fix"),
  ("downstream", "What changes downstream"),
  ("plan", "Effort, risks and a plan"),
  ("built", "How this page is built"),
]

# =========================================================================================== 0
nbChapter("started", "How this page started", "28 Nov 2026, from the Nimib Land project")

nbPrompt("Pietro", "28 Nov 2026", [
  "I am considering adopting marvdown and open parser for nimib (instead of jsony and opentoml and nim markdown. Write an explainer that estimates the impacts, pros and cons. Also, what do we use Nim fusion for?",
  "I want also to know all that you can find about George lemon and openpeeps. Which other projects are depending on those libraries?",
])

nbText: """
"opentoml" is parsetoml: that is the TOML library nimib uses. Earlier in the project, a thread
on taking Nim's standard library off PCRE recommended porting nim-markdown to
[nim-regex](https://github.com/nitely/nim-regex), so this page compares against that too.
Everything here was run, not read: the libraries at the commits in `bench/deps.sh`, built with
Nim 2.2.15 (openparser asks for 2.2.10 or later).
"""

# =========================================================================================== 1
nbChapter("today", "What nimib depends on today", "nimib 0.4.3 on main (7118b3a), its nimble file")

nbText: """
nimib's nimble file asks for five packages. Each is used in one or two places:
"""

nbTable toTableData(@[
  (pkg: "`markdown` (nim-markdown)", where: "`renders.nim`: `markdownToHtml`, the HTML of every `nbText`; `nimib.nim` imports it", candidate: "marvdown"),
  (pkg: "`parsetoml`", where: "`config.nim`: `loadTomlSection` reads `nimib.toml`, turns TOML into JSON, then into an object with jsony", candidate: "openparser/toml"),
  (pkg: "`jsony`", where: "`jsons.nim`: a JSON hook per block type, so a `seq[NbBlock]` can go to JSON and back; `jsutils.nim`: values passed to `nbJsFromCode`; re-exported by `nimib`", candidate: "openparser/json"),
  (pkg: "`fusion`", where: "`capture.nim`: `captureStdout`, the output of `nbCode`", candidate: "nothing: ~20 lines"),
  (pkg: "Nim ≥ 1.4", where: "CI tests Nim stable and devel only", candidate: "openparser needs 2.2.10"),
]):
  optCssTheme()
  tabHeader "nimib's dependencies", "what each is for, and what would replace it"
  colsLabel:
    pkg: "package"
    where: "used in"
    candidate: "replaced by"
  fmtMarkdown ["pkg", "where", "candidate"]

nbText: """
The same three libraries are used beside nimib, not only through it: nimiSlides calls
nim-markdown's `markdown(...)` itself, and so does tabelline's book; nimibook reads and writes
its `book.json` with jsony, and nimibook and nimiSlides read their own sections of `nimib.toml`
with nimib's `loadTomlSection`. The [downstream chapter](#downstream) has the full list.
"""

nbTable toTableData(libs.mapIt((lib: it[0], role: it[1], version: it[3], nim: it[4], since: it[5][0 .. 3],
    last: it[6], commits: parseInt(it[7]), authors: parseInt(it[8]), year: parseInt(it[9]),
    lines: parseInt(it[10]), nimble: parseInt(it[11])))), rownameCol = "lib":
  optCssTheme()
  tabHeader "The libraries, old and new", "from their git history, 28 Nov 2026"
  colsLabel:
    role: "for"
    version: "version"
    nim: "needs Nim"
    since: "since"
    last: "last commit"
    commits: "commits"
    authors: "authors"
    year: "commits, last 12 months"
    lines: "lines of Nim"
    nimble: "nimble files that name it"
  fmtNumber ["commits", "authors", "year", "lines", "nimble"], decimals = 0
  tabStyle style.text(weight = "bold"), loc.body(rows = where($it["lib"] in ["marvdown", "openparser"]))
  tabSourceNote md("Authors: distinct commit e-mails. Last column: GitHub code search for the name in `.nimble` files (a rough count of users, forks and duplicates included).")

# =========================================================================================== 2
nbChapter("fusion", "Fusion: one module, two C calls", "the short answer to the second question")

nbText: &"""
nimib imports [fusion](https://github.com/nim-lang/fusion) in exactly one place,
[`src/nimib/capture.nim`]({nimibRepo}src/nimib/capture.nim), for `fusion/ioutils`:

```nim
import fusion/ioutils   # duplicate, duplicateTo
```

`captureStdout` is how `nbCode` gets the output of its code: it copies the stdout file
descriptor with `duplicate`, points stdout at a temporary file with `duplicateTo`, runs the code,
reads the file and puts stdout back. `duplicate` is C's `dup` and `duplicateTo` is `dup2`
(`_dup` and `_dup2` on Windows). The only other trace of fusion is `withDir` in `paths.nim`,
already copied from `fusion/scripting` ("ported from fusion/scripting"), not imported.

So the whole dependency is two C calls. Here they are without fusion, run while this page was built
(the block below runs inside nimib's own `captureStdout`, so it also checks that the two nest):
"""

nbCode:
  import std/tempfiles
  when defined(windows):
    proc cDup(fd: cint): cint {.importc: "_dup", header: "<io.h>".}
    proc cDup2(fd, to: cint): cint {.importc: "_dup2", header: "<io.h>".}
  else:
    proc cDup(fd: cint): cint {.importc: "dup", header: "<unistd.h>".}
    proc cDup2(fd, to: cint): cint {.importc: "dup2", header: "<unistd.h>".}

  template captureStdoutNoFusion(ident: untyped, body: untyped) =
    let outFd = stdout.getFileHandle()
    let saved = cDup(outFd)                     # was fusion's duplicate
    let (tmp, path) = createTempFile("tmp", "")
    stdout.flushFile()
    doAssert cDup2(tmp.getFileHandle(), outFd) != -1   # was duplicateTo
    body
    stdout.flushFile()
    tmp.setFilePos(0)
    ident = tmp.readAll()
    tmp.close()
    removeFile(path)
    doAssert cDup2(saved, outFd) != -1

  var captured: string
  captureStdoutNoFusion(captured):
    echo "hello from inside"
  echo "captured: ", captured.strip

nbNote(nkNimib, """
Removing fusion is a small, safe change on its own: the template above, a test on Windows in CI,
and one line less in `nimib.nimble`. It does not depend on anything else on this page.
""")

# =========================================================================================== 3
nbChapter("who", "George Lemon and OpenPeeps", "from GitHub, DEV, the Nim forum and the package registry")

nbText: &"""
**George Lemon** ([georgelemon](https://github.com/georgelemon) on GitHub) describes himself as
"Open Source Enthusiast", and on [DEV](https://dev.to/georgelemon) (since September 2019) as
"Open Source Enthusiast at OpenPeeps". His one DEV post (June 2023) shows how to build Node.js and
Bun addons in Nim with his library [denim](https://github.com/openpeeps/denim). His site,
openpeeps.dev, did not load from here. Nothing public says more about him than his work.

**OpenPeeps** is a GitHub organization whose description is "Open Source Enthusiasts | Developing
@supranim @getsunday @tim-engine @trytilda @onebuckapp and more". Its only visible member is George
Lemon, and every one of the {libs[1][7]} commits of marvdown and the {libs[4][7]} commits of
openparser is his. It works like the label of one very productive person, with sister
organizations for each larger project:
"""

nbTable toTableData(orgs.mapIt((org: it[0], repos: it[1], what: it[2]))), rownameCol = "org":
  optCssTheme()
  tabHeader "George Lemon's organizations", "public repositories, 28 Nov 2026"
  colsLabel:
    repos: "repos"
    what: "what is there"
  tabSourceNote md("GitHub search, forks included. 92 entries of Nim's package registry (of about 3,000) point to openpeeps (48), nimbase (38) or supranim (6).")

nbText: """
Some facts that matter for a dependency:

- **Pace.** OpenPeeps created 5 to 8 repositories a year from 2021 to 2025, and 35 in 2026.
  openparser is 47,000 lines of Nim written in seven months (April to November 2026, 265 commits),
  with a regex engine that has its own JIT (via his DynASM port), SIMD JSON, a QR code reader,
  a diff engine and a NIF parser among its 30 modules.
- **Best known work.** [Tim](https://github.com/tim-engine/tim), a template engine and markup
  language (69 stars, since 2022), denim (56), [Supranim](https://github.com/supranim/supranim), a
  web framework (46), kapsis, a CLI builder (41). His libraries have tests, CI and API docs.
- **Moves and renames.** He renamed `bro` to `bowdy` in the registry and moved a batch of
  wrappers from openpeeps to nimbase (nim-lang/packages PRs
  [#3535](https://github.com/nim-lang/packages/pull/3535) and
  [#3546](https://github.com/nim-lang/packages/pull/3546)). Handled well, but a reminder that
  names and places change.
- **His own package manager.** In August 2026 he announced
  [Clue](https://forum.nim-lang.org/t/14123), an alternative to nimble that resolves versions
  depth-first ("I don't care about versions, that's a PM's job"). His libraries are tested with
  `clue test`; they install with nimble too.
"""

nbNote(nkCareful, """
All of this is what his public profiles and repositories show. I found no interview, talk or
biography, and I did not try to find out more about him as a person.
""")

# =========================================================================================== 4
nbChapter("users", "Who depends on openparser and marvdown", "every nimble file on GitHub that names them")

nbText: &"""
I read the nimble files of all 153 public repositories of George Lemon's organizations, then
searched GitHub's code index for every other nimble file that names `openparser` or `marvdown`.

- **Inside his organizations**: {opOwn} repositories require openparser (Tim, Supranim, Clue,
  Booyaka, powpow, kapsis, bowdy, nyml, ozark, the nimbase API clients...). Only {mdOwn} require
  marvdown: Booyaka (his documentation generator), datengine and stupidgreen (a static site
  generator), plus getsunday/sunday in another of his organizations.
- **Outside them**, there are three:
"""

nbTable toTableData(outside.mapIt((repo: it[0], who: it[1], uses: it[2], why: it[3]))), rownameCol = "repo":
  optCssTheme()
  tabHeader "Users outside George Lemon's organizations"
  colsLabel:
    who: "by"
    uses: "requires"
    why: "for"
  tabSourceNote md("GitHub code search (default branches, as indexed on 28 Nov 2026), checked by cloning each repository.")

nbText: """
So openparser has two real users outside its author's work, both for its NIF module, both by
well-known Nim developers (Jaremy Creechley wrote figuro and contributed to nim-markdown;
David Krause wrote nimja), both in the last two months. marvdown has none. nimib would be the
first large outside user of either, with nimibook, nimiSlides and every nimib page behind it.
"""

# =========================================================================================== 5
nbChapter("toml", "TOML: parsetoml or openparser", "the simplest swap, and the clearest win")

nbText: """
nimib reads one table of `nimib.toml` and keeps the rest of the text for others to read:

```toml
[nimib]
srcDir = "docsrc"
homeDir = "docs"
```

Today `loadTomlSection` parses the text with parsetoml, converts the section to `JsonNode` with
45 lines of `customToJson`, prints it and parses it again with jsony into the object. openparser
parses TOML straight into an object, which removes those 45 lines and jsony from the config path:

```nim
import std/tables, openparser/toml
type Cfg = object
  nimib: NbConfig
let cfg = parseTOML(content, Cfg)    # unknown tables and keys are skipped by default
```

To compare the two parsers I ran the [toml-test](https://github.com/toml-lang/toml-test) suite,
the one TOML implementations use: a parser should accept every valid file and reject every
invalid one.
"""

nbScores("toml-test, TOML 1.0", @[
  (label: "parsetoml, valid files accepted", passed: pt10[0], total: pt10[1], side: sNow),
  (label: "openparser, valid files accepted", passed: op10[0], total: op10[1], side: sNew),
  (label: "parsetoml, invalid files rejected", passed: pt10[2], total: pt10[3], side: sNow),
  (label: "openparser, invalid files rejected", passed: op10[2], total: op10[3], side: sNew),
], &"TOML 1.1: parsetoml {pt11[0]}/{pt11[1]} and {pt11[2]}/{pt11[3]}, openparser {op11[0]}/{op11[1]} and {op11[2]}/{op11[3]}. Acceptance only: the values parsed were not compared.")

nbNote(nkCareful, """
One rough edge: `parseTOML(text, T)` did not compile until I added `import std/tables` to my own
module (a generic in openparser calls `pairs` on an `OrderedTableRef` without binding it). Easy
to work around, worth an issue upstream.
""")

nbNote(nkNimib, """
For `nimib.toml` the gain is correctness on corner cases nimib users rarely write, and less code.
The cost is the whole openparser package: 47,000 lines, Nim 2.2.10 or later, and nimble installs
nimsimd, nimcypher and dynasm with it, even if only `openparser/toml` and `openparser/json` are
compiled (json pulls nimsimd for its SIMD path).
""")

# =========================================================================================== 6
nbChapter("json", "JSON: jsony or openparser", "a sideways move with a breaking change")

nbText: &"""
nimib uses JSON in three places: the config path above, the values that `nbJsFromCode` passes
to the browser (`toJson(x)`, parsed back with `std/json`), and its **JSON backend**: every block
type registers a hook, so a document's `seq[NbBlock]` (of many subtypes) can be written to JSON
and read back with the right types. tabelline's book uses that: it saves each chapter's
blocks and renders them again later with `readFile(path).fromJson(NbDoc)`.

jsony's hook gets the raw string and a position, `parseHook(s: string, i: var int, v: var NbBlock)`;
nimib reads the `kind` field, rewinds `i` and parses again as the right type.
openparser's hook gets a parser object, `parseHook(p: var JsonParser, v: var NbBlock)`, whose
position is private, so it cannot rewind. It works with a detour through `JsonNode`, which I tried
on a small block hierarchy (`bench/tjson_op.nim`):

```nim
proc parseHook(p: var JsonParser, v: var NbBlock) =
  var node: JsonNode
  parseHook(p, node)                       # parse the block once, as a tree
  v = registry[node["kind"].getStr](node)  # each kind: fromJson($node, ThatKind)
```

It wrote nested containers to JSON and read them back exactly (`toJson(back) == s` printed
`true`), at the cost of parsing every block twice.
"""

nbTable toTableData(@[
  (side: "for openparser", text: "one JSON library for nimib and its TOML; SIMD parsing; `{.json: \"name\".}` field names (compile-time dump only, so far); depth limits"),
  (side: "against", text: "every custom `parseHook`/`dumpHook` written for jsony breaks (new signature); nimib re-exports jsony, so pages that call `toJson`/`fromJson` through nimib change library; the JsonNode detour; nimibook keeps jsony anyway for `book.json`"),
  (side: "speed", text: "not a factor: nimib writes a few kilobytes of JSON per page"),
]):
  optCssTheme()
  tabHeader "jsony to openparser/json"
  colsLabel:
    side: ""
    text: ""
  fmtMarkdown ["text"]

nbNote(nkNimib, """
jsony is small (1,000 lines), maintained by treeform, named in 200+ nimble files and does the job.
Swapping it only makes sense as part of adopting openparser for TOML, and even then nimib could keep
jsony for blocks and use openparser only for the config.
""")

# =========================================================================================== 7
nbChapter("markdown", "Markdown: nim-markdown or marvdown", "the one that every page sees")

nbText: &"""
This is the dependency that matters most: every `nbText` of every nimib page goes through it.
[marvdown]({marv}) says it is "CommonMark compliant", with GitHub tables, task lists, alerts,
footnotes, front matter, heading anchors and a JSON AST. To check, I ran the
[CommonMark 0.31.2 spec](https://spec.commonmark.org/0.31.2/) examples through both libraries,
compared the HTML the way CommonMark's own test runner does, and forgave marvdown two
differences that browsers ignore (`class=""` on code blocks and the last newline in a block).
"""

nbScores("CommonMark 0.31.2 and GitHub's extensions", @[
  (label: &"nim-markdown, CommonMark ({cmN} examples)", passed: cmNow, total: cmN, side: sNow),
  (label: &"marvdown, CommonMark ({cmN} examples)", passed: cmNew, total: cmN, side: sNew),
  (label: "nim-markdown, GFM extensions (tables, strikethrough, autolinks)", passed: gfmNow, total: gfmN, side: sNow),
  (label: "marvdown, GFM extensions", passed: gfmNew, total: gfmN, side: sNew),
  (label: &"{rwFiles} real `.md` files of the nimib repositories, same HTML from both", passed: rwSame, total: rwFiles, side: sNew),
], "marvdown with all raw HTML allowed and anchors off, nim-markdown with nimib's GFM settings. Real files: every .md of 1 KB or more in nimib, nimibook, tabelline, diagrammari, xoffy, skills and nblog, compared after also ignoring heading ids and &quot;.")

var bySection: seq[tuple[section: string, n, now, new: int]]
for r in cm:
  bySection.add (r[0], parseInt(r[1]), parseInt(r[2]), parseInt(r[3]))
nbTable toTableData(bySection), rownameCol = "section":
  optCssTheme()
  tabHeader "CommonMark examples passed, by section of the spec"
  colsLabel:
    n: "examples"
    now: "nim-markdown"
    new: "marvdown"
  tabStyle style.text(weight = "bold"), loc.body(cols("new"), rows = where(it["new"].toFloat >= it["now"].toFloat))
  tabSourceNote md("Bold: where marvdown does at least as well (ATX headings, where nim-markdown's untagged main adds heading ids the spec does not have).")

nbText: """
The sections that fail are the everyday ones: lists (3 of 26), block quotes (3 of 25), images,
autolinks, raw HTML. Here is what that looks like, on inputs a nimib page writes all the time:
"""

var renders: seq[Render]
for c in cases:
  renders.add (name: c["name"].getStr, md: c["md"].getStr, now: c["nimMarkdown"].getStr, new: c["marvdown"].getStr)
nbRenders renders

nbText: """
A list right after a line of text is how most pages write lists: the list of folders in
nimib's own CONTRIBUTING.md comes out as one paragraph. An `<img>` (or any tag marvdown takes for the start
of a block) in the middle of a sentence turns everything after it into raw text, to the end of the
page. Words lose their space after a line that ends with "!". A double-backtick code span loses
its text.
"""

var sp: seq[tuple[file: string, kb: int, now, new: float]]
for r in speed: sp.add (r[0], parseInt(r[1]), parseFloat(r[2]), parseFloat(r[3]))
nbTable toTableData(sp), rownameCol = "file":
  optCssTheme()
  tabHeader "Speed: one file to HTML", "milliseconds, mean of 50 runs in one process, -d:release"
  colsLabel:
    kb: "KB"
    now: "nim-markdown"
    new: "marvdown"
  fmtNumber ["now", "new"], decimals = 2
  tabSourceNote md("`bench/bench.nim`. A nimib page spends seconds compiling, so a few milliseconds of Markdown do not show.")

nbText: &"""
marvdown is 10 to 30 times faster, and it has things nimib pages build by hand today: heading
ids with a table of contents (`getSelectorItems`; tabelline, diagrammari and xoffy each wrote an
`addHeadingIds`), GitHub alerts, footnotes, YAML front matter, and an AST it can write as JSON and
render later, a natural fit for nimib's JSON backend. Its defaults differ from nimib's needs
(anchors with a 🔗 on, raw HTML filtered by a list of tags), so nimib would set its own options.

Running the spec through nim-markdown found something too: **two examples crash it**.
"""

nbTable toTableData(crash.mapIt((input: "`" & it[0] & "`", result: it[1]))):
  optCssTheme()
  tabHeader "Inputs that stop nim-markdown", "an IndexDefect, which ends the program: a nimib page would not build"
  colsLabel:
    input: "Markdown"
    result: "what happens"
  fmtMarkdown ["input"]
  tabSourceNote md("nim-markdown at main (995405b). marvdown renders both, not as the spec says.")

# =========================================================================================== 8
nbChapter("pcre", "The PCRE problem, and a cheaper fix", "why this came up, and what it would take")

nbText: """
nim-markdown is built on `std/re`, which loads **PCRE 1** (`libpcre.so.3`) at run time. Ubuntu
26.04 no longer ships it, so nimib's CI pins `ubuntu-24.04` and installs `libpcre3`, and every
sandbox that builds a nimib page needs the same trick. That is the real reason to look at
marvdown: it needs no regular expressions from outside Nim.

But the cheaper fix is in nim-markdown itself. It has **82 regular expression literals**, used
through `matchLen` (54 times), `replace`, `find`, `contains` and `match`.
[nim-regex](https://github.com/nitely/nim-regex) (pure Nim, by nitely, the engine behind Nim
2.4's `std/nre2`) handles lookahead (7 uses) and named groups (2), but not back references, which 2
patterns use (code spans: a run of backticks closed by the same run). Those two become a few lines
of plain Nim each.
"""

nbTable toTableData(@[
  (option: "Port nim-markdown to nim-regex", effort: "1 to 2 days, with the CommonMark runner of this page to check that 611 stays 611", keeps: "today's output, byte for byte", risk: "low; upstream is quiet (3 commits in a year), so a fork in nimib-land may be needed"),
  (option: "Move to marvdown now", effort: "1 hour for nimib's code, then weeks of fixing pages, or of fixing marvdown", keeps: "nothing: half of real files change", risk: "high: lost lists and swallowed text in published pages"),
  (option: "Help marvdown reach CommonMark first", effort: "weeks, upstream, with George Lemon", keeps: "a fast parser with anchors, AST and front matter, later", risk: "depends on one maintainer's priorities"),
]):
  optCssTheme()
  tabHeader "Three ways off PCRE"
  colsLabel:
    option: "option"
    effort: "effort"
    keeps: "output of existing pages"
    risk: "risk"
  colsWidth:
    option: "130px"
    effort: "165px"
    keeps: "150px"
    risk: "180px"

# =========================================================================================== 9
nbChapter("downstream", "What changes downstream", "the repositories in this project, read on 28 Nov 2026")

nbTable toTableData(@[
  (repo: "nimibook", uses: "jsony for `book.json` (own dependency); `loadTomlSection` for `[nimibook]`", impact: "TOML: none if `loadTomlSection` keeps its signature. JSON: none, it keeps jsony. Markdown: every chapter's text"),
  (repo: "nimiSlides", uses: "imports `markdown` and calls `markdown(...)` for slides and footers; `loadTomlSection` for `[nimislides]`", impact: "Markdown: two renderers in one deck if nimib moves and nimiSlides does not; move both or neither"),
  (repo: "tabelline (docs, book)", uses: "`markdownToHtml` in 9 blocks; the book calls `markdown(...)` and `fromJson(NbDoc)` (jsony through nimib)", impact: "JSON: the book's re-render changes if nimib leaves jsony. Markdown: every page"),
  (repo: "diagrammari, xoffy", uses: "`markdownToHtml` in their blocks, own `addHeadingIds`", impact: "Markdown only; would gain anchors from marvdown"),
  (repo: "nblog", uses: "a draft post on serializing OOP blocks with jsony", impact: "the post documents jsony's approach, still valid as history"),
  (repo: "every nimib page", uses: "`nbText`", impact: "Markdown: any output change shows up in published pages"),
]):
  optCssTheme()
  tabHeader "Where nimib's three libraries show up", "and what a swap would change"
  colsLabel:
    repo: "repository"
    uses: "uses"
    impact: "impact"
  colsWidth:
    repo: "115px"
    uses: "200px"
    impact: "215px"
  fmtMarkdown ["uses", "impact"]

nbNote(nkNimib, """
Two API points make this manageable: `markdownToHtml` is the single place nimib renders Markdown,
and `loadTomlSection(content, section, T)` the single place it reads TOML. Keep both signatures and
most downstream code does not notice. The exceptions are the direct `markdown(...)` calls
(nimiSlides, tabelline's book) and the jsony re-export.
""")

# =========================================================================================== 10
nbChapter("plan", "Effort, risks and a plan", "from the simplest change to the hardest")

nbTable toTableData(@[
  (step: "1. Drop fusion", effort: "an hour", gain: "one dependency less", risk: "none; test on Windows", now: "**yes**"),
  (step: "2. nim-markdown off PCRE (nim-regex port, fix the two crashes)", effort: "1 to 2 days", gain: "no libpcre3, no Ubuntu pin, sandboxes just work", risk: "low, checked by the spec runner", now: "**yes**"),
  (step: "3. parsetoml to openparser/toml", effort: "half a day", gain: "a conforming TOML parser, 45 lines less", risk: "Nim ≥ 2.2.10 for every user; a 47k-line single-author package", now: "later, when nimib raises its Nim floor"),
  (step: "4. jsony to openparser/json", effort: "1 to 2 days, plus downstream", gain: "one JSON library", risk: "breaks custom block hooks and tabelline's book", now: "no"),
  (step: "5. nim-markdown to marvdown", effort: "an hour of code, weeks of output changes", gain: "speed, anchors, front matter, AST", risk: "lost lists and text in published pages", now: "not before ~90% on CommonMark"),
]):
  optCssTheme()
  tabHeader "Five changes, in order"
  colsLabel:
    step: "change"
    effort: "effort"
    gain: "gain"
    risk: "risk"
    now: "do it now?"
  colsWidth:
    step: "150px"
    effort: "115px"
    gain: "150px"
    risk: "180px"
    now: "130px"
  fmtMarkdown ["now"]

nbText: &"""
**Recommendation.** Do the first two now: they remove what hurts (fusion, PCRE) without changing
a single page. Keep jsony. Treat openparser's TOML as a good option for the next time nimib
raises its minimum Nim, if openparser is still moving at the same quality and has gained users.
Leave marvdown for later, and if its ideas appeal (anchors, front matter, the AST), the most
useful thing nimib can do is send George Lemon this page's CommonMark runner: it turns
"CommonMark compliant" into a number that can go up.

What would change my mind: marvdown passing 90% of the spec and rendering the nimib repositories'
files like nim-markdown; openparser getting a second maintainer or wide use; nimib deciding to
require Nim 2.2.10 anyway.
"""

# =========================================================================================== 11
nbChapter("built", "How this page is built", "every number is rerun by one script")

nbText: """
The page is a nimib notebook (`src/index.nim`) with tables by
[tabelline](https://pietroppeter.github.io/tabelline/); it reads every number from `src/data/`,
which `src/bench/run.sh` writes:

- `bench/deps.sh` fetches marvdown, openparser (and nimsimd, nimcypher, dynasm), nim-markdown,
  jsony, parsetoml and three test suites at pinned commits: commonmark-spec, cmark-gfm (the GFM
  extensions) and toml-test.
- `cm_*.nim` and `gfm_*.nim` are four tiny programs, Markdown on stdin and HTML on stdout, one per
  library and setting. `runspec.py` feeds them every spec example and compares the HTML with
  CommonMark's own `normalize.py` (that is why it is Python: it reuses the official normalizer).
  `realworld.py` does the same for a folder of `.md` files.
- `tt_parsetoml.nim` and `tt_optoml.nim` run toml-test's file lists; `tjson_op.nim` is the block
  round trip of the JSON chapter; `bench.nim` the speed table; `cases.nim` renders the cards of the
  Markdown chapter with both libraries in one program.
- The dependents come from cloning (blob-less) every repository of George Lemon's organizations and
  reading their nimble files, then GitHub code search for the rest.
"""

nbText: """
**Sources**: [marvdown](https://github.com/openpeeps/marvdown) (6af1ac0),
[openparser](https://github.com/openpeeps/openparser) (a60cce6),
[nim-markdown](https://github.com/soasme/nim-markdown) (995405b),
[jsony](https://github.com/treeform/jsony), [parsetoml](https://github.com/NimParsers/parsetoml),
[fusion](https://github.com/nim-lang/fusion), [nimib](https://github.com/pietroppeter/nimib) (7118b3a),
[CommonMark spec](https://github.com/commonmark/commonmark-spec),
[cmark-gfm](https://github.com/github/cmark-gfm), [toml-test](https://github.com/toml-lang/toml-test),
[George Lemon on GitHub](https://github.com/georgelemon) and [on DEV](https://dev.to/georgelemon),
[OpenPeeps](https://github.com/openpeeps), [Clue on the Nim forum](https://forum.nim-lang.org/t/14123).
"""

nbSave
