## Translation notes: a nimib page that writes a language's catalog. Claude writes it (`it.nim`),
## a person reviews it in the review mode, and building it writes `it.po` from the template
## `messages.pot` that the page writes. Every message is given by its key (`msgKey`), so the
## notes never repeat the English: they show it, from the template.
##
##   nb.useNotes("it")                    # after usePage: the language, the template beside it
##   nbMsg "a1b2c3", "Italiano"           # the translation of one message, beside its English
##   nbChoice "a1b2c3", ["A", "B"], "why" # the first option is the translation; the others are shown
##   nbNotesCheck                         # what is missing, or left over: messages and keys
##   nbPoFile                             # the catalog this page writes, folded
##   nbSaveNotes                          # check, write <lang>.po, write the page
import std/[os, strutils, strformat, tables]
import nimib except md
import lingua

type
  Given = object
    text*: string
    options*: seq[string]   ## for a choice: every option, the first is `text`
    why*: string
  Notes* = object
    lang*, dir*: string
    reviewed*: bool                       ## true when a person has read every message
    pot*: seq[tuple[key, msgid: string]]
    english*: Table[string, string]       ## key: msgid
    given*: OrderedTable[string, Given]
    po*: string                           ## the catalog, once written

var notes*: Notes

func esc(s: string): string = s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))

func asHtml(md: string): string =
  ## A message as the page shows it, but a heading is a line, not a heading of the notes.
  if md.startsWith("## "): &"""<p class="msg-h">{esc(md[3 .. ^1])}</p>"""
  else: markdownToHtml(md)

proc useNotes*(nb: var Nb, lang: string, pot = "messages.pot", reviewed = false) =
  ## The notes of language `lang`, for the messages of the template `pot` (beside the notes).
  ## `reviewed`: every message has been read by a person, so none is marked `machine`.
  notes = Notes(lang: lang, dir: nb.doc.thisFile.string.parentDir, reviewed: reviewed)
  notes.pot = readPot(notes.dir / pot)
  for (k, m) in notes.pot: notes.english[k] = m

newNbBlock(NbMsg):
  key: string
  text: string
  options: seq[string]
  why: string
  toHtml:
    {.cast(noSideEffect).}:
      let en = notes.english.getOrDefault(blk.key)
      let tl = notes.lang
    let left = if en.len > 0: asHtml(en) else: """<p class="msg-gone">Not on the page any more.</p>"""
    var right = ""
    if blk.options.len > 1:
      right = """<ol class="options">"""
      for i, o in blk.options:
        right.add &"""<li{(if i == 0: " class=\"picked\"" else: "")}><span class="opt">{chr(ord('A') + i)}</span>{asHtml(o)}</li>"""
      right.add "</ol>"
      if blk.why.len > 0: right.add &"""<div class="why">{markdownToHtml(blk.why)}</div>"""
    else: right = asHtml(blk.text)
    &"""<div class="msg{(if blk.options.len > 1: " choice" else: "")}" id="m-{blk.key}"><div class="msg-en" lang="en">{left}</div>""" &
      &"""<div class="msg-tr" lang="{tl}">{right}</div><span class="msg-key">{blk.key}</span></div>"""

proc msg*(nb: var Nb, key: string, options: openArray[string], why = "") =
  notes.given[key] = Given(text: options[0], options: @options, why: why)
  nb.add newNbMsg(key = key, text = options[0], options = @options, why = why)

template nbMsg*(key, text: string) =
  ## The translation of the message `key`, shown beside its English.
  nb.msg(key, [text])

template nbChoice*(key: string, options: openArray[string], why: string) =
  ## A message Claude could translate in more than one way: the first option is the
  ## translation, the others are shown under it, with why the first was picked. To pick another,
  ## select it in the review mode and say so: the next version puts it first.
  nb.msg(key, options, why)

func missing*(n: Notes): seq[string] =
  for (k, _) in n.pot:
    if k notin n.given: result.add k

func leftOver*(n: Notes): seq[string] =
  for k in n.given.keys:
    if k notin n.english: result.add k

newNbBlock(NbNotesCheck):
  toHtml:
    {.cast(noSideEffect).}:
      let (miss, left) = (notes.missing, notes.leftOver)
      let total = notes.pot.len
    if miss.len == 0 and left.len == 0:
      &"""<div class="note code"><p>Every message of the page ({total}) has its translation here, and every key here is a message of the page.</p></div>"""
    else:
      var s = &"""<div class="note gap"><p><strong>{miss.len} of {total} messages</strong> have no translation here"""
      if left.len > 0: s.add &""", and <strong>{left.len}</strong> translations are of messages no longer on the page"""
      s.add ".</p>"
      if miss.len > 0:
        s.add "<ul>"
        {.cast(noSideEffect).}:
          for k in miss: s.add &"""<li><code>{k}</code>: {esc(notes.english[k].splitLines[0])}</li>"""
        s.add "</ul>"
      s & "</div>"

template nbNotesCheck* =
  ## Whether the notes and the page agree: messages with no translation, keys no longer used.
  nb.add newNbNotesCheck()

newNbBlock(NbPoFile):
  toHtml:
    {.cast(noSideEffect).}:
      let po = notes.po
      let name = notes.lang & ".po"
    &"""<details class="foldcode"><summary><code>{name}</code> <span>{po.splitLines.len} lines</span></summary>""" &
      &"""<pre><code class="language-text">{esc(po.strip)}</code></pre></details>"""

template nbPoFile* =
  ## The catalog these notes write, folded.
  nb.add newNbPoFile()

proc writeCatalog*() =
  ## `<lang>.po`: every message of the template, in its order, with its translation from the
  ## notes (empty if missing), its key, and `# machine` until the notes are reviewed.
  var c = Catalog()
  for (k, m) in notes.pot:
    var e = Entry(msgid: m, msgstr: notes.given.getOrDefault(k).text)
    if not notes.reviewed and e.msgstr.len > 0: e.comments.add "machine"
    e.comments.add "key: " & k
    c.entries[m] = e
  let path = notes.dir / notes.lang & ".po"
  c.writePo(path, notes.lang)
  notes.po = readFile(path)

template nbSaveNotes* =
  ## Write the catalog, say what is missing, write the notes page.
  writeCatalog()
  let (miss, left) = (notes.missing, notes.leftOver)
  if miss.len > 0 or left.len > 0:
    echo "[notes] ", notes.lang, ": ", miss.len, " messages without translation, ", left.len, " keys no longer used"
  nbSave
