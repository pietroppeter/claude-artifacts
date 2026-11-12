## lingua: a prototype of localization for nimib pages, in about 300 lines of Nim.
##
## The page is written in one language (the source) and stays plain nimib: `nbText` is not
## changed. Its text is cut into chunks (a paragraph, a heading, a list), and each chunk is a
## message of a gettext catalog beside the page (`it.po`), which any PO editor or service
## reads. At render time each chunk is shown in every language, and a switch in the header picks
## one; or the page is written once per language (`nbSaveEach`). Code that must run once per
## language (a table in the reader's locale) goes in `nbEach`, where `lang` is that language.
##
##   nb.useLingua(["en", "it"], ["English", "Italiano"])  # after nbInit: languages, source first
##   nbText "..."                     # unchanged: its chunks are messages of the catalogs
##   tr"Contents"                     # a message from code (labels, cells of a table)
##   nbEach: body                     # body runs once per language; `lang` is the language
##   nb.localized(md), nb.localizedInline(md)   # for custom blocks: one element per language
##   nbSaveLingua                     # render, update the catalogs, write the page
##   nbSaveEach                       # or: one file per language (index.html, index.it.html)
##
## nimib renders with `noSideEffect` functions; lingua keeps its state in one global (`l10n`),
## so the functions that read it during rendering say so with `{.cast(noSideEffect).}`.
import std/[strutils, tables, sets, os, json, strformat]
import nimib except md
import nimib/themes

type
  Entry* = object
    msgid*, msgstr*: string
    comments*: seq[string]     ## translator comments: "machine" marks a translation not yet reviewed
  Catalog* = object
    header*: string            ## the msgstr of the entry with an empty msgid
    entries*: OrderedTable[string, Entry]
    obsolete*: seq[Entry]      ## entries no chunk uses any more, kept as `#~` for reference
  Stats* = object
    lang*: string
    total*, translated*, machine*, missing*: int
  Lingua* = object
    source*: string            ## the language the page is written in
    langs*: seq[string]        ## every language, the source first
    names*: seq[string]        ## how each language calls itself
    dir*: string               ## where the catalogs are: <dir>/<lang>.po
    catalogs*: Table[string, Catalog]
    current*: string           ## the language code runs in (`lang`): the source, or nbEach's
    rendering*: string         ## "" while rendering every language, else the one being written
    seen*: OrderedSet[string]  ## every message met, in the order of the page
    stats*: seq[Stats]

var l10n*: Lingua
  ## The state of the page's localization: its languages, catalogs, and what is being written.

template lang*: string = l10n.current
  ## The language code is running in: the source language, or each language in turn in `nbEach`.

# ------------------------------------------------------------------------------- gettext catalogs

func poString(s: string): string =
  ## A PO string: quoted and escaped, one line per line of text.
  func q(s: string): string = "\"" & s.multiReplace(("\\", "\\\\"), ("\"", "\\\""), ("\t", "\\t"), ("\n", "\\n")) & "\""
  if '\n' notin s: return q(s)
  result = "\"\""
  let lines = s.split('\n')
  for i, line in lines:
    if i < lines.high: result.add "\n" & q(line & "\n")
    elif line.len > 0: result.add "\n" & q(line)

func unquote(s: string): string =
  let s = s.strip
  if s.len < 2 or s[0] != '"' or s[^1] != '"': return ""
  var i = 1
  while i < s.len - 1:
    if s[i] == '\\' and i + 1 < s.len - 1:
      inc i
      result.add(case s[i]
                 of 'n': '\n'
                 of 't': '\t'
                 else: s[i])
    else: result.add s[i]
    inc i

