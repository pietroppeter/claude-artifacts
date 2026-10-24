## The in-browser demo: appalette compiled to JS.
##   nim js -d:danger -o:demo/demo.js demo/demo.nim
## The page (demo/page.html) provides the markup and `window.EXAMPLES`
## ([{name, title, author, license, src}]); tools/build_demo.py inlines both.
##
## An image is drawn on a canvas at most 640 px wide; its pixels go through
## `colorSet` and `similarities`, then the preference sweep runs one
## affinity propagation per timer tick, so the page stays responsive and the
## palettes appear as they are found.

import std/[dom, jsffi, math, strutils, strformat, algorithm]
import appalette

# --- a few browser APIs --------------------------------------------------

proc ctx2d(c: Element): JsObject {.importjs: "#.getContext('2d', {willReadFrequently: true})".}
proc drawImage(ctx, img: JsObject; w, h: int) {.importjs: "#.drawImage(#, 0, 0, #, #)".}
proc getImageData(ctx: JsObject; w, h: int): JsObject {.importjs: "#.getImageData(0, 0, #, #)".}
proc createImageData(ctx: JsObject; w, h: int): JsObject {.importjs: "#.createImageData(#, #)".}
proc putImageData(ctx, d: JsObject) {.importjs: "#.putImageData(#, 0, 0)".}
proc pixels(d: JsObject): seq[uint8] {.importjs: "#.data".}
proc setPixels(d: JsObject; p: seq[uint8]) {.importjs: "#.data.set(#)".}
proc newImage(): JsObject {.importjs: "new Image()".}
proc examples(): JsObject {.importjs: "(window.EXAMPLES || [])".}
proc closest(e: JsObject; sel: cstring): JsObject {.importjs: "#.closest(#)".}
proc isNull(o: JsObject): bool {.importjs: "(# == null)".}
proc readAsDataUrl(f: JsObject; cb: proc (url: cstring)) {.importjs:
  "(function(f, cb){ var r = new FileReader(); r.onload = function(){ cb(r.result); }; r.readAsDataURL(f); })(#, #)".}
proc copyText(s: cstring; ok: proc (); fail: proc ()) {.importjs:
  "(function(s, ok, fail){ if (navigator.clipboard) navigator.clipboard.writeText(s).then(ok, fail); else fail(); })(#, #, #)".}
proc nowMs(): float {.importjs: "performance.now()".}

proc byId(id: string): Element = document.getElementById(cstring(id))
proc setHtml(id, html: string) = byId(id).innerHTML = cstring(html)
proc setText(id, text: string) = byId(id).textContent = cstring(text)
proc value(id: string): string = $byId(id).value
proc esc(s: string): string = s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))

# --- state ---------------------------------------------------------------

const maxSide = 640
const kMax = 24
const factor = 0.9

var
  img: JsObject          # the current HTMLImageElement
  imgTitle = ""
  w, h: int
  ctx: JsObject
  source: JsObject       # ImageData of the original
  shown: JsObject        # ImageData shown
  outp: seq[uint8]
  cs: ColorSet
  sims: Matrix[float]
  runs: seq[Palette]
  shares: seq[seq[float]]  # for each run, the pixel share of each exemplar
  stable: seq[StablePalette]
  sweepGen = 0           # bumped to cancel a running sweep
  sweeping = false
  pNext: float
  selected = -1          # run shown
  userPicked = false     # the user chose a run: don't move the selection
  keep: seq[bool]
  showOriginal = false
  tStart: float
  hasHint = false        # examples suggest a color to keep
  hint: ColorLAB

proc alpha(): float = parseFloat(value("alpha")) / 100
proc softness(): float = parseFloat(value("softness")) / 10
proc nColors(): int = parseInt(value("ncolors"))

# --- rendering -----------------------------------------------------------

proc chromaOf(c: int): float = sqrt(cs.lab[c].a.float ^ 2 + cs.lab[c].b.float ^ 2)

