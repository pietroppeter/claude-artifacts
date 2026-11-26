## The custom blocks of the conda-for-nim explainer. Classes only: every style is in style.nim.
import std/[math, sequtils, strformat, strutils, json]
import nimib

func esc*(s: string): string = s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))
proc inlineMd*(md: string): string = markdownToHtml(md).strip.replace("<p>", "").replace("</p>", "")

newNbBlock(NbKicker):
  text: string
  toHtml:
    &"""<p class="kicker">{esc(blk.text)}</p>"""

template nbKicker*(ttext: string) =
  ## A handwritten line above a title, as on prefix.dev's slides.
  nb.add newNbKicker(text = ttext)

newNbBlock(NbLede):
  text: string
  toHtml:
    &"""<div class="lede">{markdownToHtml(blk.text)}</div>"""

template nbLede*(ttext: string) =
  ## The paragraph under the title.
  nb.add newNbLede(text = ttext)

newNbBlock(NbTldr):
  text: string
  toHtml:
    &"""<div class="tldr"><span class="tldr-label">The short version</span>{markdownToHtml(blk.text)}</div>"""

template nbTldr*(ttext: string) =
  ## The short version, in a box: a Markdown list.
  nb.add newNbTldr(text = ttext)

newNbBlock(NbPrompt):
  who: string
  date: string
  texts: seq[string]
  toHtml:
    var quotes = ""
    for t in blk.texts: quotes.add markdownToHtml(t)
    &"""<figure class="prompt"><figcaption><span class="prompt-who">{esc(blk.who)}</span> asked Claude, {esc(blk.date)}</figcaption><blockquote>{quotes}</blockquote></figure>"""

template nbPrompt*(twho, tdate: string; ttexts: openArray[string]) =
  ## The messages that started the page, as one chat bubble, verbatim.
  nb.add newNbPrompt(who = twho, date = tdate, texts = @ttexts)

type NoteKind* = enum
  nkAside = "aside"       ## a remark
  nkCareful = "careful"   ## a caveat, a rough edge
  nkNim = "nim"           ## about Nim
  nkConda = "conda"       ## about conda

func noteLabel(k: NoteKind): string =
  case k
  of nkAside: "Aside"
  of nkCareful: "Careful"
  of nkNim: "👑 Nim"
  of nkConda: "🐍 Conda"

newNbBlock(NbNote):
  level: NoteKind
  text: string
  toHtml:
    &"""<aside class="note {blk.level}"><span class="note-label">{noteLabel(blk.level)}</span>{markdownToHtml(blk.text)}</aside>"""

template nbNote*(tkind: NoteKind, ttext: string) =
  ## A labelled aside: `nbNote(nkCareful, "...")`.
  nb.add newNbNote(level = tkind, text = ttext)

newNbBlock(NbFold):
  summary: string
  text: string
  toHtml:
    &"""<details class="fold"><summary>{inlineMd(blk.summary)}</summary>{markdownToHtml(blk.text)}</details>"""

template nbFold*(tsummary, ttext: string) =
  ## Markdown folded under a summary: details a reader can skip.
  nb.add newNbFold(summary = tsummary, text = ttext)

proc codeHtml(lang, code: string): string =
  if lang == "nim": &"""<pre><code class="hljs nim">{highlightNim(code)}</code></pre>"""
  else: &"""<pre><code class="language-{lang}">{esc(code)}</code></pre>"""

newNbBlock(NbFile):
  path: string
  lang: string
  code: string
  folded: bool
  toHtml:
    let n = blk.code.countLines
    if blk.folded:
      &"""<details class="source"><summary><code>{esc(blk.path)}</code> <span class="src-lines">{n} lines</span></summary>{codeHtml(blk.lang, blk.code)}</details>"""
    else:
      &"""<figure class="file"><figcaption>{esc(blk.path)}</figcaption>{codeHtml(blk.lang, blk.code)}</figure>"""

template nbFile*(tpath, tlang, tcode: string; tfolded = false) =
  ## A file of the PoC, with its name on a tab (or folded when `tfolded`). The code is the
  ## real file, read at build time; Nim is highlighted by nimib, the rest by tools/codeblocks.py.
  nb.add newNbFile(path = tpath, lang = tlang, code = tcode.strip(leading = false), folded = tfolded)

newNbBlock(NbTerm):
  title: string
  text: string
  toHtml:
    var lines: seq[string]
    for l in blk.text.strip(leading = false).splitLines:
      if l.startsWith("$ "): lines.add &"""<span class="term-cmd">{esc(l[2..^1])}</span>"""
      else: lines.add esc(l)
    &"""<figure class="term"><figcaption>{esc(blk.title)}</figcaption><pre class="nb-output">{lines.join("\n")}</pre></figure>"""

template nbTerm*(ttitle, ttext: string) =
  ## A terminal: lines starting with `$ ` are commands, the rest is what they printed,
  ## captured by poc/run.sh.
  nb.add newNbTerm(title = ttitle, text = ttext)

