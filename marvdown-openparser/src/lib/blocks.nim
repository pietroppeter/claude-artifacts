## The custom blocks of the marvdown and openparser explainer. Classes only: every style is in style.nim.
import std/[strformat, strutils]
import nimib

func esc*(s: string): string = s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))
proc inlineMd*(md: string): string = markdownToHtml(md).strip.replace("<p>", "").replace("</p>", "")

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

type NoteKind* = enum
  nkAside = "aside"       ## a remark
  nkCareful = "careful"   ## a caveat, or something I could not verify
  nkNimib = "nimib"       ## what it means for nimib and the pages built on it

func noteLabel(k: NoteKind): string =
  case k
  of nkAside: "Aside"
  of nkCareful: "Careful"
  of nkNimib: "🐳 For nimib"

newNbBlock(NbNote):
  level: NoteKind
  text: string
  toHtml:
    &"""<aside class="note {blk.level}"><span class="note-label">{noteLabel(blk.level)}</span>{markdownToHtml(blk.text)}</aside>"""

template nbNote*(tkind: NoteKind, ttext: string) =
  ## A labelled aside: `nbNote(nkCareful, "...")`.
  nb.add newNbNote(level = tkind, text = ttext)

newNbBlock(NbToc):
  items: seq[(string, string)]   ## (anchor, Markdown label)
  toHtml:
    var s = """<nav class="toc" id="toc"><span class="toc-label">Contents</span><ol>"""
    for (a, label) in blk.items:
      s.add &"""<li><a href="#{a}">{inlineMd(label)}</a></li>"""
    s & "</ol></nav>"

template nbToc*(titems: seq[(string, string)]) =
  ## The contents, after the short version. Every chapter links back to it.
  nb.add newNbToc(items = titems)

newNbBlock(NbChapter):
  id: string
  title: string    ## Markdown
  sub: string      ## one line under the heading
  toHtml:
    let sub = if blk.sub.len > 0: &"""<span class="ch-sub">{inlineMd(blk.sub)}</span>""" else: ""
    &"""<h2 id="{blk.id}">{inlineMd(blk.title)}{sub}<a class="ch-top" href="#toc">↑ Contents</a></h2>"""

template nbChapter*(tid, ttitle: string; tsub = "") =
  ## A chapter heading with an anchor, a line under it and a link back to the contents.
  nb.add newNbChapter(id = tid, title = ttitle, sub = tsub)

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

type
  Side* = enum
    sNow = "now"        ## what nimib uses today
    sNew = "new"        ## the candidate (marvdown, openparser)
  Score* = tuple[label: string, passed, total: int, side: Side]

newNbBlock(NbScores):
  title: string
  note: string
  scores: seq[Score]
  toHtml:
    var s = &"""<figure class="scores"><figcaption>{inlineMd(blk.title)}</figcaption>"""
    for sc in blk.scores:
      let pct = if sc.total > 0: 100 * sc.passed / sc.total else: 0.0
      let w = formatFloat(pct, ffDecimal, 1)
      s.add &"""<div class="score"><div class="score-label">{inlineMd(sc.label)}</div><div class="score-line"><span class="score-bar {sc.side}" style="width:{w}%"></span><span class="score-value">{sc.passed} / {sc.total} · {int(pct + 0.5)}%</span></div></div>"""
    if blk.note.len > 0: s.add &"""<p class="scores-note">{inlineMd(blk.note)}</p>"""
    s & "</figure>"

template nbScores*(ttitle: string; tscores: seq[Score]; tnote = "") =
  ## Pass rates as horizontal bars: nimib's library today in teal, the candidate in lemon.
  nb.add newNbScores(title = ttitle, scores = tscores, note = tnote)

type Render* = tuple[name, md, now, new: string]

newNbBlock(NbRenders):
  renders: seq[Render]
  toHtml:
    var s = """<div class="renders">"""
    for r in blk.renders:
      s.add &"""<section class="render"><h4>{esc(r.name)}</h4><pre class="out src"><code class="language-text">{esc(r.md.strip(leading = false))}</code></pre>""" &
        &"""<span class="render-who now">nim-markdown</span><pre class="out"><code class="language-text">{esc(r.now.strip)}</code></pre>""" &
        &"""<span class="render-who new">marvdown</span><pre class="out"><code class="language-text">{esc(r.new.strip)}</code></pre></section>"""
    s & "</div>"

template nbRenders*(trenders: seq[Render]) =
  ## Markdown in, and the HTML each library writes for it, one card per input.
  nb.add newNbRenders(renders = trenders)
