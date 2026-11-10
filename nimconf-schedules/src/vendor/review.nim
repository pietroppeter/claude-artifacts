## The review mode of a page: open it with **✎ Review**, select text, comment on it, and export
## the comments for a coding agent. One module for now, with its blocks, its styles and its
## script (`assets/review.js`), so it can move to nimib as it is.
##
## Vendored from pietroppeter/tabelline `docs/review.nim` at 4657f10 (review mode v8, PR #47),
## with its two local changes marked `vendored:` (no `stile` import, no quaderno rules; the
## script sits beside this file).
import std/[json, os, strutils, strformat]
import nimib except md

func esc(s: string): string = s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))
func inline(md: string): string = markdownToHtml(md).strip.replace("<p>", "").replace("</p>", "")

# ---------------------------------------------------------------------------------------- styles

const reviewRules = """
/* the colours and fonts the review mode uses, for a page that has none of its own (a plain nimib
   page): `:where` weighs nothing, so a page's own tokens (tabelline's, on :root) win */
:where(html) { --paper: #fffdf8; --ink: #1f1f1f; --surface: #f6f3ec; --line: #c9c4ba; --shade: #e7e2d8;
  --muted: #6b675f; --secondary: #6aa9d6; --secondary-soft: #d6e8f5; --primary-text: #8a3550;
  --neutral-1: #ece8df; --font: system-ui, sans-serif; --mono: ui-monospace, monospace; }
/* the review mode (review.nim, nbReview): a Review button, then marks on the text, a bar at
   the bottom, the comment's sheet at the top, export and history */
.rv-only { display: none; }
body.rv-on .rv-only { display: block; }
.rv-bar[hidden], .rv-panel[hidden] { display: none; }
.rv-enter { display: flex; flex-wrap: wrap; align-items: center; gap: .4rem .8rem; margin: .8rem 0 1.4rem; color: var(--muted); font-size: .92rem; }
.rv-enter .rv-version { font-weight: 700; color: var(--ink); }
.rv-toggle { font: inherit; color: var(--ink); background: transparent; border: 1px solid var(--line); border-radius: 0;
  min-height: 44px; padding: 0 .8rem; cursor: pointer; }
.rv-toggle[aria-pressed="true"] { border-color: var(--ink); box-shadow: inset 0 -3px 0 var(--secondary); }
body.rv-on { padding-bottom: calc(4.6rem + env(safe-area-inset-bottom, 0px)); }
mark.rv-mark { background: var(--secondary-soft); color: inherit; box-shadow: 0 2px 0 var(--secondary); cursor: pointer; }
mark.rv-mark.rv-current { background: var(--secondary); }
.rv-bar { position: fixed; left: 0; right: 0; bottom: 0; z-index: 50; display: flex; align-items: center; gap: .3rem;
  justify-content: center; padding: .45rem max(.5rem, env(safe-area-inset-right, 0px)) calc(.45rem + env(safe-area-inset-bottom, 0px)) max(.5rem, env(safe-area-inset-left, 0px));
  background: var(--surface); border-top: 3px solid var(--ink); font: 400 15px/1.2 var(--font); }
.rv-bar button, .rv-sheet button { font: inherit; color: var(--ink); background: var(--paper); border: 1px solid var(--line);
  border-radius: 0; min-height: 44px; min-width: 44px; padding: 0 .7rem; cursor: pointer; white-space: nowrap; }
.rv-bar button { padding: 0 .55rem; }
.rv-bar button[data-do="delete"] { color: var(--primary-text); }
.rv-bar button:disabled { color: var(--muted); border-color: var(--shade); cursor: default; }
.rv-bar button[data-do="prev"], .rv-bar button[data-do="next"] { font-size: 1.4rem; padding: 0; }
.rv-bar .rv-count { min-width: 3.2rem; text-align: center; color: var(--muted); font-size: .85rem; }
.rv-bar .rv-add, .rv-sheet .rv-save { background: var(--ink); color: var(--paper); border-color: var(--ink); font-weight: 700; }
.rv-bar .rv-add.rv-selected { background: var(--secondary); color: var(--ink); border-color: var(--ink); }
dialog.rv-sheet { width: 100%; max-width: 40rem; margin: 0 auto auto; padding: 1rem max(1rem, env(safe-area-inset-right, 0px)) 1rem max(1rem, env(safe-area-inset-left, 0px));
  border: 0; border-bottom: 3px solid var(--ink); background: var(--surface); color: var(--ink); font: 400 16px/1.45 var(--font);
  max-height: 90vh; overflow-y: auto; }
dialog.rv-sheet::backdrop { background: color-mix(in oklab, var(--ink) 30%, transparent); }
.rv-sheet .rv-where { margin: 0 0 .4rem; font-weight: 700; }
.rv-sheet textarea { display: block; width: 100%; margin-top: .2rem; font: 16px/1.4 var(--font); color: var(--ink);
  background: var(--paper); border: 1px solid var(--line); border-radius: 0; padding: .5rem; }
.rv-export textarea { font: 16px/1.45 var(--mono); white-space: pre-wrap; }   /* 16px: a phone zooms on smaller fields */
.rv-sheet .rv-actions { display: flex; flex-wrap: wrap; gap: .4rem; justify-content: flex-end; }
.rv-sheet .rv-left { margin-right: auto; }
.rv-sheet .rv-danger { color: var(--primary-text); }
/* the comment's sheet: at the top, small, not modal: the bar and the page stay in reach */
.rv-panel { position: fixed; top: 0; left: 0; right: 0; z-index: 60; max-width: 40rem; margin: 0 auto;
  padding: .5rem max(.6rem, env(safe-area-inset-right, 0px)) .6rem max(.6rem, env(safe-area-inset-left, 0px));
  background: var(--surface); border-bottom: 3px solid var(--ink); color: var(--ink); font: 400 16px/1.45 var(--font);
  animation: rv-down .2s ease-out; }
.rv-panel .rv-whole { margin: 0 0 .3rem; color: var(--muted); font-size: .85rem; }
.rv-panel .rv-note { margin: 0; }
.rv-panel .rv-thumbs { margin-top: .45rem; }
.rv-panel button { font: inherit; color: var(--ink); background: var(--paper); border: 1px solid var(--line); border-radius: 0; cursor: pointer; }
/* history: one line per version */
.rv-versions { list-style: none; margin: 0 0 .8rem; padding: 0; }
.rv-versions li { display: flex; align-items: center; gap: .5rem; min-height: 48px; border-bottom: 1px solid var(--shade); }
.rv-versions a { color: var(--ink); }
.rv-versions .rv-date { flex: 1; color: var(--muted); font-size: .9rem; }
.rv-versions .rv-n { font-size: .85rem; }
/* a screenshot, as large as the screen allows */
dialog.rv-zoom { width: 100vw; height: 100vh; max-width: 100vw; max-height: 100vh; margin: 0; padding: 0; border: 0; background: transparent; }
dialog.rv-zoom[open] { display: flex; align-items: center; justify-content: center; }
dialog.rv-zoom::backdrop { background: color-mix(in oklab, var(--ink) 88%, transparent); }
dialog.rv-zoom img { max-width: 100%; max-height: 100%; object-fit: contain; }
dialog.rv-zoom button { position: fixed; top: max(.5rem, env(safe-area-inset-top, 0px)); right: .5rem; min-width: 44px; min-height: 44px;
  font-size: 1.5rem; color: var(--ink); background: var(--paper); border: 1px solid var(--line); border-radius: 0; }
.rv-thumb img, .rv-shot img { cursor: zoom-in; }
dialog.rv-sheet[open] { animation: rv-down .2s ease-out; }
@keyframes rv-down { from { transform: translateY(-100%); } }
/* the note: an editable box, so a phone offers to paste a screenshot in it */
.rv-note { min-height: 3.2rem; max-height: 9rem; overflow-y: auto; padding: .5rem; font: 16px/1.4 var(--font);
  background: var(--paper); border: 1px solid var(--line); white-space: pre-wrap; overflow-wrap: anywhere; }
.rv-note:empty::before { content: attr(data-placeholder); color: var(--muted); }
.rv-note:focus { outline: 2px solid var(--secondary); outline-offset: -1px; }
.rv-thumbs { display: flex; flex-wrap: wrap; gap: .5rem; }
.rv-thumb { position: relative; }
.rv-thumb img { display: block; height: 4.5rem; width: auto; border: 1px solid var(--line); }
.rv-thumb button { position: absolute; top: 0; right: 0; min-height: 32px; min-width: 32px; padding: 0; font-size: 1.1rem; }
/* the export: each screenshot with its own Copy */
.rv-shotlist { display: flex; flex-direction: column; gap: .35rem; margin: 0 0 .6rem; }
.rv-shot { display: flex; align-items: center; gap: .5rem; font-size: .85rem; color: var(--muted); }
.rv-shot img { height: 2.75rem; width: auto; border: 1px solid var(--line); }
.rv-shot span { flex: 1; overflow-wrap: anywhere; }
/* the strip of versions of the older versions of the post Review mode (nbVersions) */
.versioni { margin: 1rem 0 1.4rem; font-size: .92rem; }
.versioni ol { list-style: none; margin: 0; padding: 0; display: flex; flex-wrap: wrap; gap: .4rem; }
.versioni li { border: 1px solid var(--line); background: var(--surface); }
.versioni li > a, .versioni li > .voce { display: flex; align-items: center; min-height: 44px; padding: 0 .7rem; color: var(--ink); text-decoration: none; }
.versioni li > a:hover b { text-decoration: underline; }
.versioni li[aria-current] { border-color: var(--ink); box-shadow: inset 0 -3px 0 var(--ink); }
.versioni .titolo { font-weight: 700; margin-right: .5rem; }
.versioni li span span, .versioni li a span { color: var(--muted); margin-left: .35rem; }
/* moving between versions: a short slide, the bar stays where it is */
@view-transition { navigation: auto; }
::view-transition-old(root) { animation: versione-out .22s ease-in both; }
::view-transition-new(root) { animation: versione-in .26s ease-out both; }
@keyframes versione-out { to { opacity: 0; transform: translateX(-1.5rem); } }
@keyframes versione-in { from { opacity: 0; transform: translateX(1.5rem); } }
.rv-bar { view-transition-name: rv-bar; }
@media (prefers-reduced-motion: reduce) {
  ::view-transition-old(root), ::view-transition-new(root) { animation: none; }
}
"""