proc render() =
  if selected < 0 or source.isNull: return
  if showOriginal:
    putImageData(ctx, source)
    return
  let pal = runs[selected]
  let wts = keepWeights(cs, pal, keep, softness())
  colorSplash(pixels(source), 4, cs, wts, outp)
  shown.setPixels(outp)
  putImageData(ctx, shown)

proc order(r: int): seq[int] =
  ## Exemplar positions of run r, largest share first.
  result = newSeq[int](runs[r].exemplars.len)
  for e in 0 ..< result.len: result[e] = e
  let sh = shares[r]
  result.sort(proc (x, y: int): int = cmp(sh[y], sh[x]))

proc stableOf(k: int): int =
  for q, sp in stable:
    if sp.k == k: return q
  -1

proc renderPalettes() =
  ## One row per number of colors k, the run of its widest plateau (or the
  ## best run for k if it never holds for two runs in a row).
  var rows: seq[(int, int)]  # (k, run)
  for r, pal in runs:
    let k = pal.exemplars.len
    if k < 2 or k > kMax: continue
    var found = false
    for row in rows.mitems:
      if row[0] == k:
        found = true
        let q = stableOf(k)
        if q >= 0: row[1] = stable[q].palette
        elif pal.netsim > runs[row[1]].netsim: row[1] = r
    if not found:
      let q = stableOf(k)
      rows.add (k, (if q >= 0: stable[q].palette else: r))
  rows.sort(proc (x, y: (int, int)): int = cmp(x[0], y[0]))
  var maxWidth = 0.0
  for sp in stable:
    if sp.k >= 3: maxWidth = max(maxWidth, sp.width)
  var html = ""
  let selK = if selected >= 0: runs[selected].exemplars.len else: -1
  for (k, r) in rows:
    let q = stableOf(k)
    let width = if q >= 0: stable[q].width else: 0.0
    var rank = -1  # among the plateaus with 3+ colors (stable is widest first)
    if q >= 0 and k >= 3:
      rank = 0
      for p in stable[0 ..< q]:
        if p.k >= 3: inc rank
    let cls = (if k == selK: " is-selected" else: "") & (if rank in 0 .. 2: " is-stable" else: "")
    html.add &"""<li class="pal{cls}" data-run="{r}"><button class="pal-pick" data-run="{r}" aria-label="Show the {k}-color palette">"""
    html.add &"""<span class="pal-k">{k}</span><span class="pal-strip">"""
    if k == selK:
      # the selected palette: its swatches are toggles
      for e in order(selected):
        let x = runs[selected].exemplars[e]
        let on = e < keep.len and keep[e]
        html.add &"""<span class="sw{(if on: " on" else: "")}" style="flex-grow:{max(shares[selected][e], 0.004):.4f};background:{cs.rgb[x].hex}"></span>"""
    else:
      for e in order(r):
        let x = runs[r].exemplars[e]
        html.add &"""<span class="sw" style="flex-grow:{max(shares[r][e], 0.004):.4f};background:{cs.rgb[x].hex}"></span>"""
    html.add "</span>"
    let barW = if maxWidth > 0: min(100.0, 100 * width / maxWidth) else: 0.0
    html.add &"""<span class="pal-stab" title="range of log preference: {width:.2f}"><span style="width:{barW:.0f}%"></span></span>"""
    html.add "</button></li>"
  setHtml("palettes", html)

proc renderKeep() =
  ## The toggles of the selected palette.
  if selected < 0:
    setHtml("keep", "")
    return
  let pal = runs[selected]
  var html = ""
  for e in order(selected):
    let x = pal.exemplars[e]
    let on = e < keep.len and keep[e]
    let c = cs.rgb[x]
    let light = cs.lab[x].l > 60
    html.add &"""<button class="chip{(if on: " on" else: "")}{(if light: " light" else: "")}" data-ex="{e}" aria-pressed="{on}" style="--c:{c.hex}">"""
    html.add &"""<span class="chip-dot"></span><span class="chip-hex">{c.hex}</span><span class="chip-share">{100 * shares[selected][e]:.0f}%</span></button>"""
  setHtml("keep", html)
  var n = 0
  for k in keep:
    if k: inc n
  setText("keep-count", if n == 0: "No color kept: the image is all gray. Pick colors to keep."
                        elif n == pal.exemplars.len: "Every color kept."
                        else: &"{n} of {pal.exemplars.len} colors kept, the rest in gray.")

