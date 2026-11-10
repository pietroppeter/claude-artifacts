## The blocks of the page: what it says more than once, or what plain Markdown can't say. The
## page (`index.nim`) is Markdown, nimib's blocks, tabelline's `nbTable` and these; their CSS is in
## `style.nim`.
##
##   nb.usePage(title, description)     # both looks, the header with the switch, the footer
##   nbTitle kicker, title, lede        # the top of the page
##   nbEditions [("2020", "20 June")]   # a strip of small cards
##   nbNote text, nkCode                # a sheet set apart: plain, about the code, or a gap
##   nbTabs labels: body                # one tab per label, one block of `body` per tab
##   nbSource "nimconf.nim", "plain"    # a proc of a file, shown and not run
##   nbFoldCode "nimconf.nim"            # a whole file, folded under its name
import std/[json, os, strutils, strformat]
import nimib except md
import nimib/highlight
import style

func esc(s: string): string = s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))
func inline(md: string): string = markdownToHtml(md).strip.replace("<p>", "").replace("</p>", "")

# ------------------------------------------------------------------------------------- the title

newNbBlock(NbTitle):
  kicker: string
  title: string
  lede: string
  toHtml:
    &"""<p class="kicker">{inline(blk.kicker)}</p>""" & "\n" & &"<h1>{inline(blk.title)}</h1>\n" &
      &"""<div class="lede">{markdownToHtml(blk.lede)}</div>"""

proc title*(nb: var Nb, kicker, title, lede: string) =
  nb.add newNbTitle(kicker = kicker, title = title, lede = lede)

template nbTitle*(tkicker, ttitle, tlede: string) =
  ## The top of the page: a small line (kicker), the title and the lede, all in Markdown.
  nb.title(tkicker, ttitle, tlede)

# ------------------------------------------------------------------------------------ the editions

newNbBlock(NbEditions):
  items: seq[(string, string)]
  toHtml:
    var lis = ""
    for (big, small) in blk.items:
      lis.add &"""<li><b>{esc(big)}</b><span>{inline(small)}</span></li>"""
    &"""<ul class="editions">{lis}</ul>"""

proc editionCards*(nb: var Nb, items: openArray[(string, string)]) = nb.add newNbEditions(items = @items)

template nbEditions*(titems: openArray[(string, string)]) =
  ## A strip of small cards, a big word and a line under it: the editions at a glance.
  nb.editionCards(titems)

# ----------------------------------------------------------------------------------------- notes

type NoteKind* = enum
  nkPlain = "plain", nkCode = "code", nkGap = "gap"

newNbBlock(NbNote):
  text: string
  noteKind: NoteKind
  toHtml:
    &"""<div class="note {blk.noteKind}">{markdownToHtml(blk.text)}</div>"""

proc note*(nb: var Nb, text: string, kind: NoteKind) = nb.add newNbNote(text = text, noteKind = kind)

template nbNote*(ttext: string, tkind = nkPlain) =
  ## A sheet set apart, with its straight top edge: `nkCode` (green) is about the code above it,
  ## `nkGap` (the triangle) says where the data is missing or does not agree.
  nb.note(ttext, tkind)

# ------------------------------------------------------------------------------------------ tabs

newNbBlock(NbTabs of NbContainer):
  labels: seq[string]
  group: string
  toHtml:
    var bar = &"""<div class="tabs-bar" role="tablist" aria-label="{esc(blk.group)}">"""
    var panels = ""
    for i, b in blk.blocks:
      let label = if i < blk.labels.len: blk.labels[i] else: $(i + 1)
      bar.add &"""<button type="button" role="tab" aria-selected="{i == 0}">{esc(label)}</button>"""
      # without JavaScript every panel shows, each under its label
      panels.add &"""<div class="tab-panel" role="tabpanel" aria-label="{esc(label)}">""" & nb.render(b) & "</div>"
    """<div class="tabs">""" & bar & "</div>" & panels & "</div>"

