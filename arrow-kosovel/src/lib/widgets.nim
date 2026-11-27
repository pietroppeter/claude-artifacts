## The layout explorer: a Kosovel poem as an Arrow column, byte by byte, in your browser.
## Nim compiled to JavaScript (`nim js`, see blocks.compileWidgets); the buffers come from
## layout.nim, the same procs the page used when it was built (and that cdata.nim exports
## to pyarrow). The poems are in `KOSOVEL`, a small array the page puts before this script.
## Also: the theme picker (the illustrators), which only sets `data-theme` on <html>.
import std/[dom, strutils]
import layout

# ------------------------------------------------------------------ a little DOM interop
proc poemCount(): int {.importjs: "KOSOVEL.length@".}
proc poemTitle(p: int): cstring {.importjs: "KOSOVEL[#].t".}
proc poemColl(p: int): cstring {.importjs: "KOSOVEL[#].c".}
proc lineCount(p: int): int {.importjs: "KOSOVEL[#].l.length".}
proc lineAt(p, i: int): cstring {.importjs: "KOSOVEL[#].l[#]".}
proc wordCount(p: int): int {.importjs: "KOSOVEL[#].w.length".}
proc wordAt(p, i: int): cstring {.importjs: "KOSOVEL[#].w[#]".}
proc transLine(p: int; lang: cstring; i: int): cstring {.importjs: "(KOSOVEL[#][#] || [])[#] || ''".}
proc wordLine(p, i: int): int {.importjs: "KOSOVEL[#].wl[#]".}
proc setHtml(e: Element; s: cstring) {.importjs: "#.innerHTML = #".}
proc valueI(e: Element): int {.importjs: "parseInt(#.value)".}
proc setValueI(e: Element; v: int) {.importjs: "#.value = #".}
proc setMax(e: Element; v: int) {.importjs: "#.max = #".}
proc rowOf(e: Element): cstring {.importjs: "((#.closest('[data-row]') || {dataset: {}}).dataset.row || '')".}
proc lineOf(e: Element): cstring {.importjs: "((#.closest('[data-line]') || {dataset: {}}).dataset.line || '')".}
proc targetEl(ev: Event): Element {.importjs: "#.target".}
proc setPressed(e: Element; on: bool) {.importjs: "#.setAttribute('aria-pressed', # ? 'true' : 'false')".}
proc setTheme(t: cstring) {.importjs: "document.documentElement.dataset.theme = #".}
proc savedTheme(): cstring {.importjs: "(function(){try{return localStorage.getItem('puscica-theme')||''}catch(e){return ''}})()@".}
proc saveTheme(t: cstring) {.importjs: "(function(t){try{localStorage.setItem('puscica-theme', t)}catch(e){}})(#)".}
proc byId(id: string): Element = document.getElementById(cstring(id))

proc esc(s: string): string =
  s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))

# ------------------------------------------------------------------ state
type Column = enum colLines = "lines", colWords = "words"

var
  poem = 0
  column = colLines
  enc = encUtf8
  sel = 0                 ## the selected row
  sliceFrom = 0
  sliceLen = 0            ## 0 = the whole column
  hexMode = false
  lang = "en"             ## the translation shown beside the poem: "sl" (none), "en" or "it"

proc values(): (seq[string], seq[bool]) =
  ## The column: the poem's lines (a blank line between stanzas is a null) or its words.
  var vs: seq[string]
  var ok: seq[bool]
  if column == colLines:
    for i in 0 ..< lineCount(poem):
      let l = $lineAt(poem, i)
      vs.add l
      ok.add l.strip.len > 0
  else:
    for i in 0 ..< wordCount(poem):
      vs.add $wordAt(poem, i)
      ok.add true
  (vs, ok)

proc inSlice(i, n: int): bool =
  let hi = if sliceLen == 0: n else: min(n, sliceFrom + sliceLen)
  i >= sliceFrom and i < hi

# ------------------------------------------------------------------ drawing the buffers

proc utf8Len(b: int): int =
  if b < 0x80: 1 elif b shr 5 == 0b110: 2 elif b shr 4 == 0b1110: 3 elif b shr 3 == 0b11110: 4 else: 0

proc le32(b: seq[int]; at: int): int =
  for k in 0..3: result = result or (b[at + k] shl (8 * k))

