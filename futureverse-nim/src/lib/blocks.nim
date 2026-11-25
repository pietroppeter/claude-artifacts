## The custom blocks of the futureverse explainer. Classes only: every style is in style.nim.
import std/[os, osproc, sequtils, strformat, strutils]
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

newNbBlock(NbPrompt):
  who: string
  date: string
  text: string     ## Markdown
  toHtml:
    &"""<figure class="prompt"><figcaption><span class="prompt-who">{esc(blk.who)}</span> asked Claude, {esc(blk.date)}</figcaption><blockquote>{markdownToHtml(blk.text)}</blockquote></figure>"""

template nbPrompt*(twho, tdate, ttext: string) =
  ## The request that started the page, as a chat bubble, verbatim.
  nb.add newNbPrompt(who = twho, date = tdate, text = ttext)

type NoteKind* = enum
  nkAside = "aside"       ## a remark
  nkCareful = "careful"   ## a caveat, a rough edge
  nkNim = "nim"           ## about Nim itself
  nkR = "r"               ## how R does it

func noteLabel(k: NoteKind): string =
  case k
  of nkAside: "Aside"
  of nkCareful: "Careful"
  of nkNim: "Nim"
  of nkR: "Meanwhile, in R"

newNbBlock(NbNote):
  level: NoteKind
  text: string
  toHtml:
    &"""<aside class="note {blk.level}"><span class="note-label">{noteLabel(blk.level)}</span>{markdownToHtml(blk.text)}</aside>"""

template nbNote*(tkind: NoteKind, ttext: string) =
  ## A labelled aside: `nbNote(nkCareful, "...")`.
  nb.add newNbNote(level = tkind, text = ttext)

newNbBlock(NbSource):
  path: string
  code: string
  open: bool
  anchor: string
  toHtml:
    let o = (if blk.open: " open" else: "") & (if blk.anchor.len > 0: &" id=\"{blk.anchor}\"" else: "")
    let n = blk.code.strip.countLines
    &"""<details class="source"{o}><summary><code>{esc(blk.path)}</code> <span class="src-lines">{n} lines</span></summary><pre><code class="hljs nim">{highlightNim(blk.code.strip)}</code></pre></details>"""

template nbSource*(tpath: string; topen = false; tanchor = "") =
  ## A whole source file of the PoC, folded (it is the same file that runs below); `tanchor`
  ## gives it an id to link to.
  nb.add newNbSource(path = tpath, code = readFile(tpath), open = topen, anchor = tanchor)

newNbBlock(NbCompileError):
  code: string
  output: string
  fold: string     ## when set, the snippet and its error are folded under this Markdown summary
  toHtml:
    let inner = &"""<pre><code class="hljs nim">{highlightNim(blk.code.strip)}</code></pre><pre class="nb-output err">{esc(blk.output)}</pre>"""
    if blk.fold.len == 0: inner
    else: &"""<details class="fold"><summary>{inlineMd(blk.fold)}</summary>{inner}</details>"""

template nbCompileError*(tcode: string; tmax = 1; tlines = 4; tfold = ""; targs = ""; tcmd = "check") =
  ## Code that must not compile: it is compiled now, with the Nim on the PATH, and the
  ## compiler's first `tmax` errors (each with up to `tlines` lines) are shown under it.
  ## The build fails if the snippet compiles.
  block:
    let dir = getTempDir() / "fv-errors"
    createDir dir
    let f = dir / "snippet.nim"
    writeFile(f, tcode.strip & "\n")
    let (o, code) = execCmdEx("nim " & tcmd & " --hints:off --colors:off " & targs & " " & quoteShell(f))
    doAssert code != 0, "this snippet was meant not to compile:\n" & tcode
    var errs: seq[string]
    var n, taken = 0
    for line in o.replace(f, "snippet.nim").splitLines:
      if "Error:" in line:
        inc n
        taken = 0
      if n == 0 or n > tmax or line.strip.len == 0 or taken >= tlines: continue
      if errs.len > 0 and line in errs: continue
      errs.add line
      inc taken
    nb.add newNbCompileError(code = tcode, output = errs.join("\n"), fold = tfold)