const reviewCss* = reviewRules   # vendored: tabelline adds its quaderno rules here
  ## The styles of the review mode, added only to the pages that use it.

# ---------------------------------------------------------------------------------------- blocks

const reviewJs* = staticRead(currentSourcePath().parentDir / "review.js")   # vendored: beside this file
  ## The script, kept as a file of its own (`assets/review.js`) so it can be read and shown.

func versionHref*(n, this, latest: int): string =
  ## The link from the page of version `this` to version `n`, for a page that keeps its old
  ## versions: the newest is the page itself, version `n` is kept in `vn/` beside it.
  if n == this: ""
  elif this == latest: &"v{n}/"
  elif n == latest: "../"
  else: &"../v{n}/"

func versionsJson*(dates: openArray[string], this: int): string =
  ## The versions of a page for History: number, date and link from version `this`.
  var all = newJArray()
  for i, date in dates:
    all.add %*{"n": i + 1, "date": date, "href": versionHref(i + 1, this, dates.len)}
  $all

newNbBlock(NbReview):
  page: string
  version: int
  title: string
  source: string
  versions: string   ## JSON: `[{"n", "date", "href"}]`, for History
  script: string     ## the script's address, or "" to inline it
  toHtml:
    &"""<div id="review" hidden data-page="{esc(blk.page)}" data-version="{blk.version}" """ &
      &"""data-title="{esc(blk.title)}" data-source="{esc(blk.source)}" data-versions="{esc(blk.versions)}"></div>""" &
      (if blk.script.len > 0: &"""<script src="{esc(blk.script)}" defer></script>"""
       else: "<script>\ndocument.addEventListener('DOMContentLoaded', function () {\n" & reviewJs & "});\n</script>")