proc readPo*(path: string): Catalog =
  ## A gettext catalog: entries of `msgid` and `msgstr`, translator comments (`# `) and obsolete
  ## entries (`#~`). Plural forms and contexts are not read: lingua does not write them.
  if not fileExists(path): return
  var e: Entry
  var field = ""
  var obsolete = false
  proc flush(c: var Catalog) =
    if field.len > 0:
      if e.msgid.len == 0: c.header = e.msgstr
      elif obsolete: c.obsolete.add e
      else: c.entries[e.msgid] = e
    e = Entry(); field = ""; obsolete = false
  for raw in readFile(path).splitLines:
    var line = raw
    if line.startsWith("#~"):
      if field == "msgstr" and not obsolete: flush(result)
      obsolete = true
      line = line[2 .. ^1].strip(trailing = false)
    elif line.startsWith("# ") or line == "#":
      if field == "msgstr": flush(result)
      e.comments.add line.substr(2)
      continue
    elif line.startsWith("#"): continue
    if line.startsWith("msgid "):
      if field == "msgstr": flush(result)
      field = "msgid"; e.msgid = unquote(line[6 .. ^1])
    elif line.startsWith("msgstr "):
      field = "msgstr"; e.msgstr = unquote(line[7 .. ^1])
    elif line.startsWith("\""):
      if field == "msgid": e.msgid.add unquote(line) else: e.msgstr.add unquote(line)
    elif line.strip.len == 0 and field == "msgstr": flush(result)
  flush(result)

proc writePo*(c: Catalog, path, lang: string) =
  var s = "msgid \"\"\nmsgstr " & poString(if c.header.len > 0: c.header else:
    &"Language: {lang}\nMIME-Version: 1.0\nContent-Type: text/plain; charset=UTF-8\nContent-Transfer-Encoding: 8bit\n") & "\n"
  for e in c.entries.values:
    s.add "\n"
    for com in e.comments: s.add "# " & com & "\n"
    s.add "msgid " & poString(e.msgid) & "\nmsgstr " & poString(e.msgstr) & "\n"
  for e in c.obsolete:
    s.add "\n"
    for com in e.comments: s.add "# " & com & "\n"
    for line in ("msgid " & poString(e.msgid) & "\nmsgstr " & poString(e.msgstr)).splitLines:
      s.add "#~ " & line & "\n"
  writeFile(path, s)

# ------------------------------------------------------------------------------------ the chunks

func chunks*(md: string): seq[string] =
  ## The messages of a text: its paragraphs, headings and lists, cut at blank lines; a fenced
  ## block of code stays whole, blank lines included.
  var cur: seq[string]
  var fence = false
  for line in md.strip.splitLines:
    if line.strip.startsWith("```"): fence = not fence
    if line.strip.len == 0 and not fence:
      if cur.len > 0: result.add cur.join("\n")
      cur = @[]
    else: cur.add line
  if cur.len > 0: result.add cur.join("\n")

func translatable*(chunk: string): bool =
  ## A chunk that is only a block of code is the same in every language.
  not (chunk.startsWith("```") and chunk.endsWith("```"))

func slug*(heading: string): string =
  ## The id of a heading, from its text in the source language, so a link works in every language.
  for c in heading.toLowerAscii:
    if c in {'a'..'z', '0'..'9'}: result.add c
    elif result.len > 0 and result[^1] != '-': result.add '-'
  result = result.strip(chars = {'-'})

proc lookup*(msg, l: string): tuple[text: string, found, machine: bool] =
  ## The message in language `l`: its translation, or the message itself when there is none.
  if l == l10n.source: return (msg, true, false)
  let c = l10n.catalogs.getOrDefault(l)
  if msg in c.entries and c.entries[msg].msgstr.len > 0:
    let e = c.entries[msg]
    return (e.msgstr, true, "machine" in e.comments)
  (msg, false, false)

proc tr*(msg: string): string =
  ## A message from code, in the language code is running in (`lang`). Use `%` for values:
  ## `tr("$1 islands") % [$n]`, so the translation can move them.
  l10n.seen.incl msg
  lookup(msg, l10n.current).text

# ------------------------------------------------------------------------------------- rendering

func renderingLangs(): seq[string] =
  {.cast(noSideEffect).}:
    if l10n.rendering.len > 0: @[l10n.rendering] else: l10n.langs

func headingHtml(html, id, up: string): string =
  ## A heading of level 2 gets the id of its source text and a link back to the contents.
  if html.startsWith("<h2>"):
    &"""<h2 id="{id}">""" & html[4 .. ^1].strip.replace("</h2>",
      &""" <a class="up" href="#contents" aria-label="{up}">↑</a></h2>""")
  else: html