func tabsBlock(labels: openArray[string], group: string): NbTabs = newNbTabs(labels = @labels, group = group)

template nbTabs*(tlabels: openArray[string], tgroup: string, body: untyped) =
  ## One tab per label: each block that `body` adds (a table) is the panel of one tab, in order.
  let tabs = tabsBlock(tlabels, tgroup)
  nb.withContainer(tabs):
    body
  nb.add tabs

# ---------------------------------------------------------------------------- code, shown not run

proc procSource*(file, name: string): string =
  ## The source of the top-level proc, func, iterator or const `name` in `file`, with its doc comment:
  ## from its line to the next line that starts at column 0.
  let lines = readFile(file).splitLines
  var start = -1
  for i, line in lines:
    for kind in ["proc ", "func ", "iterator ", "const "]:
      if line.startsWith(kind & name & "*") or line.startsWith(kind & name & "("):
        start = i
    if start >= 0: break
  if start < 0: raise newException(KeyError, name & " is not in " & file)
  var stop = start + 1
  while stop < lines.len and (lines[stop].len == 0 or lines[stop][0] == ' '): inc stop
  while stop > start and lines[stop - 1].strip.len == 0: dec stop
  lines[start ..< stop].join("\n")

newNbBlock(NbSource):
  file: string
  code: string
  toHtml:
    &"""<div class="source"><p class="file">{esc(blk.file)}</p><pre><code class="nohighlight nim hljs">""" &
      highlightNim(blk.code) & "</code></pre></div>"

proc source*(nb: var Nb, file: string, names: openArray[string]) =
  let dir = nb.doc.thisFile.string.parentDir
  var code: seq[string]
  for name in names: code.add procSource(dir / file, name)
  nb.add newNbSource(file = file, code = code.join("\n\n"))

template nbSource*(tfile: string, tnames: varargs[string]) =
  ## The procs `tnames` of `tfile` (beside the page's source), as they are in the file: the code
  ## that the page explains is the code that downloaded the data.
  nb.source(tfile, tnames)

# ------------------------------------------------------------------------------ files, folded
# After tabelline's `nbFoldCode` (its docs, PR #34): a file folded under its path and its length.

newNbBlock(NbFoldCode):
  title: string
  anchor: string
  path: string
  lang: string
  code: string
  toHtml:
    let lines = blk.code.splitLines.len
    let name = if blk.title.len > 0: inline(blk.title) else: "<code>" & esc(blk.path) & "</code>"
    let body = case blk.lang
      of "nim": "<pre><code class=\"nohighlight nim hljs\">" & highlightNim(blk.code) & "</code></pre>"
      of "md", "text": "<pre><code class=\"language-text\">" & esc(blk.code) & "</code></pre>"
      else: &"""<pre><code class="language-{blk.lang}">""" & esc(blk.code) & "</code></pre>"
    let id = if blk.anchor.len > 0: &" id=\"{blk.anchor}\"" else: ""
    &"""<details class="foldcode"{id}><summary>{name} <span>{lines} lines</span></summary>{body}</details>"""

proc foldCode*(nb: var Nb, file, title, lang, anchor: string) =
  let path = nb.doc.thisFile.string.parentDir / file
  let lang = if lang.len > 0: lang
             else: (case file.splitFile.ext
                    of ".nim", ".nims": "nim"
                    of ".md": "md"
                    of ".tsv", ".txt": "text"
                    else: "sh")
  nb.add newNbFoldCode(title = title, anchor = anchor, path = file, lang = lang, code = readFile(path).strip(chars = {'\n'}))

template nbFoldCode*(tfile: string, ttitle = "", tlang = "", tid = "") =
  ## The file `tfile` (beside the page's source), folded under its name (or `ttitle`, in
  ## Markdown) and its number of lines: *+* opens it. `tid` lets a link open it (`#source`).
  nb.foldCode(tfile, ttitle, tlang, tid)

# -------------------------------------------------------------------------------------- the page