proc renderChart() =
  ## Number of colors against preference: a staircase, one dot per run.
  const W = 340.0
  const H = 150.0
  const L = 30.0
  const R = 8.0
  const T = 8.0
  const B = 26.0
  if runs.len == 0:
    setHtml("chart", "")
    return
  let x0 = ln(-runs[0].preference)
  let x1 = x0 + ln(factor) * float(max(runs.len - 1, 1))
  let kTop = max(kMax, 4)
  proc sx(p: float): float = L + (W - L - R) * (ln(-p) - x0) / (x1 - x0)
  proc sy(k: int): float = H - B - (H - B - T) * min(k, kTop).float / kTop.float
  var svg = &"""<svg viewBox="0 0 {W} {H}" role="img" aria-label="Number of colors for each preference">"""
  # plateau of the selected k
  if selected >= 0:
    let q = stableOf(runs[selected].exemplars.len)
    if q >= 0:
      let a = sx(runs[stable[q].first].preference) - 4
      let b = sx(runs[stable[q].last].preference) + 4
      svg.add &"""<rect class="band" x="{a:.1f}" y="{T}" width="{b - a:.1f}" height="{H - B - T}"/>"""
  for k in [0, 8, 16, 24]:
    svg.add &"""<line class="grid" x1="{L}" x2="{W - R}" y1="{sy(k):.1f}" y2="{sy(k):.1f}"/>"""
    svg.add &"""<text class="tick" x="{L - 6}" y="{sy(k) + 4:.1f}" text-anchor="end">{k}</text>"""
  var path = ""
  for r, pal in runs:
    let x = sx(pal.preference)
    let y = sy(pal.exemplars.len)
    path.add (if r == 0: &"M{x:.1f},{y:.1f}" else: &"H{x:.1f}V{y:.1f}")
  svg.add &"""<path class="stairs" d="{path}"/>"""
  for r, pal in runs:
    let cls = if r == selected: "dot is-selected" else: "dot"
    svg.add &"""<circle class="{cls}" data-run="{r}" cx="{sx(pal.preference):.1f}" cy="{sy(pal.exemplars.len):.1f}" r="{(if r == selected: 4.5 else: 2.6)}"/>"""
  svg.add &"""<text class="axis" x="{L}" y="{H - 6}">lower preference</text>"""
  svg.add &"""<text class="axis" x="{W - R}" y="{H - 6}" text-anchor="end">higher (closer to 0)</text>"""
  svg.add "</svg>"
  setHtml("chart", svg)

proc renderStatus() =
  if sweeping:
    setText("status", &"Finding palettes: {runs.len} runs so far…")
  elif runs.len > 0:
    var its = 0
    for r in runs: its += r.iterations
    setText("status", &"{runs.len} runs of affinity propagation on {cs.lab.len} colors, " &
                      &"{its} iterations in {(nowMs() - tStart) / 1000:.1f} s.")

proc defaultKeep(r: int): seq[bool] =
  ## The exemplar nearest to the example's suggested color, if it has one,
  ## else the most chromatic exemplar.
  result = newSeq[bool](runs[r].exemplars.len)
  var best = 0
  for e, x in runs[r].exemplars:
    if hasHint:
      if deltaE00(cs.lab[x], hint) < deltaE00(cs.lab[runs[r].exemplars[best]], hint): best = e
    elif chromaOf(x) > chromaOf(runs[r].exemplars[best]): best = e
  if result.len > 0: result[best] = true

proc select(r: int, keepColors: seq[bool] = @[]) =
  selected = r
  keep = if keepColors.len == runs[r].exemplars.len: keepColors else: defaultKeep(r)
  renderPalettes()
  renderKeep()
  renderChart()
  render()

