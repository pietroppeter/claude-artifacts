## The custom blocks of the Nimony explainer. Classes only: every style is in style.nim.
import std/[strformat, strutils]
import nimib

func esc*(s: string): string = s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))
proc inlineMd*(md: string): string = markdownToHtml(md).strip.replace("<p>", "").replace("</p>", "")

func slug*(s: string): string =
  ## `NIF27` -> `nif27`, `.passive procs` -> `passive-procs`: the anchor of a term.
  for c in s.toLowerAscii:
    if c in {'a'..'z', '0'..'9'}: result.add c
    elif result.len > 0 and result[^1] != '-': result.add '-'
  result = result.strip(chars = {'-'})

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
  nkNim2 = "nim2"         ## what it means for Nim 2 users

func noteLabel(k: NoteKind): string =
  case k
  of nkAside: "Aside"
  of nkCareful: "Careful"
  of nkNim2: "For Nim 2 users"

newNbBlock(NbNote):
  level: NoteKind
  text: string
  toHtml:
    &"""<aside class="note {blk.level}"><span class="note-label">{noteLabel(blk.level)}</span>{markdownToHtml(blk.text)}</aside>"""

template nbNote*(tkind: NoteKind, ttext: string) =
  ## A labelled aside: `nbNote(nkCareful, "...")`.
  nb.add newNbNote(level = tkind, text = ttext)

newNbBlock(NbQuote):
  text: string
  who: string
  url: string
  date: string
  toHtml:
    &"""<blockquote class="quote">{markdownToHtml(blk.text)}<cite>{esc(blk.who)}, <a href="{blk.url}">{esc(blk.date)}</a></cite></blockquote>"""

template nbQuote*(ttext, turl, tdate: string; twho = "Araq") =
  ## A quote with who said it, where and when (Araq unless said otherwise).
  nb.add newNbQuote(text = ttext, who = twho, url = turl, date = tdate)

newNbBlock(NbTerm):
  term: string
  aka: string       ## other or older names, Markdown
  text: string      ## Markdown
  since: string     ## when it first appears, Markdown (a link to the source)
  toHtml:
    let aka = if blk.aka.len > 0: &"""<span class="term-aka">{inlineMd(blk.aka)}</span>""" else: ""
    let since = if blk.since.len > 0: &"""<span class="term-since">{inlineMd(blk.since)}</span>""" else: ""
    &"""<section class="term" id="t-{slug(blk.term)}"><div class="term-head"><span class="term-name">{inlineMd(blk.term)}</span>{aka}</div>{markdownToHtml(blk.text)}{since}</section>"""

template nbTerm*(tterm, ttext: string; taka = ""; tsince = "") =
  ## A glossary card for one term, at the point of the story where it shows up. Its anchor is
  ## `#t-<slug>`, so the index at the end can link to it.
  nb.add newNbTerm(term = tterm, text = ttext, aka = taka, since = tsince)

type Event* = tuple[date, text, url: string]   ## text in Markdown; url: the source

newNbBlock(NbEvents):
  events: seq[Event]
  toHtml:
    var s = """<ol class="events">"""
    for e in blk.events:
      let date = if e.url.len > 0: &"""<a href="{e.url}">{esc(e.date)}</a>""" else: esc(e.date)
      s.add &"""<li><span class="ev-date">{date}</span><div class="ev-text">{markdownToHtml(e.text)}</div></li>"""
    s & "</ol>"

template nbEvents*(tevents: seq[Event]) =
  ## A stretch of the timeline: date (linked to its source) and what happened.
  nb.add newNbEvents(events = tevents)

type Stage* = tuple[tool, what, makes: string]   ## Markdown each

newNbBlock(NbPipeline):
  title: string
  stages: seq[Stage]
  toHtml:
    var s = &"""<figure class="pipeline"><figcaption>{inlineMd(blk.title)}</figcaption><ol>"""
    for st in blk.stages:
      s.add &"""<li><span class="st-tool">{inlineMd(st.tool)}</span><span class="st-what">{inlineMd(st.what)}</span>"""
      if st.makes.len > 0: s.add &"""<span class="st-makes">{inlineMd(st.makes)}</span>"""
      s.add "</li>"
    s & "</ol></figure>"

template nbPipeline*(ttitle: string; tstages: seq[Stage]) =
  ## The compiler pipeline as a column of stages joined by arrows: tool, what it does, what it writes.
  nb.add newNbPipeline(title = ttitle, stages = tstages)

newNbBlock(NbToc):
  items: seq[(string, string)]   ## (anchor, Markdown label)
  toHtml:
    var s = """<nav class="toc" id="toc"><span class="toc-label">Contents</span><ol>"""
    for (a, label) in blk.items:
      s.add &"""<li><a href="#{a}">{inlineMd(label)}</a></li>"""
    s & "</ol></nav>"

template nbToc*(titems: seq[(string, string)]) =
  nb.add newNbToc(items = titems)

newNbBlock(NbChapter):
  id: string
  title: string    ## Markdown
  span: string     ## the months it covers
  toHtml:
    let span = if blk.span.len > 0: &"""<span class="ch-span">{esc(blk.span)}</span>""" else: ""
    &"""<h2 id="{blk.id}">{inlineMd(blk.title)}{span}<a class="ch-top" href="#toc">↑ Contents</a></h2>"""

template nbChapter*(tid, ttitle: string; tspan = "") =
  ## A chapter heading with an anchor, the months it covers and a link back to the contents.
  nb.add newNbChapter(id = tid, title = ttitle, span = tspan)

newNbBlock(NbPrompt):
  who: string
  date: string
  text: string     ## Markdown
  toHtml:
    &"""<figure class="prompt"><figcaption><span class="prompt-who">{esc(blk.who)}</span> asked Claude, {esc(blk.date)}</figcaption><blockquote>{markdownToHtml(blk.text)}</blockquote></figure>"""

template nbPrompt*(twho, tdate, ttext: string) =
  ## The request that started the page, as a chat bubble, verbatim.
  nb.add newNbPrompt(who = twho, date = tdate, text = ttext)
