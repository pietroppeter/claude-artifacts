## The blocks of the page, and its look: Munari, from nimconf-schedules' `style.nim` (its fonts
## and tokens), plus the few rules of `pageExtra` for what is new here (the language switch, the
## contents, the marks of a missing translation). Every text a block shows goes through lingua,
## so it is a message of the catalogs too.
##
##   nb.usePage(title, description)   # Munari, header with the language switch, footer
##   nbTitle kicker, title, lede      # the top of the page
##   nbNote text, nkCode              # a sheet set apart
##   nbToc                            # the contents: every heading of level 2
##   nbStatus                         # how much of the page each language has
##   nbProc "lingua.nim", "chunks"    # a proc of a file, shown and not run
##   nbFoldCode "lingua.nim"          # a whole file, folded under its name
import std/[os, strutils, strformat, json, sets]
import nimib except md
import nimib/highlight
import tabelline
import style, lingua

func esc(s: string): string = s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))

const pageExtra = """
/* the language switch: like nimconf-schedules' switch of looks */
.langs { display: inline-flex; border: 1px solid var(--ink); }
.langs button { font: inherit; color: var(--ink); background: transparent; border: 0; min-height: 40px; padding: 0 .8rem; cursor: pointer; }
.langs button[aria-pressed="true"] { background: var(--ink); color: var(--paper); }
/* a chunk with no translation yet: the source, set apart by a dashed rule */
.l10n-missing { border-left: 3px dashed var(--secondary); padding-left: .6rem; }
/* the contents, and the way back to them from every heading */
nav.toc { margin: 1.4rem 0 1rem; padding: .7rem .9rem .5rem; border-top: 3px solid var(--ink); background: var(--shade); }
nav.toc .toc-title { margin: 0 0 .3rem; font-weight: 700; }
nav.toc ol { margin: 0; padding-left: 1.4rem; }
nav.toc li { margin: .15rem 0; }
h2 a.up { margin-left: auto; font-size: .9rem; text-decoration: none; color: var(--muted); padding: 0 .2rem; }
.note > [data-l] > :first-child, .note > :first-child > :first-child { margin-top: 0; }
.note > [data-l]:last-child > :last-child { margin-bottom: 0; }
.kicker [data-l], .langs-row [data-l] { display: inline; }
/* translation notes: each message, the English beside its translation (stacked on a phone) */
.msg { display: grid; grid-template-columns: 1fr 1fr; gap: .2rem 1.2rem; padding: .7rem 0 .3rem; border-top: 1px solid var(--line); }
.msg p { margin: 0 0 .5rem; } .msg ul, .msg ol { margin: 0 0 .5rem; }
.msg-en { color: var(--muted); font-size: .95rem; }
.msg-h { font-weight: 700; font-family: var(--heading); }
.msg-gone { font-style: italic; }
.msg-key { grid-column: 1 / -1; justify-self: end; font: 11px var(--mono); color: var(--muted); }
.msg.choice { background: var(--shade); padding-left: .6rem; padding-right: .6rem; }
.options { list-style: none; padding: 0; margin: 0 0 .4rem; }
.options li { display: flex; gap: .55rem; align-items: baseline; padding: .25rem .4rem; }
.options li.picked { background: var(--primary-soft); }
.options li > :last-child { margin-bottom: 0; }
.options .opt { flex: none; font-weight: 700; }
.why { font-size: .9rem; } .why p { margin: .3rem 0; }
@media (max-width: 40rem) { .msg { grid-template-columns: 1fr; } }
"""

# ------------------------------------------------------------------------------------- the title

newNbBlock(NbTitle):
  kicker: string
  title: string
  lede: string
  toHtml:
    &"""<p class="kicker">{nb.localizedInline(blk.kicker)}</p>""" & "\n" &
      &"<h1>{nb.localizedInline(blk.title)}</h1>\n" & &"""<div class="lede">{nb.localized(blk.lede)}</div>"""

proc title*(nb: var Nb, kicker, title, lede: string) =
  nb.add newNbTitle(kicker = kicker, title = title, lede = lede)

template nbTitle*(tkicker, ttitle, tlede: string) =
  ## The top of the page: a small line (kicker), the title and the lede, all in Markdown.
  nb.title(tkicker, ttitle, tlede)

# ----------------------------------------------------------------------------------------- notes

type NoteKind* = enum
  nkPlain = "plain", nkCode = "code", nkGap = "gap"

newNbBlock(NbNote):
  text: string
  noteKind: NoteKind
  toHtml:
    &"""<div class="note {blk.noteKind}">{nb.localized(blk.text)}</div>"""

proc note*(nb: var Nb, text: string, kind: NoteKind) = nb.add newNbNote(text = text, noteKind = kind)

template nbNote*(ttext: string, tkind = nkPlain) =
  ## A sheet set apart: `nkCode` (green) is about the code above it, `nkGap` (the triangle) is
  ## something missing.
  nb.note(ttext, tkind)

# -------------------------------------------------------------------------------------- contents

