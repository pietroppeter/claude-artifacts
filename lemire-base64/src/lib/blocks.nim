## The custom blocks of the base64 benchmark page. Classes only: every style is in style.nim.
## Bar widths are the only inline numbers (data).
import std/[strformat, strutils, json]
import nimib

type NoteKind* = enum
  nkNimib = "nimib"       ## what it means for Nim
  nkReading = "reading"   ## what we measured or found
  nkCareful = "careful"   ## a caveat

func noteLabel(k: NoteKind): string =
  case k
  of nkNimib: "For Nim"
  of nkReading: "What we found"
  of nkCareful: "Careful"

newNbBlock(NbNote):
  level: NoteKind
  text: string
  toHtml:
    &"""<aside class="note {blk.level}"><span class="note-label">{noteLabel(blk.level)}</span>{markdownToHtml(blk.text)}</aside>"""

template nbNote*(tkind: NoteKind, ttext: string) =
  ## A labelled aside: `nbNote(nkCareful, "A shared cloud machine.")`
  nb.add newNbNote(level = tkind, text = ttext)

newNbBlock(NbLede):
  text: string
  toHtml:
    &"""<div class="lede">{markdownToHtml(blk.text)}</div>"""

template nbLede*(ttext: string) =
  ## The opening paragraph, larger than body text.
  nb.add newNbLede(text = ttext)

type Stat* = tuple[value, label: string]

newNbBlock(NbStats):
  stats: seq[Stat]
  toHtml:
    var s = """<div class="stats">"""
    for st in blk.stats:
      s.add &"""<div class="stat"><div class="stat-value">{st.value}</div><div class="stat-label">{st.label}</div></div>"""
    s & "</div>"

template nbStats*(tstats: seq[Stat]) =
  ## A row of headline numbers.
  nb.add newNbStats(stats = tstats)

type
  BarKind* = enum
    bkNim = "nim"      ## pure Nim
    bkFfi = "ffi"      ## Nim calling a C++ library
    bkOther = "other"  ## the other languages
  Bar* = tuple[label: string, value: float, kind: BarKind]

func swatch(k: BarKind, label: string): string =
  &"""<span class="key"><span class="swatch {k}"></span>{label}</span>"""

newNbBlock(NbBars):
  title: string
  note: string
  bars: seq[Bar]
  toHtml:
    var top = 0.0
    for b in blk.bars: top = max(top, b.value)
    var s = &"""<figure class="chart"><figcaption>{blk.title}</figcaption><div class="legend">""" &
      swatch(bkNim, "Nim") & swatch(bkFfi, "Nim calling simdutf") & swatch(bkOther, "other languages") &
      """</div><div class="bars">"""
    for b in blk.bars:
      let w = formatFloat(100 * b.value / max(top, 1e-9), ffDecimal, 1)
      let v = formatFloat(b.value, ffDecimal, 1)
      s.add &"""<div class="bar-row"><div class="bar-label">{markdownToHtml(b.label).strip.replace("<p>", "").replace("</p>", "")}</div><div class="bar-line"><span class="bar {b.kind}" style="width:{w}%"></span><span class="bar-value">{v} GB/s</span></div></div>"""
    s.add "</div>"
    if blk.note.len > 0: s.add &"""<p class="chart-note">{blk.note}</p>"""
    s & "</figure>"

template nbBars*(ttitle: string, tbars: seq[Bar], tnote = "") =
  ## A horizontal bar chart of speeds, coloured by kind.
  nb.add newNbBars(title = ttitle, bars = tbars, note = tnote)

func sourceFooter(blk: JsonNode, nb: Nb): string =
  """<span class="nb-small">After <a href="https://lemire.me/blog/2026/11/20/decoding-base64-email-attachments/">Daniel Lemire, “Decoding base64 email attachments”</a> (20 Nov 2026)</span>"""

proc useSourceFooter*(nb: var Nb) =
  ## The centre of the footer names the post this page replicates.
  nb.backend.partials["footer_center"] = sourceFooter