const lookHead = """<script>
(function () {
  var root = document.documentElement;
  root.classList.add('js');
  try {
    var q = new URLSearchParams(location.search).get('look');
    if (q === 'munari' || q === 'nimconf') localStorage.setItem('nimconf-look', q);
    var l = q || localStorage.getItem('nimconf-look');
    root.dataset.look = (l === 'munari') ? 'munari' : 'nimconf';   // NimConf is the default
  } catch (e) { root.dataset.look = 'nimconf'; }
})();
</script>"""

const bodyScript = """<script>
(function () {
  var root = document.documentElement;
  function show() {
    document.querySelectorAll('.looks button').forEach(function (b) {
      b.setAttribute('aria-pressed', b.dataset.look === root.dataset.look ? 'true' : 'false');
    });
  }
  document.querySelectorAll('.looks button').forEach(function (b) {
    b.addEventListener('click', function () {
      root.dataset.look = b.dataset.look;
      try { localStorage.setItem('nimconf-look', b.dataset.look); } catch (e) {}
      show();
    });
  });
  show();
  // "Show source" in the footer opens the folded index.nim and goes to it
  function openSource() {
    var d = document.getElementById('source');
    if (d && location.hash === '#source') { d.open = true; d.scrollIntoView(); }
  }
  window.addEventListener('hashchange', openSource);
  document.querySelectorAll('a.show-source').forEach(function (a) {
    a.addEventListener('click', function () { setTimeout(openSource, 0); });
  });
  openSource();
  // tabs: with JavaScript, one panel at a time
  document.querySelectorAll('.tabs').forEach(function (tabs) {
    var buttons = tabs.querySelectorAll('.tabs-bar button');
    var panels = tabs.querySelectorAll(':scope > .tab-panel');
    function pick(n) {
      buttons.forEach(function (b, i) { b.setAttribute('aria-selected', i === n ? 'true' : 'false'); });
      panels.forEach(function (p, i) { p.hidden = i !== n; });
    }
    buttons.forEach(function (b, i) { b.addEventListener('click', function () { pick(i); }); });
    pick(0);
  });
})();
</script>"""

func pageHeader(blk: JsonNode, nb: Nb): string =
  """<header class="page"><span>NimConf, in tables</span>
<div class="looks" role="group" aria-label="Look of the page"><button type="button" data-look="munari" aria-pressed="true">Munari</button><button type="button" data-look="nimconf" aria-pressed="false">NimConf</button></div>
</header>"""

func pageFooter(blk: JsonNode, nb: Nb): string =
  """<footer class="page">Written in Nim with Claude, in a <a href="https://github.com/pietroppeter/nimib">nimib</a> 🐳 page,
tables by <a href="https://pietroppeter.github.io/tabelline/">tabelline</a>; the code on this page ran when it was built.
<a href="#source" class="show-source">Show source</a> (<code>index.nim</code>, folded at the end with the other files) ·
<a href="https://github.com/pietroppeter/claude-artifacts/tree/main/nimconf-schedules/src">all the files and the data on GitHub</a>.</footer>""" & bodyScript

func emptyPartial(blk: JsonNode, nb: Nb): string = ""

proc usePage*(nb: var Nb, title, description: string) =
  ## The page: both looks (`style.nim`), the header with the switch between them, the footer.
  nb.doc.context["title"] = %title
  nb.doc.context["stylesheet"] = %(&"""<meta name="description" content="{esc(description)}">""" & "\n" &
    """<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2280%22>👑</text></svg>">""" &
    "\n" & lookHead & "\n<style>\n" & pageCss & "</style>")
  nb.doc.context["highlight"] = %""
  nb.doc.context["nb_style"] = %""
  nb.doc.context["disableHighlightJs"] = %true
  nb.backend.partials["header"] = pageHeader
  nb.backend.partials["footer"] = pageFooter
  nb.backend.partials["left"] = emptyPartial
  nb.backend.partials["right"] = emptyPartial
