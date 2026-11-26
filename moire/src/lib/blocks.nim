## The custom blocks of the moiré page. Classes only: every style is in style.nim.
## The one inline style is a canvas's aspect ratio (data: each widget's own shape).
import std/[strformat, strutils, os, osproc]
import nimib

type NoteKind* = enum
  nkIdea = "idea"         ## the point to take away
  nkNim = "nim"           ## about the Nim behind the page
  nkCareful = "careful"   ## a caveat

func noteLabel(k: NoteKind): string =
  case k
  of nkIdea: "The idea"
  of nkNim: "In Nim"
  of nkCareful: "Careful"

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

newNbBlock(NbFormula):
  text: string
  note: string
  toHtml:
    &"""<div class="formula">{blk.text}<small>{markdownToHtml(blk.note).strip.replace("<p>", "").replace("</p>", "")}</small></div>"""

template nbFormula*(ttext: string, tnote = "") =
  ## A formula, set large (plain text with <i>, <sub>: no maths library).
  nb.add newNbFormula(text = ttext, note = tnote)

type
  ControlKind* = enum ckSlider, ckButton, ckToggle
  Control* = object
    id*, label*: string
    case kind*: ControlKind
    of ckSlider: lo*, hi*, step*, value*: float
    of ckButton: discard
    of ckToggle: pressed*: bool    ## one of a group: the page sets aria-pressed

func slider*(id, label: string; lo, hi, step, value: float): Control =
  Control(kind: ckSlider, id: id, label: label, lo: lo, hi: hi, step: step, value: value)
func button*(id, label: string): Control = Control(kind: ckButton, id: id, label: label)
func toggle*(id, label: string; pressed = false): Control =
  Control(kind: ckToggle, id: id, label: label, pressed: pressed)

newNbBlock(NbWidget):
  id: string
  aspect: float
  drag: string          ## "", "x" or "xy": what a finger on the canvas does
  label: string         ## what the picture shows, for screen readers
  controls: seq[Control]
  hint: string
  caption: string
  toHtml:
    let cls = if blk.drag.len > 0: &""" class="drag-{blk.drag}"""" else: ""
    var s = &"""<figure class="widget" id="{blk.id}"><canvas id="{blk.id}-c"{cls} style="aspect-ratio:1/{blk.aspect}" role="img" aria-label="{blk.label}"></canvas>"""
    if blk.hint.len > 0: s.add &"""<p class="hint">{blk.hint}</p>"""
    s.add &"""<p class="out" id="{blk.id}-out" aria-live="polite"></p>"""
    var btns = ""
    for c in blk.controls:
      case c.kind
      of ckSlider:
        s.add &"""<div class="ctl"><label for="{c.id}">{c.label}</label><input type="range" id="{c.id}" min="{c.lo}" max="{c.hi}" step="{c.step}" value="{c.value}"><output id="{c.id}-v"></output></div>"""
      of ckButton:
        btns.add &"""<button type="button" id="{c.id}">{c.label}</button>"""
      of ckToggle:
        btns.add &"""<button type="button" id="{c.id}" aria-pressed="{c.pressed}">{c.label}</button>"""
    if btns.len > 0: s.add &"""<div class="btns">{btns}</div>"""
    if blk.caption.len > 0:
      s.add &"""<figcaption>{markdownToHtml(blk.caption).strip.replace("<p>", "").replace("</p>", "")}</figcaption>"""
    s & "</figure>"

template nbWidget*(tid: string; taspect: float; tlabel: string; tcontrols: openArray[Control] = [];
                   tdrag = ""; thint = ""; tcaption = "") =
  ## A canvas the widgets script (widgets.nim) draws into, with its sliders and buttons.
  nb.add newNbWidget(id = tid, aspect = taspect, drag = tdrag, label = tlabel, controls = @tcontrols,
                     hint = thint, caption = tcaption)

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