proc cellClass(owner, selected: int; live: bool): string =
  result = "cell"
  if owner == selected and selected >= 0: result.add " sel"
  elif owner == -2: result.add " pad"
  if not live: result.add " dim"

proc drawBuf(b: Buf; selected: int; live: proc (owner: int): bool; isValidity: bool; n: int): string =
  ## One buffer as a row of cells. Ints (offsets, indices, run ends) are shown as numbers,
  ## data as text (one character over its 1 to 4 UTF-8 bytes), views as their four parts.
  result = "<div class=\"buf\"><div class=\"buf-h\"><b>" & esc(b.name) & "</b> <span>" &
    $b.bytes.len & " bytes</span></div><div class=\"cells\">"
  if b.bytes.len == 0:
    result.add "<span class=\"empty\">" & (if isValidity: "no nulls, so no bitmap at all" else: "empty") & "</span>"
  elif isValidity:
    for i in 0 ..< n:
      let bit = (b.bytes[i div 8] shr (i mod 8)) and 1
      result.add "<span class=\"" & cellClass(i, selected, live(i)) & " bit b" & $bit & "\" data-row=\"" & $i & "\">" & $bit & "</span>"
    let spare = b.bytes.len * 8 - n
    if spare > 0: result.add "<span class=\"cell pad\" title=\"padding bits\">+" & $spare & "</span>"
  elif b.width == 4:
    var i = 0
    while i + 3 < b.bytes.len:
      let o = b.owner[i]
      let v = le32(b.bytes, i)
      let sub = if hexMode: "<small>" & toHex(b.bytes[i], 2).toLowerAscii & " " & toHex(b.bytes[i+1], 2).toLowerAscii & " " &
                  toHex(b.bytes[i+2], 2).toLowerAscii & " " & toHex(b.bytes[i+3], 2).toLowerAscii & "</small>" else: ""
      result.add "<span class=\"" & cellClass(o, selected, live(o)) & " int\"" & (if o >= 0: " data-row=\"" & $o & "\"" else: "") &
        ">" & $v & sub & "</span>"
      i += 4
  elif b.width == 16:
    var i = 0
    while i + 15 < b.bytes.len:
      let o = b.owner[i]
      let ln = le32(b.bytes, i)
      var inner = "<span class=\"vlen\">" & $ln & "</span>"
      if ln <= 12:
        var s = ""
        for k in 0 ..< ln: s.add char(b.bytes[i + 4 + k])
        inner.add "<span class=\"vinl\">" & esc(s) & "</span>"
        if 12 - ln > 0: inner.add "<span class=\"vpad\">" & repeat("·", 12 - ln) & "</span>"
      else:
        var s = ""
        for k in 0 ..< 4: s.add char(b.bytes[i + 4 + k])
        inner.add "<span class=\"vpre\">" & esc(s) & "…</span><span class=\"vref\">buf " & $le32(b.bytes, i + 8) &
          " @" & $le32(b.bytes, i + 12) & "</span>"
      result.add "<span class=\"" & cellClass(o, selected, live(o)) & " view\" data-row=\"" & $o & "\">" & inner & "</span>"
      i += 16
  elif b.width == 8:
    var v = 0
    for k in 0..3: v = v or (b.bytes[k] shl (8 * k))
    result.add "<span class=\"cell int\">" & $v & "</span>"
  else:
    var i = 0
    while i < b.bytes.len:
      let o = b.owner[i]
      let n = max(1, utf8Len(b.bytes[i]))
      var s = ""
      for k in 0 ..< n:
        if i + k < b.bytes.len: s.add char(b.bytes[i + k])
      let shown = if s == " ": "␣" else: esc(s)
      var hx = ""
      for k in 0 ..< n:
        if i + k < b.bytes.len: hx.add toHex(b.bytes[i + k], 2).toLowerAscii & (if k < n - 1: " " else: "")
      let cls = cellClass(o, selected, live(o)) & " ch" & (if n > 1: " mb mb" & $n else: "")
      result.add "<span class=\"" & cls & "\" data-row=\"" & $o & "\">" &
        (if hexMode: "<i>" & shown & "</i><small>" & hx & "</small>" else: shown) & "</span>"
      i += n
  result.add "</div></div>"

proc drawLayout(l: Layout; title: string; selected: int; live: proc (owner: int): bool; n: int): string =
  result = "<div class=\"lay\"><div class=\"lay-h\">" & esc(title) & " <code>" & esc(l.format) & "</code></div>"
  for k, b in l.buffers:
    result.add drawBuf(b, selected, live, k == 0 and b.name == "validity", n)
  result.add "</div>"