newNbBlock(NbToc):
  toHtml:
    var items = ""
    for b in nb.doc.blocks:
      if b of NbText:
        for c in chunks(b.NbText.text):
          if c.startsWith("## "):
            let h = c[3 .. ^1].strip
            items.add &"""<li><a href="#{slug(h)}">{nb.localizedInline(h)}</a></li>"""
    &"""<nav class="toc" id="contents"><p class="toc-title">{nb.localizedInline("Contents")}</p><ol>{items}</ol></nav>"""

template nbToc* =
  ## The contents: every heading of level 2 of the page's text, linked; every heading links back.
  nb.add newNbToc()

# ---------------------------------------------------------------------------------------- status

newNbBlock(NbStatus):
  toHtml:
    {.cast(noSideEffect).}:
      let all = l10n.rendering.len == 0
      for lang in (if all: l10n.langs else: @[l10n.rendering]):
        let l = lang
        let t = proc (m: string): string = (l10n.seen.incl m; lookup(m, l).text)
        var rows: seq[tuple[language: string, messages, translated, machine, missing: int]]
        for s in l10n.stats:
          rows.add (l10n.names[l10n.langs.find(s.lang)], s.total, s.translated, s.machine, s.missing)
        let tab = tabella(rows):
          tabHeader t("The catalogs of this page")
          colsLabel:
            language: t("Language")
            messages: t("Messages")
            translated: t("Translated")
            machine: t("By Claude")
            missing: t("Missing")
          optCssTheme()
        let html = tab.toHtml(withStyle = false)
        result.add(if all: &"""<div data-l="{l}" lang="{l}">{html}</div>""" else: html)

template nbStatus* =
  ## How much of the page each language has, counted when the page was built.
  nb.add newNbStatus()

# ------------------------------------------------------------------------------ a proc, shown

proc procSource*(file, name: string): string =
  ## The top-level proc, func or template `name` of `file`, with its doc comment: from its first
  ## line to the last indented line after it.
  let lines = readFile(file).splitLines
  var start = -1
  for i, line in lines:
    for kind in ["proc ", "func ", "template ", "macro "]:
      if line.startsWith(kind & name & "*") or line.startsWith(kind & name & "(") or line.startsWith(kind & name & "["):
        start = i
    if start >= 0: break
  doAssert start >= 0, name & " not found in " & file
  var stop = start
  for i in start + 1 ..< lines.len:
    if lines[i].len > 0 and lines[i][0] != ' ': break
    if lines[i].strip.len > 0: stop = i
  lines[start .. stop].join("\n")

newNbBlock(NbProc):
  file: string
  code: string
  toHtml:
    &"""<div class="source"><p class="file">{esc(blk.file)}</p><pre><code class="nim hljs">{highlightNim(blk.code)}</code></pre></div>"""

template nbProc*(tfile: string, tnames: varargs[string]) =
  ## The procs `tnames` of `tfile` (beside the page's source), shown as they are in the file.
  block:
    let dir = nb.doc.thisFile.string.parentDir
    var code: seq[string]
    for n in tnames: code.add procSource(dir / tfile, n)
    nb.add newNbProc(file = tfile, code = code.join("\n\n"))

# --------------------------------------------------------------------------------- files, folded

newNbBlock(NbFoldCode):
  file: string
  code: string
  lang: string
  toHtml:
    let lines = blk.code.splitLines.len
    let code = if blk.lang == "nim": highlightNim(blk.code) else: esc(blk.code)
    &"""<details class="foldcode"><summary><code>{esc(blk.file)}</code> <span>{lines} lines</span></summary>""" &
      &"""<pre><code class="{(if blk.lang == "nim": "nim hljs" else: "language-" & blk.lang)}">{code}</code></pre></details>"""

template nbFoldCode*(tfile: string, tlang = "nim") =
  ## The whole file `tfile` (beside the page's source), folded under its name.
  nb.add newNbFoldCode(file = tfile, lang = tlang,
                       code = readFile(nb.doc.thisFile.string.parentDir / tfile).strip)

# ------------------------------------------------------------------------------------------ page

func pageHeader(blk: JsonNode, nb: Nb): string =
  &"""<header class="page"><span>{nb.localizedInline("nimib, in more than one language")}</span>{nb.switchHtml}</header>"""

func pageFooter(blk: JsonNode, nb: Nb): string =
  &"""<footer class="page">{nb.localizedInline("Written in Nim with Claude, in a [nimib](https://github.com/pietroppeter/nimib) 🐳 page; the code on this page ran when it was built. [Source on GitHub](https://github.com/pietroppeter/claude-artifacts/tree/main/nimib-localization/src).")}</footer>"""

func emptyPartial(blk: JsonNode, nb: Nb): string = ""

proc usePage*(nb: var Nb, title, description: string) =
  ## Munari, the header with the language switch, the footer.
  nb.doc.context["title"] = %title
  nb.doc.context["stylesheet"] = %(&"""<meta name="description" content="{esc(description)}">""" & "\n" &
    """<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2280%22>🐳</text></svg>">""" &
    "\n<style>\n" & pageCss & pageExtra & "</style>")
  nb.doc.context["highlight"] = %""
  nb.doc.context["nb_style"] = %""
  nb.doc.context["disableHighlightJs"] = %true
  nb.backend.partials["header"] = pageHeader
  nb.backend.partials["footer"] = pageFooter
  nb.backend.partials["left"] = emptyPartial
  nb.backend.partials["right"] = emptyPartial