proc autoSelect() =
  ## The widest plateau with at least 3 colors (2 if none).
  if userPicked: return
  var pick = -1
  for sp in stable:
    if sp.k >= 3:
      pick = sp.palette
      break
  if pick < 0 and stable.len > 0: pick = stable[0].palette
  if pick < 0: pick = runs.len - 1
  if pick != selected: select(pick)

# --- the sweep -----------------------------------------------------------

proc computeShares(pal: Palette): seq[float] =
  result = newSeq[float](pal.exemplars.len)
  var tot = 0.0
  for c, l in pal.labels:
    result[l] += cs.count[c].float
    tot += cs.count[c].float
  for x in result.mitems: x /= tot

proc step(gen: int) =
  if gen != sweepGen: return
  let pal = palette(sims, pNext)
  runs.add pal
  shares.add computeShares(pal)
  stable = stablePalettes(runs)
  pNext *= factor
  if pal.exemplars.len > kMax or runs.len >= 200:
    sweeping = false
  autoSelect()
  renderPalettes()
  renderChart()
  renderStatus()
  if sweeping:
    discard setTimeout(proc () = step(gen), 0)
  else:
    byId("app").classList.remove("is-busy")

proc analyze() =
  inc sweepGen
  let gen = sweepGen
  tStart = nowMs()
  sweeping = true
  runs = @[]
  shares = @[]
  stable = @[]
  selected = -1
  userPicked = false
  byId("app").classList.add("is-busy")
  setHtml("palettes", "")
  setHtml("keep", "")
  setText("keep-count", "")
  setText("status", "Reading the colors of the image…")
  discard setTimeout(proc () =
    if gen != sweepGen: return
    cs = colorSet(pixels(source), 4, nColors())
    sims = similarities(cs, alpha())
    pNext = preferenceBounds(sims)[0]
    if pNext.isNaN or pNext >= 0:
      sweeping = false
      setText("status", "This image has a single color.")
      byId("app").classList.remove("is-busy")
      return
    step(gen), 30)

proc loadImage(src: cstring, title: string) =
  let im = newImage()
  im.onload = proc () =
    img = im
    imgTitle = title
    let iw = im.naturalWidth.to(int)
    let ih = im.naturalHeight.to(int)
    let s = min(1.0, maxSide / max(iw, ih).float)
    w = max(1, int(round(iw.float * s)))
    h = max(1, int(round(ih.float * s)))
    let canvas = byId("canvas")
    canvas.setAttribute("width", cstring($w))
    canvas.setAttribute("height", cstring($h))
    ctx = ctx2d(canvas)
    drawImage(ctx, im, w, h)
    source = getImageData(ctx, w, h)
    shown = createImageData(ctx, w, h)
    outp = newSeq[uint8](w * h * 4)
    setText("image-title", title)
    analyze()
  im.src = src

proc selectExample(i: int) =
  let ex = examples()[i]
  for el in document.querySelectorAll(".thumb"):
    el.classList.remove("is-current")
  let t = byId("thumb-" & $i)
  if t != nil: t.classList.add("is-current")
  setText("credit", &"""{$ex.author.to(cstring)}. {$ex.license.to(cstring)}.""")
  let k = $ex.keep.to(cstring)
  hasHint = k.len == 7
  if hasHint:
    hint = toLab(parseHexInt(k[1..2]).float, parseHexInt(k[3..4]).float, parseHexInt(k[5..6]).float)
  loadImage(ex.src.to(cstring), $ex.title.to(cstring))

# --- wiring --------------------------------------------------------------