# ------------------------------------------------------------------ the explorer

proc render() =
  let (vs, ok) = values()
  let n = vs.len
  if sel >= n: sel = 0
  let maxFrom = max(0, n - 1)
  byId("lx-from").setMax maxFrom
  byId("lx-count").setMax n
  if sliceFrom > maxFrom: sliceFrom = maxFrom
  byId("lx-from").setValueI sliceFrom
  byId("lx-count").setValueI sliceLen
  let shownLen = if sliceLen == 0: n - sliceFrom else: min(sliceLen, n - sliceFrom)
  byId("lx-from-v").setHtml cstring($sliceFrom)
  byId("lx-count-v").setHtml cstring(if sliceLen == 0: "all" else: $shownLen)

  # the values, as chips to tap
  var chips = ""
  for i, v in vs:
    let cls = "chip" & (if i == sel: " sel" else: "") & (if not ok[i]: " null" else: "") &
              (if inSlice(i, n): "" else: " dim")
    chips.add "<button type=\"button\" class=\"" & cls & "\" data-row=\"" & $i & "\"><small>" & $i & "</small>" &
      (if ok[i]: esc(v) else: "null") & "</button>"
  byId("lx-values").setHtml cstring(chips)

  let l = layout(enc, vs, ok)
  let live = proc (owner: int): bool = owner < 0 or inSlice(owner, n)
  var html = ""
  case enc
  of encUtf8, encView:
    html = drawLayout(l, "the column", sel, live, n)
  of encDict:
    html = drawLayout(l, "the column: indices", sel, live, n)
    var used: seq[bool] = newSeq[bool](l.children[0].length)
    for i in 0 ..< n:
      if inSlice(i, n): used[l.childIndex[i]] = true
    let liveD = proc (owner: int): bool = owner < 0 or used[owner]
    html.add drawLayout(l.children[0], "its dictionary", l.childIndex[sel], liveD, l.children[0].length)
  of encRunEnd:
    var used: seq[bool] = newSeq[bool](l.children[1].length)
    for i in 0 ..< n:
      if inSlice(i, n): used[l.childIndex[i]] = true
    let liveR = proc (owner: int): bool = owner < 0 or used[owner]
    html = "<div class=\"lay\"><div class=\"lay-h\">the column <code>+r</code>: no buffers of its own, two children</div></div>"
    html.add drawLayout(l.children[0], "run_ends", l.childIndex[sel], liveR, l.children[0].length)
    html.add drawLayout(l.children[1], "values", l.childIndex[sel], liveR, l.children[1].length)
  byId("lx-buffers").setHtml cstring(html)

  # what the selected value is made of, and the sizes of the four encodings
  let v = vs[sel]
  var info = "<b>row " & $sel & "</b>: "
  if not ok[sel]:
    info.add "null: its validity bit is 0, and it takes no data bytes (its two offsets are equal)."
  else:
    var runes = 0
    var multi = 0
    var i = 0
    while i < v.len:
      let k = max(1, utf8Len(ord(v[i])))
      inc runes
      if k > 1: inc multi
      i += k
    info.add "“" & esc(v) & "”, " & $runes & " characters in " & $v.len & " bytes"
    if multi > 0: info.add " (" & $multi & " of them, like č š ž, take 2 or more bytes)"
    info.add ". "
  info.add esc(l.note) & "."
  if sliceFrom > 0 or sliceLen > 0:
    info.add " Slice: <code>offset = " & $sliceFrom & ", length = " & $shownLen & "</code>, same buffers, nothing copied."
  var sizes = "<div class=\"sizes\">"
  var best = high(int)
  var tot: array[Encoding, int]
  for e in Encoding:
    tot[e] = layout(e, vs, ok).totalBytes
    best = min(best, tot[e])
  var worst = 1
  for e in Encoding: worst = max(worst, tot[e])
  for e in Encoding:
    let pct = (100 * tot[e]) div worst
    sizes.add "<div class=\"size" & (if e == enc: " on" else: "") & "\"><span>" & $e & "</span><i style=\"width:" & $pct &
      "%\"></i><b>" & $tot[e] & " B</b></div>"
  sizes.add "</div>"
  byId("lx-out").setHtml cstring(info & sizes)

  # the poem, with the line of the selected value marked, and its translation
  let curLine = if column == colLines: sel else: wordLine(poem, sel)
  var ptxt = ""
  for i in 0 ..< lineCount(poem):
    let orig = $lineAt(poem, i)
    if orig.strip.len == 0:
      ptxt.add "<div class=\"pl gap\"></div>"
      continue
    let tr = if lang == "sl": "" else: $transLine(poem, cstring(lang), i)
    ptxt.add "<div class=\"pl" & (if i == curLine: " sel" else: "") & "\" data-line=\"" & $i & "\"><span>" & esc(orig) & "</span>" &
      (if tr.len > 0: "<i>" & esc(tr) & "</i>" else: "") & "</div>"
  byId("lx-text").setHtml cstring(ptxt)
  for l in ["sl", "en", "it"]: byId("lx-" & l).setPressed(l == lang)

  for e in Encoding: byId("lx-e" & $ord(e)).setPressed(e == enc)
  byId("lx-lines").setPressed(column == colLines)
  byId("lx-words").setPressed(column == colWords)
  byId("lx-hex").setPressed(hexMode)