proc pick*(path: string; starts: openArray[string]): string =
  ## The definitions of `path` whose first line starts with one of `starts` (after the indent),
  ## each with the lines indented under it: `pick("apps/dice.nim", ["proc update*"])`.
  ## A type found inside a `type` section gets its own `type` line.
  let lines = readFile(path).splitLines
  var parts: seq[string]
  for st in starts:
    var i = 0
    while i < lines.len and not lines[i].strip(trailing = false).startsWith(st): inc i
    doAssert i < lines.len, path & ": no line starts with " & st
    let ind = lines[i].len - lines[i].strip(trailing = false).len
    var part = @[lines[i][ind .. ^1]]
    var j = i + 1
    while j < lines.len and (lines[j].strip.len == 0 or lines[j].len - lines[j].strip(trailing = false).len > ind):
      part.add(if lines[j].len >= ind: lines[j][ind .. ^1] else: "")
      inc j
    while part[^1].strip.len == 0: part.setLen(part.len - 1)
    if ind > 0: part = @["type"] & part.mapIt("  " & it)
    parts.add part.join("\n")
  parts.join("\n\n")

proc lineCount*(path: string): int =
  ## Lines that are not blank, of one source file.
  for l in readFile(path).splitLines:
    if l.strip.len > 0: inc result

newNbBlock(NbSnippet):
  path: string
  code: string
  toHtml:
    &"""<figure class="snippet"><figcaption>from <code>{esc(blk.path)}</code></figcaption><pre><code class="hljs nim">{highlightNim(blk.code)}</code></pre></figure>"""

template nbSnippet*(tpath: string; tstarts: openArray[string]) =
  ## Some definitions of a source file of the PoC, shown open, read from the file itself.
  nb.add newNbSnippet(path = tpath, code = pick(tpath, tstarts))

newNbBlock(NbFold):
  summary: string
  text: string
  toHtml:
    &"""<details class="fold"><summary>{inlineMd(blk.summary)}</summary>{markdownToHtml(blk.text)}</details>"""

template nbFold*(tsummary, ttext: string) =
  ## Markdown that is folded under a summary: details a reader can skip.
  nb.add newNbFold(summary = tsummary, text = ttext)

newNbBlock(NbShowText):
  text: string
  toHtml:
    &"""<pre class="nb-output">{esc(blk.text)}</pre>"""

template nbShowText*(ttext: string) =
  ## A text shown as an output, escaped: for an HTML string, as a string.
  nb.add newNbShowText(text = ttext)

type Step* = tuple[icon, title, what: string]   ## what: Markdown

newNbBlock(NbSteps):
  caption: string
  steps: seq[Step]
  toHtml:
    var s = """<figure class="steps"><ol>"""
    for st in blk.steps:
      s.add &"""<li><span class="step-icon">{esc(st.icon)}</span><span class="step-title">{inlineMd(st.title)}</span><span class="step-what">{inlineMd(st.what)}</span></li>"""
    s & &"""</ol><figcaption>{inlineMd(blk.caption)}</figcaption></figure>"""

template nbSteps*(tcaption: string; tsteps: seq[Step]) =
  ## A strip of steps, left to right on a wide screen and top to bottom on a phone.
  nb.add newNbSteps(caption = tcaption, steps = tsteps)

newNbBlock(NbR):
  code: string
  output: string
  toHtml:
    let o = if blk.output.len > 0: &"""<pre class="nb-output">{esc(blk.output)}</pre>""" else: ""
    &"""<figure class="rcode"><figcaption>R</figcaption><pre><code class="language-r">{esc(blk.code.strip)}</code></pre>{o}</figure>"""

template nbR*(tcode: string; toutput = "") =
  ## R code, shown and not run (there is no R here); `toutput` is the output the paper or the
  ## futureverse docs print for it. Highlighted after the build by tools/codeblocks.py.
  nb.add newNbR(code = tcode, output = toutput)
