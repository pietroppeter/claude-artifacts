## The custom blocks of the "Skill issues" explainer. Classes only: every style is in style.nim.
## The few inline numbers (bar widths, SVG coordinates) are data.
import std/[strformat, strutils, json]
import nimib
import data

type NoteKind* = enum
  nkPaper = "paper"       ## what the paper says
  nkNimib = "nimib"       ## what it means for Nim and nimib
  nkReading = "reading"   ## what we read off the paper's figures or counted ourselves
  nkCareful = "careful"   ## a caveat to keep in mind

func noteLabel(k: NoteKind): string =
  case k
  of nkPaper: "The paper"
  of nkNimib: "For nimib"
  of nkReading: "Our reading"
  of nkCareful: "Careful"

newNbBlock(NbNote):
  level: NoteKind
  text: string
  toHtml:
    &"""<aside class="note {blk.level}"><span class="note-label">{noteLabel(blk.level)}</span>{markdownToHtml(blk.text)}</aside>"""

template nbNote*(tkind: NoteKind, ttext: string) =
  ## A labelled aside: `nbNote(nkCareful, "One model, one agent.")`
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

# ---------------------------------------------------------------- the setup (paper's Figure 1)
type Knob* = tuple[name, what: string, yours: bool]

newNbBlock(NbKnobs):
  knobs: seq[Knob]
  toHtml:
    var s = """<div class="knobs">"""
    for k in blk.knobs:
      let (cls, tag) = if k.yours: ("yours", "you write it") else: ("fixed", "fixed")
      s.add &"""<div class="knob {cls}"><span class="knob-tag">{tag}</span><span class="knob-name">{k.name}</span><span class="knob-what">{k.what}</span></div>"""
    s & "</div>"

template nbKnobs*(tknobs: seq[Knob]) =
  ## The parts of a coding-agent setup, marked fixed or yours.
  nb.add newNbKnobs(knobs = tknobs)

# ---------------------------------------------------------------- tabs (shared by several blocks)
func tabsHtml(labels: openArray[string]): string =
  result = """<div class="tabs" role="tablist">"""
  for i, l in labels:
    let sel = if i == 0: "true" else: "false"
    result.add &"""<button class="tab" role="tab" aria-selected="{sel}" data-pane="{i}">{l}</button>"""
  result.add "</div>"

func paneOpen(i: int): string =
  let hidden = if i == 0: "" else: " hidden"
  &"""<div class="pane" data-pane="{i}"{hidden}>"""

# ---------------------------------------------------------------- the task lifecycle (Table 1)
type Step* = tuple[title, bauplan, nimib: string]

newNbBlock(NbLifecycle):
  id: string
  steps: seq[Step]
  toHtml:
    var s = &"""<figure class="tabbed lifecycle" id="{blk.id}">""" & tabsHtml(["Bauplan (the paper)", "A nimib page"])
    for i in 0 .. 1:
      s.add paneOpen(i) & """<ol class="steps">"""
      for st in blk.steps:
        let body = if i == 0: st.bauplan else: st.nimib
        s.add &"""<li><span class="step-title">{st.title}</span>{markdownToHtml(body)}</li>"""
      s.add "</ol></div>"
    s & "</figure>"

template nbLifecycle*(tid: string, tsteps: seq[Step]) =
  ## The six steps of one benchmark task, for Bauplan and for a nimib page, behind tabs.
  nb.add newNbLifecycle(id = tid, steps = tsteps)

# ---------------------------------------------------------------- horizontal bars
type Bar* = tuple[label: string, value: float, shown: string, cls: string]

func barsHtml(bars: seq[Bar], note: string): string =
  var top = 0.0
  for b in bars: top = max(top, b.value)
  result = """<div class="bars">"""
  for b in bars:
    let w = formatFloat(100 * b.value / max(top, 1e-9), ffDecimal, 1)
    result.add &"""<div class="bar-row"><div class="bar-label">{b.label}</div><div class="bar-line"><span class="bar {b.cls}" style="width:{w}%"></span><span class="bar-value">{b.shown}</span></div></div>"""
  result.add "</div>"
  if note.len > 0: result.add &"""<p class="chart-note">{note}</p>"""

type BarChart* = object
  tab*, title*, note*, legend*: string   ## legend: raw HTML of the keys, empty for one series
  bars*: seq[Bar]

newNbBlock(NbBarTabs):
  id: string
  charts: seq[BarChart]
  toHtml:
    var labels: seq[string]
    for c in blk.charts: labels.add c.tab
    var s = &"""<figure class="tabbed chart" id="{blk.id}">"""
    if blk.charts.len > 1: s.add tabsHtml(labels)
    for i, c in blk.charts:
      s.add paneOpen(i) & &"""<figcaption>{c.title}</figcaption>{c.legend}{barsHtml(c.bars, c.note)}</div>"""
    s & "</figure>"

template nbBarTabs*(tid: string, tcharts: seq[BarChart]) =
  ## Bar charts, behind tabs when there is more than one.
  nb.add newNbBarTabs(id = tid, charts = tcharts)

func key*(cls, label: string): string =
  &"""<span class="key"><span class="swatch {cls}"></span>{label}</span>"""

func legend*(keys: varargs[string]): string =
  """<div class="legend">""" & keys.join("") & "</div>"