type Card* = object
  name*, who*, motto*, text*: string
  conda*: bool

newNbBlock(NbCards):
  cards: seq[Card]
  toHtml:
    var s = ""
    for c in blk.cards:
      let cls = if c.conda: "card conda" else: "card"
      s.add &"""<div class="{cls}"><h4>{esc(c.name)}</h4><div class="card-who">{inlineMd(c.who)}</div><div class="card-motto">{esc(c.motto)}</div>{markdownToHtml(c.text)}</div>"""
    &"""<div class="cards">{s}</div>"""

template nbCards*(tcards: openArray[Card]) =
  ## A grid of cards, one per tool.
  nb.add newNbCards(cards = @tcards)

newNbBlock(NbWheel):
  spokes: seq[string]
  caption: string
  toHtml:
    # the wheel on Wolf's slide, redrawn: one spoke per language, and a dashed one for Nim
    let (wx, wy, wr) = (170.0, 160.0, 112.0)
    let n = blk.spokes.len + 1
    var s = &"""<circle class="wh-ring" wx="{wx}" wy="{wy}" wr="{wr}"/><circle class="wh-ring" wx="{wx}" wy="{wy}" wr="{wr-8}" stroke-width="1"/>"""
    for i in 0 ..< n:
      let a = -PI/2 + 2*PI*i.float/n.float
      let (x1, y1) = (wx + 34*cos(a), wy + 34*sin(a))
      let (x2, y2) = (wx + (wr-8)*cos(a), wy + (wr-8)*sin(a))
      let (lx, ly) = (wx + (wr+28)*cos(a), wy + (wr+20)*sin(a))
      if i < blk.spokes.len:
        s.add &"""<line class="wh-spoke" x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}"/><text class="wh-lab" x="{lx:.1f}" y="{ly:.1f}">{esc(blk.spokes[i])}</text>"""
      else:
        s.add &"""<line class="wh-nim" x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}"/><text class="wh-nim-lab" x="{lx:.1f}" y="{ly:.1f}">Nim?</text>"""
    s.add &"""<circle class="wh-hub" wx="{wx}" wy="{wy}" wr="34"/><text class="wh-hub-t" x="{wx}" y="{wy}">conda</text>"""
    &"""<figure class="wheel"><svg viewBox="0 0 340 320" role="img" aria-label="conda at the centre of a wheel of languages, with a dashed spoke for Nim">{s}</svg><figcaption>{inlineMd(blk.caption)}</figcaption></figure>"""

template nbWheel*(tspokes: openArray[string]; tcaption: string) =
  nb.add newNbWheel(spokes = @tspokes, caption = tcaption)

newNbBlock(NbBars):
  rows: seq[(string, float, bool)]
  unit: string
  caption: string
  toHtml:
    let mx = blk.rows.mapIt(it[1]).max
    var s = ""
    for (label, v, conda) in blk.rows:
      let w = max(0.5, 100 * v / mx)
      let cls = if conda: "bar-fill conda" else: "bar-fill"
      let shown = if v < 1: &"{v:.2f} {blk.unit}" else: &"{v:.1f} {blk.unit}"
      s.add &"""<div class="bar-row"><span>{inlineMd(label)}</span><div class="bar-track"><div class="{cls}" style="width:{w:.1f}%"></div><span class="bar-val">{shown}</span></div></div>"""
    &"""<figure class="bars">{s}<figcaption>{inlineMd(blk.caption)}</figcaption></figure>"""

template nbBars*(trows: openArray[(string, float, bool)]; tunit, tcaption: string) =
  ## Horizontal bars for a few measured times (conda's in green).
  nb.add newNbBars(rows = @trows, unit = tunit, caption = tcaption)

const raceJs = staticRead("race.js")

newNbBlock(NbRace):
  data: string     ## JSON: {pkg: {deps: {name: [deps...]}, versions: {name: v}}}
  toHtml:
    &"""<section class="race" id="race" aria-label="clone-first against index-first, step by step">
<div class="rc-row" role="group" aria-label="what to install"><span class="rc-label">install</span><span id="rc-pkgs"></span></div>
<div class="rc-lane" id="rc-clone"></div>
<div class="rc-lane conda" id="rc-index"></div>
<div class="rc-row">
  <button type="button" class="rc-btn primary" id="rc-step">Next round trip ▸</button>
  <button type="button" class="rc-btn" id="rc-play">▶ Play</button>
  <button type="button" class="rc-btn" id="rc-reset">↺ Reset</button>
</div>
<p class="rc-verdict" id="rc-verdict" aria-live="polite"></p>
<noscript><p>This explainer needs JavaScript.</p></noscript>
<script type="application/json" id="rc-data">{blk.data}</script>
</section><script>{raceJs}</script>"""

template nbRace*(tdata: JsonNode) =
  ## The interactive: who knows the dependency graph, and when.
  nb.add newNbRace(data = $tdata)