proc repoPath(file: string): string =
  ## `file` from the root of its git repository, as the agent reading the export sees it.
  var dir = file.parentDir
  while dir.len > 1 and not dirExists(dir / ".git"): dir = dir.parentDir
  if dirExists(dir / ".git"): file.relativePath(dir) else: file.extractFilename

proc review*(nb: var Nb, version = 1, page = "", title = "", source = "",
             versions: openArray[string] = [], script = "") =
  let source = if source.len > 0: source else: repoPath(nb.doc.thisFile.string)
  let title = if title.len > 0: title else: nb.doc.context{"title"}.getStr
  nb.doc.context["stylesheet"] = %(nb.doc.context["stylesheet"].getStr & "\n<style>\n" & reviewCss & "</style>")
  nb.add newNbReview(page = (if page.len > 0: page else: source), version = version, title = title, source = source,
                     versions = (if versions.len > 0: versionsJson(versions, version) else: ""), script = script)

template nbReview*(tversion = 1, tpage = "", ttitle = "", tsource = "",
                   tversions: openArray[string] = [], tscript = "") =
  ## The review mode on this page. Reading is the default: the page shows one button,
  ## **✎ Review** (beside `nbVersion`'s line, or under the title), that opens and closes it.
  ## With no arguments, everything comes from the notebook: the source file (named in the
  ## export, and the key the comments are kept under in the browser) and the page's title.
  ## A page that changes in versions gives its `tversion`, and the dates of all of them
  ## (`tversions`, oldest first) for History; `tpage` is the key when it must stay the same
  ## across versions kept in different files. `tscript`: the address of `review.js` shared by
  ## the site; empty, the script is inlined and the page stays one file. After `useTabelline`.
  nb.review(tversion, tpage, ttitle, tsource, tversions, tscript)

