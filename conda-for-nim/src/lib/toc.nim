## The table of contents: after nbSave, `addToc` gives every `<h2>` and `<h3>` of the page an id
## and a small "↑ Contents" link back, and puts the list of them where `nbTocHere` was called.
import std/[strutils, strformat]
import nimib

const marker = "<!-- conda-for-nim:toc -->"

template nbTocHere* =
  ## Where the contents go (filled in by `addToc` once the page is written).
  nbRawHtml marker

func plain(html: string): string =
  ## The text of a heading: tags dropped, entities left as they are.
  var inTag = false
  for c in html:
    if c == '<': inTag = true
    elif c == '>': inTag = false
    elif not inTag: result.add c

func slug(text: string): string =
  for c in text.toLowerAscii:
    if c in {'a'..'z', '0'..'9'}: result.add c
    elif result.len > 0 and result[^1] != '-': result.add '-'
  result = result.strip(chars = {'-'})

proc addToc*(path: string) =
  var html = readFile(path)
  let at = html.find(marker)
  doAssert at >= 0, "nbTocHere was not called"
  var items = ""
  var inSub = false
  var i = at
  while true:
    # only headings that nimib's markdown wrote, at the start of a line (not strings in scripts)
    let h2 = html.find("\n<h2>", i)
    let h3 = html.find("\n<h3>", i)
    if h2 < 0 and h3 < 0: break
    let (pos, level) = if h3 < 0 or (h2 >= 0 and h2 < h3): (h2, 2) else: (h3, 3)
    let close = html.find(&"</h{level}>", pos)
    let inner = html[pos + 5 ..< close]
    var id = slug(plain(inner))
    if html.find(&"id=\"{id}\"") >= 0: id.add "-" & $level
    let heading = &"""
<h{level} id="{id}">{inner} <a class="toc-up" href="#contents">↑ Contents</a></h{level}>"""
    html = html[0 ..< pos] & heading & html[close + 5 .. ^1]
    i = pos + heading.len
    if level == 2:
      if inSub: items.add "</ol></li>"; inSub = false
      elif items.len > 0: items.add "</li>"
      items.add &"""<li><a href="#{id}">{inner}</a>"""
    else:
      if not inSub: items.add "<ol>"; inSub = true
      items.add &"""<li><a href="#{id}">{inner}</a></li>"""
  if inSub: items.add "</ol>"
  if items.len > 0: items.add "</li>"
  let toc = &"""<nav class="toc" id="contents" aria-label="Contents"><span class="toc-label">Contents</span><ol>{items}</ol></nav>"""
  writeFile(path, html.replace(marker, toc))