# ---------------------------------------------------------------- the optimization curves (Figure 4)
const
  W = 320.0
  H = 190.0
  padL = 34.0
  padR = 8.0
  padT = 8.0
  padB = 26.0
  yLo = 0.70
  yHi = 1.00

func xOf(i, n: int): float = padL + (W - padL - padR) * i.float / max(n - 1, 1).float
func yOf(v: float): float = padT + (H - padT - padB) * (yHi - v) / (yHi - yLo)
func f1(x: float): string = formatFloat(x, ffDecimal, 1)
func r3(x: float): string = formatFloat(x, ffDecimal, 3)

func curveSvg(c: Curve): string =
  let n = c.validation.len
  let pick = c.byValidation
  result = &"""<svg class="curve" viewBox="0 0 {W} {H}" role="img" aria-label="validation and test reward of {n} candidates of {c.skill}">"""
  for v in [0.7, 0.8, 0.9, 1.0]:
    result.add &"""<line class="grid" x1="{padL}" x2="{W - padR}" y1="{f1 yOf(v)}" y2="{f1 yOf(v)}"/><text class="axis" x="{padL - 5}" y="{f1(yOf(v) + 4)}" text-anchor="end">{v:.1f}</text>"""
  for i in 0 ..< n:
    if i mod 2 == 0 or n <= 11:
      result.add &"""<text class="axis" x="{f1 xOf(i, n)}" y="{H - 8}" text-anchor="middle">{i}</text>"""
  let bw = (W - padL - padR) / max(n - 1, 1).float
  result.add &"""<rect class="band pick" x="{f1(xOf(pick.candidate, n) - bw / 2)}" y="{padT}" width="{f1 bw}" height="{f1(H - padT - padB)}"/>"""
  result.add &"""<rect class="band cursor" x="0" y="{padT}" width="{f1 bw}" height="{f1(H - padT - padB)}" visibility="hidden"/>"""
  for (cls, vs) in [("val", c.validation), ("test", c.test)]:
    var pts: seq[string]
    for i, v in vs: pts.add f1(xOf(i, n)) & "," & f1(yOf(v))
    result.add &"""<polyline class="line {cls}" points="{pts.join(" ")}"/>"""
  for i, v in c.validation:
    result.add &"""<circle class="mark val" cx="{f1 xOf(i, n)}" cy="{f1 yOf(v)}" r="4"/>"""
  for i, v in c.test:
    result.add &"""<rect class="mark test" x="{f1(xOf(i, n) - 4)}" y="{f1(yOf(v) - 4)}" width="8" height="8"/>"""
  for i in 0 ..< n:   # hit targets: a full-height column per candidate, wider than the marks
    result.add &"""<rect class="hit" data-i="{i}" x="{f1(xOf(i, n) - bw / 2)}" y="0" width="{f1 bw}" height="{H}"/>"""
  result.add "</svg>"

func pickLine(c: Curve): string =
  let p = c.byValidation
  &"""GEPA's pick (best validation) is candidate <b>{p.candidate}</b>: test reward {r3 p.test} vs {r3 c.test[0]} for the seed, <b>{signed p.gain}%</b>."""

newNbBlock(NbCurves):
  id: string
  toHtml:
    var labels: seq[string]
    for c in curves: labels.add c.skill.short
    var s = &"""<figure class="tabbed chart curves" id="{blk.id}">""" & tabsHtml(labels)
    for i, c in curves:
      s.add paneOpen(i) & &"""<figcaption>{c.skill}</figcaption>""" &
        legend(key("val round", "validation reward"), key("test", "test reward (held out)"), key("gepa", "picked by validation")) &
        curveSvg(c) & &"""<p class="readout" aria-live="polite" data-default="{pickLine(c).replace("\"", "&quot;")}">{pickLine(c)}</p></div>"""
    s & """<p class="chart-note">Tap a candidate to read its numbers. Candidate 0 is the seed skill. The y axis starts at 0.7 to make the differences visible; the paper's starts at 0.</p></figure>"""

template nbCurves*(tid: string) =
  ## Figure 4 as six tappable line charts, behind tabs.
  nb.add newNbCurves(id = tid)

# ---------------------------------------------------------------- the quiz
newNbBlock(NbQuiz):
  id: string
  toHtml:
    &"""<div class="widget quiz" id="{blk.id}">
<div class="quiz-top"><span class="widget-title">Which check catches it?</span><span class="quiz-score">0 / 0</span></div>
<p class="quiz-domain"></p>
<blockquote class="quiz-prompt"></blockquote>
<div class="quiz-buttons"><button data-k="0" class="pick trace">trace</button><button data-k="1" class="pick state">state</button><button data-k="2" class="pick judge">judge</button></div>
<p class="quiz-feedback" aria-live="polite"></p>
<button class="quiz-next">Next case</button>
</div>"""

template nbQuiz*(tid: string) =
  ## The empty quiz card; the page's script fills it with cases.
  nb.add newNbQuiz(id = tid)

func sourceFooter(blk: JsonNode, nb: Nb): string =
  """<span class="nb-small">Explainer of Schneider, Ghilardi, Piccinini &amp; Tagliabue, “Skill Issues” (VLDB ADS 2026).</span>"""

proc useSourceFooter*(nb: var Nb) =
  ## The centre of the footer names the paper.
  nb.backend.partials["footer_center"] = sourceFooter