proc initThumbs() =
  # DOM nodes rather than an HTML string: the data URIs are large, and
  # turning them into Nim strings is slow (and overflows the stack).
  let exs = examples()
  let box = byId("thumbs")
  for i in 0 ..< exs.length.to(int):
    let ex = exs[i]
    let b = document.createElement("button")
    b.className = "thumb"
    b.id = cstring("thumb-" & $i)
    b.setAttribute("data-ex", cstring($i))
    b.setAttribute("title", ex.title.to(cstring))
    let im = document.createElement("img")
    im.setAttribute("alt", ex.title.to(cstring))
    im.setAttribute("src", ex.src.to(cstring))
    b.appendChild(im)
    box.appendChild(b)
  byId("thumbs").addEventListener("click", proc (ev: Event) =
    let b = closest(ev.target.toJs, ".thumb")
    if not b.isNull:
      selectExample(parseInt($b.getAttribute("data-ex").to(cstring))))

proc useFile(f: JsObject) =
  if f.isNull: return
  readAsDataUrl(f, proc (url: cstring) =
    for el in document.querySelectorAll(".thumb"):
      el.classList.remove("is-current")
    setText("credit", "Your image. It stays in this browser: nothing is uploaded.")
    hasHint = false
    loadImage(url, $f.name.to(cstring)))

proc main() =
  initThumbs()
  byId("palettes").addEventListener("click", proc (ev: Event) =
    let sw = closest(ev.target.toJs, ".pal.is-selected .sw")
    let b = closest(ev.target.toJs, "[data-run]")
    if b.isNull: return
    let r = parseInt($b.getAttribute("data-run").to(cstring))
    userPicked = true
    if r != selected or sw.isNull: select(r))
  byId("keep").addEventListener("click", proc (ev: Event) =
    let b = closest(ev.target.toJs, "[data-ex]")
    if b.isNull: return
    let e = parseInt($b.getAttribute("data-ex").to(cstring))
    keep[e] = not keep[e]
    renderKeep()
    renderPalettes()
    render())
  byId("chart").addEventListener("click", proc (ev: Event) =
    let d = closest(ev.target.toJs, "[data-run]")
    if d.isNull: return
    userPicked = true
    select(parseInt($d.getAttribute("data-run").to(cstring))))
  byId("softness").addEventListener("input", proc (ev: Event) =
    setText("softness-out", &"{softness():.1f}")
    render())
  byId("alpha").addEventListener("input", proc (ev: Event) =
    setText("alpha-out", &"{alpha():.2f}"))
  byId("alpha").addEventListener("change", proc (ev: Event) =
    if not source.isNull: analyze())
  byId("ncolors").addEventListener("change", proc (ev: Event) =
    if not source.isNull: analyze())
  byId("invert").addEventListener("click", proc (ev: Event) =
    for k in keep.mitems: k = not k
    renderKeep()
    renderPalettes()
    render())
  byId("copy").addEventListener("click", proc (ev: Event) =
    if selected < 0: return
    var hexes: seq[string]
    for e in order(selected): hexes.add cs.rgb[runs[selected].exemplars[e]].hex
    let text = hexes.join(" ")
    copyText(cstring(text),
      proc () = setText("copy-out", "Copied."),
      proc () = setText("copy-out", text)))
  let canvas = byId("canvas")
  for evName in ["pointerdown"]:
    canvas.addEventListener(cstring(evName), proc (ev: Event) =
      showOriginal = true
      render())
  for evName in ["pointerup", "pointerleave", "pointercancel"]:
    canvas.addEventListener(cstring(evName), proc (ev: Event) =
      if showOriginal:
        showOriginal = false
        render())
  byId("file").addEventListener("change", proc (ev: Event) =
    let files = ev.target.toJs.files
    if files.length.to(int) > 0: useFile(files[0]))
  let drop = byId("app")
  drop.addEventListener("dragover", proc (ev: Event) = ev.preventDefault())
  drop.addEventListener("drop", proc (ev: Event) =
    ev.preventDefault()
    let files = ev.toJs.dataTransfer.files
    if files.length.to(int) > 0: useFile(files[0]))
  setText("alpha-out", &"{alpha():.2f}")
  setText("softness-out", &"{softness():.1f}")
  if examples().length.to(int) > 0: selectExample(0)

main()