func variant(l, html: string, found: bool, wrap: bool, tag = "div"): string =
  if not wrap: return html
  if found: &"""<{tag} data-l="{l}" lang="{l}">{html}</{tag}>"""
  else:
    {.cast(noSideEffect).}:
      &"""<{tag} data-l="{l}" lang="{l10n.source}" class="l10n-missing">{html}</{tag}>"""

func localizedChunk(chunk: string): string =
  {.cast(noSideEffect).}:
    l10n.seen.incl chunk
    let langs = renderingLangs()
    let id = if chunk.startsWith("## "): slug(chunk[3 .. ^1]) else: ""
    if id.len > 0: l10n.seen.incl "Back to the contents"
    for l in langs:
      let (text, found, _) = lookup(chunk, l)
      var html = markdownToHtml(text).strip
      if id.len > 0: html = headingHtml(html, id, lookup("Back to the contents", l).text)
      result.add variant(l, html, found, langs.len > 1)

func localized*(nb: Nb, md: string): string =
  ## Markdown, in every language being rendered: one element per language and chunk.
  ## A chunk with no translation shows the source, marked `l10n-missing`.
  for c in chunks(md):
    result.add(if translatable(c): localizedChunk(c) else: markdownToHtml(c).strip)
    result.add "\n"

func localizedInline*(nb: Nb, md: string): string =
  ## A short text (a title, a label) with no paragraph around it, one `span` per language.
  {.cast(noSideEffect).}:
    let md = md.strip
    l10n.seen.incl md
    let langs = renderingLangs()
    for l in langs:
      let (text, found, _) = lookup(md, l)
      let html = markdownToHtml(text).strip.replace("<p>", "").replace("</p>", "")
      result.add variant(l, html, found, langs.len > 1, "span")

func linguaText(blk: JsonNode, nb: Nb): string = nb.localized(blk{"text"}.getStr)

func linguaDoc(blk: NbBlock, nb: Nb): string =
  ## nimib's page, with the language in `<html lang>` (nimib writes "en-us").
  {.cast(noSideEffect).}:
    let l = if l10n.rendering.len > 0: l10n.rendering else: l10n.source
  let docJson = %[]
  "<!DOCTYPE html>\n" & &"""<html lang="{l}">""" & "\n" & nb.renderPartial("head", docJson) & "\n<body>\n" &
    nb.renderPartial("header", docJson) & "\n" & nb.renderPartial("left", docJson) & "\n" & mainToHtml(blk, nb) &
    "\n" & nb.renderPartial("right", docJson) & "\n" & nb.renderPartial("footer", docJson) & "\n</body>\n</html>"

func switchCss(langs: seq[string]): string =
  ## Only the chosen language shows: the source, until a reader picks another.
  result = &"""html:not([data-lang]) [data-l]:not([data-l="{langs[0]}"])"""
  for l in langs: result.add &""", html[data-lang="{l}"] [data-l]:not([data-l="{l}"])"""
  result.add " { display: none !important; }\n"

func switchHtml*(nb: Nb): string =
  ## The buttons that pick the language, and the script that remembers the choice (`?lang=it` in
  ## the address picks it too). Without JavaScript the page is in the source language.
  {.cast(noSideEffect).}:
    if l10n.rendering.len > 0 or l10n.langs.len < 2: return ""
    result = """<div class="langs" role="group" aria-label="Language">"""
    for i, l in l10n.langs:
      result.add &"""<button type="button" data-pick="{l}" lang="{l}" aria-pressed="{i == 0}">{l10n.names[i]}</button>"""
    result.add "</div>"

const switchJs = """
<script>
(function () {
  var root = document.documentElement, key = 'nimib-lang';
  function pick(l) {
    root.setAttribute('data-lang', l); root.lang = l;
    document.querySelectorAll('[data-pick]').forEach(function (b) {
      b.setAttribute('aria-pressed', b.getAttribute('data-pick') === l ? 'true' : 'false');
    });
    try { localStorage.setItem(key, l); } catch (e) {}
  }
  var wanted = new URLSearchParams(location.search).get('lang');
  if (!wanted) { try { wanted = localStorage.getItem(key); } catch (e) {} }
  document.addEventListener('DOMContentLoaded', function () {
    if (wanted && document.querySelector('[data-pick="' + wanted + '"]')) pick(wanted);
    document.querySelectorAll('[data-pick]').forEach(function (b) {
      b.addEventListener('click', function () { pick(b.getAttribute('data-pick')); });
    });
  });
})();
</script>
"""

