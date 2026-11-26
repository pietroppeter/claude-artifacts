## The custom blocks of the faretto explainer. Classes only: every style is in style.nim.
import std/[sequtils, strformat, strutils]
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
  nkNim = "nim"           ## about Nim and Nimony
  nkPharo = "pharo"       ## how Pharo does it

func noteLabel(k: NoteKind): string =
  case k
  of nkAside: "Aside"
  of nkCareful: "Careful"
  of nkNim: "Nim"
  of nkPharo: "Meanwhile, in Pharo"

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

newNbBlock(NbSteps):
  caption: string
  steps: seq[(string, string, string)]
  toHtml:
    var lis = ""
    for (icon, title, what) in blk.steps:
      lis.add &"""<li><span class="step-icon" aria-hidden="true">{icon}</span><span class="step-title">{esc(title)}</span><span class="step-what">{inlineMd(what)}</span></li>"""
    &"""<figure class="steps"><ol>{lis}</ol><figcaption>{inlineMd(blk.caption)}</figcaption></figure>"""

template nbSteps*(tcaption: string; tsteps: openArray[(string, string, string)]) =
  ## A row of steps (icon, title, Markdown), read left to right, like the lights along a coast.
  nb.add newNbSteps(caption = tcaption, steps = @tsteps)

newNbBlock(NbTerm):
  title: string
  text: string
  toHtml:
    &"""<figure class="term"><figcaption>{esc(blk.title)}</figcaption><pre class="nb-output">{esc(blk.text)}</pre></figure>"""

template nbTerm*(ttitle, ttext: string) =
  ## A shell session: commands and what they printed, captured when the page was built.
  nb.add newNbTerm(title = ttitle, text = ttext)

newNbBlock(NbPlayground):
  variants: seq[(string, string, string)]   ## (label, highlighted source html, NIF of the proc)
  image: string                             ## the boot image, NIF
  js: string                                ## the compiled playground (nim js)
  toHtml:
    var chips, sources, nifs = ""
    for i, (label, html, nif) in blk.variants:
      let pressed = if i == 0: "true" else: "false"
      chips.add &"""<button type="button" class="pg-chip" data-v="{i}" aria-pressed="{pressed}">{esc(label)}</button>"""
      let hidden = if i == 0: "" else: " hidden"
      sources.add &"""<pre class="pg-src" data-v="{i}"{hidden}><code class="hljs nim">{html}</code></pre>"""
      nifs.add &"""<script type="text/plain" class="pg-nif" data-v="{i}">{nif}</script>"""
    &"""<section class="playground" id="faro" aria-label="faretto, running in this page">
<div class="pg-stage">
<svg class="pg-svg" viewBox="0 0 320 210" role="img" aria-label="a lighthouse; its light follows the proc lit">
  <defs><linearGradient id="pg-sea" x1="0" y1="0" x2="0" y2="1"><stop offset="0" class="sea-top"/><stop offset="1" class="sea-bottom"/></linearGradient>
  <linearGradient id="pg-beamL" x1="1" y1="0" x2="0" y2="0"><stop offset="0" class="beam-in"/><stop offset="1" class="beam-out"/></linearGradient>
  <linearGradient id="pg-beamR" x1="0" y1="0" x2="1" y2="0"><stop offset="0" class="beam-in"/><stop offset="1" class="beam-out"/></linearGradient></defs>
  <circle class="pg-star" cx="40" cy="30" r="1.2"/><circle class="pg-star" cx="90" cy="18" r="1"/><circle class="pg-star" cx="250" cy="26" r="1.3"/><circle class="pg-star" cx="292" cy="58" r="1"/><circle class="pg-star" cx="205" cy="12" r=".9"/>
  <g id="pg-beams" class="pg-beams" opacity="0">
    <polygon points="160,62 0,30 0,102" fill="url(#pg-beamL)"/>
    <polygon points="160,62 320,30 320,102" fill="url(#pg-beamR)"/>
  </g>
  <rect x="0" y="168" width="320" height="42" fill="url(#pg-sea)"/>
  <path class="pg-rock" d="M118 172 Q130 150 160 152 Q192 150 204 172 Z"/>
  <path class="pg-tower" d="M146 156 L150 78 L170 78 L174 156 Z"/>
  <path class="pg-band" d="M148.6 132 L171.4 132 L172.3 148 L147.7 148 Z"/>
  <path class="pg-band" d="M149.9 100 L170.1 100 L170.8 116 L149.2 116 Z"/>
  <rect class="pg-gallery" x="144" y="74" width="32" height="5" rx="1"/>
  <rect class="pg-room" x="150" y="56" width="20" height="18" rx="2"/>
  <circle id="pg-lamp" class="pg-lamp" cx="160" cy="65" r="5.5"/>
  <path class="pg-roof" d="M147 57 L160 44 L173 57 Z"/>
  <path class="pg-wave" d="M0 182 q10 -4 20 0 t20 0 t20 0 t20 0 t20 0 t20 0 t20 0 t20 0 t20 0 t20 0 t20 0 t20 0 t20 0 t20 0 t20 0 t20 0"/>
</svg>
<div class="pg-strip" id="pg-strip" aria-label="the last seconds, as tick returned them"></div>
<p class="pg-report" id="pg-report" aria-live="polite"></p>
</div>
<div class="pg-row">
  <button type="button" id="pg-play" class="pg-btn">⏸ Pause</button>
  <button type="button" id="pg-snap" class="pg-btn">📸 Snapshot</button>
  <button type="button" id="pg-restore" class="pg-btn" disabled>⟲ Restore</button>
</div>
<p class="pg-label">Accept a new <code>lit</code>, while it runs:</p>
<div class="pg-chips" role="group" aria-label="versions of lit">{chips}</div>
{sources}
<div class="pg-row">
  <button type="button" id="pg-become" class="pg-btn">⇄ <code>become</code>: swap the lamps</button>
  <button type="button" id="pg-link" class="pg-btn" aria-pressed="false">🔗 MetaLink: count flashes</button>
</div>
<p class="pg-label">Inspector: <code>capo</code> and <code>spare</code>, live</p>
<pre class="pg-insp nb-output" id="pg-insp"></pre>
<p class="pg-label">Change log</p>
<ol class="pg-log" id="pg-log"></ol>
<script type="text/plain" id="pg-image">{blk.image}</script>
{nifs}
<script>{blk.js}</script>
</section>"""

template nbPlayground*(tvariants: seq[(string, string, string)]; timage, tjs: string) =
  ## faretto itself, compiled to JavaScript, running the image of this page in the browser.
  nb.add newNbPlayground(variants = tvariants, image = timage, js = tjs)