newNbBlock(NbVersion):
  version: int
  updated: string
  toHtml:
    &"""<p class="rv-enter"><span class="rv-version">Version {blk.version}""" &
      (if blk.updated.len > 0: &""" · updated {esc(blk.updated)}""" else: "") & "</span></p>"

proc version*(nb: var Nb, version: int, updated = "") = nb.add newNbVersion(version = version, updated = updated)

template nbVersion*(tversion: int, tupdated = "") =
  ## The line under the lede of a page that changes in versions: its version, the day of its
  ## last update when there was one, and **✎ Review** beside them when the page has the review mode.
  nb.version(tversion, tupdated)

newNbBlock(NbInReview of NbContainer):
  toHtml:
    """<div class="rv-only">""" & nbContainerToHtml(blk, nb) & "</div>"

template nbInReview*(body: untyped) =
  ## Blocks shown only while the review mode is open, such as what is new in this version.
  let only = newNbInReview()
  nb.withContainer(only):
    body
  nb.add only

newNbBlock(NbVersions):
  versions: seq[(string, string)]
  this: int
  toHtml:
    # two boxes, the newest first: the newest and the one before it, or, on an older version,
    # the newest and this one
    let latest = blk.versions.len
    var shown = @[latest]
    let other = if blk.this == latest: latest - 1 else: blk.this
    if other >= 1: shown.add other
    var items = ""
    for n in shown:
      let (date, what) = blk.versions[n - 1]
      let href = versionHref(n, blk.this, latest)
      let inside = &"""<b>v{n}</b> <span>{inline(date)}</span>"""   # the whole box is the link
      let box = if href.len > 0: &"""<a href="{href}">{inside}</a>""" else: &"""<span class="voce">{inside}</span>"""
      let current = if n == blk.this: " aria-current=\"page\"" else: ""
      items.add &"""<li{current} title="{esc(what)}">{box}</li>"""
    &"""<nav class="versioni" aria-label="Versions of this page"><span class="titolo">Versions</span><ol>{items}</ol></nav>"""

proc versions*(nb: var Nb, versions: openArray[(string, string)], this: int) =
  nb.add newNbVersions(versions = @versions, this = this)

template nbVersions*(tversions: openArray[(string, string)], tthis: int) =
  ## The strip of versions that versions 1 to 6 of the post Review mode show under the title:
  ## `(date, what changed)` for each, oldest first, and the number of this one.
  nb.versions(tversions, tthis)