proc useLingua*(nb: var Nb, langs, names: openArray[string], dir = "") =
  ## Localize this page: `langs` are its languages, the source first, `names` how each calls
  ## itself; the catalogs are `<dir>/<lang>.po` (default: beside the page). Call after the page's
  ## theme, since it adds to the head and replaces how text blocks are drawn.
  l10n = Lingua(source: langs[0], langs: @langs, names: @names, current: langs[0],
                  dir: if dir.len > 0: dir else: nb.doc.thisFile.string.parentDir)
  for l in langs[1 .. ^1]: l10n.catalogs[l] = readPo(l10n.dir / l & ".po")
  nb.backend.partials["nbText"] = linguaText
  nb.backend.funcs["NbDoc"] = linguaDoc
  nb.doc.context["stylesheet"] = %(nb.doc.context{"stylesheet"}.getStr & "\n<style>\n" & switchCss(@langs) &
    "</style>\n" & switchJs)

# ------------------------------------------------------------------------------- once per language

newNbBlock(NbLangPart of NbContainer):
  lang: string
  toHtml:
    nbContainerToHtml(blk, nb)

newNbBlock(NbEach of NbContainer):
  toHtml:
    {.cast(noSideEffect).}:
      let all = l10n.rendering.len == 0
      for part in blk.blocks:
        let l = part.NbLangPart.lang
        if not all and l != l10n.rendering: continue
        l10n.rendering = l
        let html = nbContainerToHtml(part, nb)
        result.add(if all: &"""<div data-l="{l}" lang="{l}">{html}</div>""" & "\n" else: html)
      if all: l10n.rendering = ""

template nbEach*(body: untyped) =
  ## `body` runs once per language, with `lang` set to it; the blocks it adds are shown in their
  ## language. For what the code computes in the reader's language: numbers, dates, a table.
  block:
    let each = newNbEach()
    for l in l10n.langs:
      l10n.current = l
      let part = newNbLangPart(lang = l)
      nb.withContainer(part):
        body
      each.blocks.add part
    l10n.current = l10n.source
    nb.add each

# ----------------------------------------------------------------------------------------- saving

proc countStats*(nb: Nb) =
  ## How much of the page each language has: chunks translated, by a machine and not reviewed, missing.
  l10n.stats = @[]
  for l in l10n.langs[1 .. ^1]:
    var s = Stats(lang: l)
    for msg in l10n.seen:
      inc s.total
      let (_, found, machine) = lookup(msg, l)
      if found: inc s.translated
      else: inc s.missing
      if machine: inc s.machine
    l10n.stats.add s

proc updateCatalogs*() =
  ## Each catalog gets every message of the page, in its order: a new one with an empty
  ## translation, one no longer used moved to the obsolete entries at the end (as msgmerge does).
  for l in l10n.langs[1 .. ^1]:
    let old = l10n.catalogs.getOrDefault(l)
    var c = Catalog(header: old.header, obsolete: old.obsolete)
    for msg in l10n.seen:
      c.entries[msg] = if msg in old.entries: old.entries[msg] else: Entry(msgid: msg)
    for msg, e in old.entries:
      if msg notin l10n.seen and e.msgstr.len > 0: c.obsolete.add e
    c.writePo(l10n.dir / l & ".po", l)
    l10n.catalogs[l] = c

template nbSaveLingua* =
  ## Render once to meet every message (`tr` met its own when the code ran), count, update
  ## the catalogs, then write the page.
  discard nb.render(nb.doc)
  nb.countStats
  updateCatalogs()
  nbSave

template nbSaveEach* =
  ## One file per language: the page's file for the source, `index.it.html` beside it for Italian.
  discard nb.render(nb.doc)
  nb.countStats
  updateCatalogs()
  let base = nb.doc.filename
  for l in l10n.langs:
    l10n.rendering = l
    nb.doc.filename = if l == l10n.source: base else: base.changeFileExt(l & ".html")
    nbSave
  l10n.rendering = ""
  nb.doc.filename = base
