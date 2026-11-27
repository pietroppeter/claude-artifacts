## The custom blocks of the Puščica page. Classes only: every style is in style.nim.
## The one inline style is a size bar's width in the explorer (data: a byte count).
import std/[strformat, strutils, os, osproc]
import nimib
import layout

type NoteKind* = enum
  nkIdea = "idea"         ## the point to take away
  nkNim = "nim"           ## about the Nim behind the page
  nkCareful = "careful"   ## a caveat
  nkPeople = "people"     ## about the people

func noteLabel(k: NoteKind): string =
  case k
  of nkIdea: "The idea"
  of nkNim: "In Nim"
  of nkCareful: "Careful"
  of nkPeople: "People"

newNbBlock(NbNote):
  level: NoteKind
  text: string
  toHtml:
    &"""<aside class="note {blk.level}"><span class="note-label">{noteLabel(blk.level)}</span>{markdownToHtml(blk.text)}</aside>"""

template nbNote*(tkind: NoteKind, ttext: string) =
  ## A labelled aside: `nbNote(nkCareful, "A toy glacier.")`
  nb.add newNbNote(level = tkind, text = ttext)

newNbBlock(NbLede):
  text: string
  toHtml:
    &"""<div class="lede">{markdownToHtml(blk.text)}</div>"""

template nbLede*(ttext: string) =
  ## The opening paragraph, larger than body text.
  nb.add newNbLede(text = ttext)

newNbBlock(NbScript):
  js: string
  toHtml:
    "<script>" & blk.js & "</script>"

template nbScript*(tjs: string) =
  ## Inline JavaScript at this point of the page (the widgets, compiled from Nim).
  nb.add newNbScript(js = tjs)

proc compileWidgets*(src, scratch: string): string =
  ## `nim js` the widgets at build time; the page inlines the result (artifacts allow no other host).
  createDir scratch
  let outp = scratch / "widgets.js"
  let (o, code) = execCmdEx("nim js -d:danger --hints:off --warnings:off -o:" & quoteShell(outp) & " " & quoteShell(src))
  doAssert code == 0, o
  readFile(outp)

import style

newNbBlock(NbThemes):
  toHtml:
    var s = """<nav class="themes" id="themes" aria-label="Pick a look"><p>Pick a look, after a Slovenian illustrator (palette and mood only, no pictures copied):</p><div class="row">"""
    for i, t in themes:
      s.add &"""<button type="button" id="th-{i}" data-theme="{t.id}" aria-pressed="false" title="{t.who}: {t.blurb}">{t.name}<small>{t.blurb.split(",")[0]}</small></button>"""
    s & "</div></nav>"

template nbThemes*() =
  ## The illustrator picker (widgets.nim wires it up).
  nb.add newNbThemes()

proc escHtml*(s: string): string =
  s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"))

newNbBlock(NbPoem):
  title: string
  verse: string
  source: string
  en: string
  it: string
  toHtml:
    var s = &"""<figure class="poem"><h4>{escHtml(blk.title)}</h4><div class="verse">{escHtml(blk.verse)}</div>"""
    for (lbl, t) in [("English", blk.en), ("Italiano", blk.it)]:
      if t.len > 0:
        s.add &"""<details class="tr"><summary>{lbl}</summary><div class="verse">{escHtml(t)}</div></details>"""
    s & &"""<figcaption class="src">{markdownToHtml(blk.source).strip.replace("<p>", "").replace("</p>", "")}</figcaption></figure>"""

template nbPoem*(ttitle, tverse, tsource: string; ten = ""; tit = "") =
  ## A poem, set as verse, with its translations folded underneath.
  nb.add newNbPoem(title = ttitle, verse = tverse, source = tsource, en = ten, it = tit)

newNbBlock(NbExplorer):
  caption: string
  toHtml:
    var s = """<figure class="explorer" id="lx">
<select id="lx-poem" aria-label="Poem"></select>
<div class="btns"><button type="button" id="lx-lines" aria-pressed="true">Lines</button><button type="button" id="lx-words" aria-pressed="false">Words</button><button type="button" id="lx-hex" aria-pressed="false">Show bytes</button><span class="sep"></span>"""
    for e in Encoding:
      s.add &"""<button type="button" id="lx-e{ord(e)}" aria-pressed="false">{e}</button>"""
    s.add """</div>
<div class="ctl"><label for="lx-from">Slice from</label><input type="range" id="lx-from" min="0" max="10" step="1" value="0"><output id="lx-from-v"></output></div>
<div class="ctl"><label for="lx-count">Length</label><input type="range" id="lx-count" min="0" max="10" step="1" value="0"><output id="lx-count-v"></output></div>
<p class="sec">The poem</p><div class="btns lang"><button type="button" id="lx-sl" aria-pressed="false">Slovenščina</button><button type="button" id="lx-en" aria-pressed="true">+ English</button><button type="button" id="lx-it" aria-pressed="false">+ Italiano</button></div>
<div class="ptext" id="lx-text"></div>
<p class="sec">The values (tap one)</p><div class="values" id="lx-values"></div>
<p class="sec">The buffers</p><div id="lx-buffers"></div>
<div class="out" id="lx-out" aria-live="polite"></div>"""
    s.add &"""<figcaption>{markdownToHtml(blk.caption).strip.replace("<p>", "").replace("</p>", "")}</figcaption></figure>"""
    s

template nbExplorer*(tcaption: string) =
  ## The layout explorer (widgets.nim draws it).
  nb.add newNbExplorer(caption = tcaption)

newNbBlock(NbHtml):
  html: string
  toHtml:
    blk.html

template nbHtml*(thtml: string) =
  ## Raw HTML (a small diagram), classes from style.nim only.
  nb.add newNbHtml(html = thtml)