proc setup() =
  let ps = byId("lx-poem")
  if ps == nil: return
  var opts = ""
  for p in 0 ..< poemCount():
    opts.add "<option value=\"" & $p & "\">" & esc($poemTitle(p)) & " · " & esc($poemColl(p)) & "</option>"
  ps.setHtml cstring(opts)
  ps.addEventListener("change", proc (ev: Event) =
    poem = ps.valueI; sel = 0; sliceFrom = 0; sliceLen = 0; render())
  proc onEnc(e: Encoding) =      # a proc per button: closures in a loop would share one `e`
    byId("lx-e" & $ord(e)).addEventListener("click", proc (ev: Event) = enc = e; render())
  for e in Encoding: onEnc(e)
  byId("lx-lines").addEventListener("click", proc (ev: Event) =
    column = colLines; sel = 0; sliceFrom = 0; sliceLen = 0; render())
  byId("lx-words").addEventListener("click", proc (ev: Event) =
    column = colWords; sel = 0; sliceFrom = 0; sliceLen = 0; render())
  byId("lx-hex").addEventListener("click", proc (ev: Event) = hexMode = not hexMode; render())
  byId("lx-from").addEventListener("input", proc (ev: Event) = sliceFrom = byId("lx-from").valueI; render())
  byId("lx-count").addEventListener("input", proc (ev: Event) = sliceLen = byId("lx-count").valueI; render())
  proc onTap(id: string; rows: bool) =
    byId(id).addEventListener("click", proc (ev: Event) =
      let r = rowOf(targetEl(ev))
      if r.len > 0:
        let k = parseInt($r)
        # in the dictionary and run-end layouts a tap in the buffers names an entry or a run, not a row
        if k >= 0 and (rows or enc in {encUtf8, encView}):
          sel = k
          render())
  proc onLang(l: string) =
    byId("lx-" & l).addEventListener("click", proc (ev: Event) = lang = l; render())
  for l in ["sl", "en", "it"]: onLang(l)
  byId("lx-text").addEventListener("click", proc (ev: Event) =
    let r = lineOf(targetEl(ev))
    if r.len > 0:
      let i = parseInt($r)
      if column == colLines: sel = i
      else:
        for k in 0 ..< wordCount(poem):
          if wordLine(poem, k) == i:
            sel = k
            break
      render())
  onTap("lx-values", true)
  onTap("lx-buffers", false)
  render()

# ------------------------------------------------------------------ the illustrator picker

proc setupThemes() =
  let bar = byId("themes")
  if bar == nil: return
  proc apply(t: string) =
    setTheme(cstring(t))
    saveTheme(cstring(t))
    var i = 0
    while true:
      let b = byId("th-" & $i)
      if b == nil: break
      b.setPressed($b.getAttribute("data-theme") == t)
      inc i
  let saved = $savedTheme()
  apply(if saved.len > 0: saved else: "reichman")
  var i = 0
  proc onTheme(b: Element) =
    let t = $b.getAttribute("data-theme")
    b.addEventListener("click", proc (ev: Event) = apply(t))
  while true:
    let b = byId("th-" & $i)
    if b == nil: break
    onTheme(b)
    inc i

setupThemes()
setup()
