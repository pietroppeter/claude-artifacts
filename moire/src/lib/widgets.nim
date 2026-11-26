## The widgets of the moiré page, in Nim compiled to JavaScript (`nim js`, see build.nim).
## Every picture is computed pixel by pixel, at the screen's own resolution, from the same
## procs in moiremath.nim that the page used when it was built. Touch first: one finger drags,
## sliders are big, nothing needs hover.
import std/[dom, math, strformat, strutils]
import moiremath

# ------------------------------------------------------------------ a little canvas interop
type
  Ctx {.importjs.} = ref object
  ImageData {.importjs.} = ref object
  Pixels {.importjs.} = ref object   # a Uint8ClampedArray

proc getContext2d(c: Element): Ctx {.importjs: "#.getContext('2d')".}
proc createImageData(c: Ctx; w, h: int): ImageData {.importjs: "#.createImageData(#, #)".}
proc putImageData(c: Ctx; d: ImageData) {.importjs: "#.putImageData(#, 0, 0)".}
proc data(d: ImageData): Pixels {.importjs: "#.data".}
proc `[]=`(p: Pixels; i: int; v: int) {.importjs: "#[#] = #".}
proc setW(c: Element; w: int) {.importjs: "#.width = #".}
proc setH(c: Element; h: int) {.importjs: "#.height = #".}
proc cssWidth(c: Element): float {.importjs: "#.getBoundingClientRect().width".}
proc dpr(): float {.importjs: "Math.min(window.devicePixelRatio || 1, 2)".}
proc cssVar(name: cstring): cstring {.importjs: "getComputedStyle(document.documentElement).getPropertyValue(#).trim()".}
proc raf(f: proc ()) {.importjs: "requestAnimationFrame(#)".}
proc valueF(e: Element): float {.importjs: "parseFloat(#.value)".}
proc setValueF(e: Element; v: float) {.importjs: "#.value = #".}
proc offsetX(e: Event): float {.importjs: "#.offsetX".}
proc offsetY(e: Event): float {.importjs: "#.offsetY".}
proc capture(e: Element; ev: Event) {.importjs: "#.setPointerCapture(#.pointerId)".}
proc now(): float {.importjs: "performance.now()".}
proc onResize(f: proc ()) {.importjs: "window.addEventListener('resize', #)".}

type Rgb = array[3, float]

proc hexRgb(s: cstring): Rgb =
  ## "#rrggbb" from the style module's tokens, so the canvases use the page's palette.
  proc h(i: int): float =
    var v = 0
    for k in 0..1:
      let c = s[i + k]
      v = v * 16 + (if c in '0'..'9': ord(c) - ord('0') elif c in 'a'..'f': ord(c) - ord('a') + 10
                    else: ord(c) - ord('A') + 10)
    float(v)
  [h(1), h(3), h(5)]

var paper, ink, ink2, rock, mark: Rgb

var paperC, markC: int   ## the same two, packed

# Colours travel as one packed int 0xRRGGBB: a shade runs for every pixel, so no arrays, no allocations.
proc pk(r, g, b: float): int {.inline.} = (int(r) shl 16) or (int(g) shl 8) or int(b)
proc pk(c: Rgb): int = pk(c[0], c[1], c[2])
proc one(c: Rgb; t: float): int {.inline.} =
  ## One sheet: ink c where t = 0, paper where t = 1.
  pk(c[0] + (paper[0] - c[0]) * t, c[1] + (paper[1] - c[1]) * t, c[2] + (paper[2] - c[2]) * t)
proc two(a: Rgb; s: float; b: Rgb; t: float): int {.inline.} =
  ## Two sheets on top of each other: their colours multiply, like two transparencies.
  pk((a[0] + (paper[0] - a[0]) * s) * (b[0] + (paper[0] - b[0]) * t) / 255,
     (a[1] + (paper[1] - a[1]) * s) * (b[1] + (paper[1] - b[1]) * t) / 255,
     (a[2] + (paper[2] - a[2]) * s) * (b[2] + (paper[2] - b[2]) * t) / 255)

# ------------------------------------------------------------------ the shared machinery
type
  Shade = proc (x, y: float): int   ## packed colour at a point, in units of a 360 wide frame
  Widget = ref object
    canvas: Element
    aspect: float                    ## height / width
    shade: Shade
    pending: bool
    blk: float                       ## > 1: draw in blocks of this many frame px (the aliasing widget)
    smooth: bool                     ## with blocks: average inside each block instead of sampling its centre

proc draw(w: Widget) =
  let cw = w.canvas.cssWidth
  if cw <= 0: return
  # shades work in a frame 360 units wide, whatever the canvas's size: s = device px per unit
  let s = dpr() * cw / 360
  let W = int(360 * s)
  let H = int(360 * w.aspect * s)
  w.canvas.setW W
  w.canvas.setH H
  let ctx = w.canvas.getContext2d
  let img = ctx.createImageData(W, H)
  let px = img.data
  if w.blk <= 1:
    for j in 0 ..< H:
      let y = (float(j) + 0.5) / s
      for i in 0 ..< W:
        let c = w.shade((float(i) + 0.5) / s, y)
        let k = 4 * (j * W + i)
        px[k] = (c shr 16) and 255; px[k + 1] = (c shr 8) and 255; px[k + 2] = c and 255; px[k + 3] = 255
  else:
    let b = max(1, int(w.blk * s))      # block size in device pixels
    var j0 = 0
    while j0 < H:
      var i0 = 0
      while i0 < W:
        var c: Rgb
        proc unpack(v: int): Rgb = [float((v shr 16) and 255), float((v shr 8) and 255), float(v and 255)]
        if w.smooth:
          const n = 4
          for a in 0 ..< n:
            for bb in 0 ..< n:
              let d = unpack w.shade((float(i0) + (float(a) + 0.5) * float(b) / n) / s,
                              (float(j0) + (float(bb) + 0.5) * float(b) / n) / s)
              for q in 0..2: c[q] += d[q] / (n * n)
        else:
          c = unpack w.shade((float(i0) + float(b) / 2) / s, (float(j0) + float(b) / 2) / s)
        for j in j0 ..< min(j0 + b, H):
          for i in i0 ..< min(i0 + b, W):
            let k = 4 * (j * W + i)
            px[k] = int(c[0]); px[k + 1] = int(c[1]); px[k + 2] = int(c[2]); px[k + 3] = 255
        i0 += b
      j0 += b
  ctx.putImageData(img)

proc redraw(w: Widget) =
  ## Coalesce many slider events into one frame.
  if w.pending: return
  w.pending = true
  raf(proc () =
    w.pending = false
    w.draw)

var all: seq[Widget]

proc widget(id: string; aspect: float; shade: Shade): Widget =
  result = Widget(canvas: document.getElementById(cstring(id & "-c")), aspect: aspect, shade: shade)
  all.add result

proc el(id: string): Element = document.getElementById(cstring(id))
proc say(id, html: string) = el(id).innerHTML = cstring(html)
proc slider(id: string; f: proc (v: float)) =
  let e = el(id)
  e.addEventListener("input", proc (ev: Event) = f(e.valueF))
  f(e.valueF)


proc fmt1(x: float): string =
  if x == Inf or x > 1e5: "∞" else: formatFloat(x, ffDecimal, 1)

const soft = 0.6    # units of edge blur: enough that the screen does not add a moiré of its own
const duty = 0.5    # half clear, half ink: where the sheets disagree, no light gets through at all

# ------------------------------------------------------------------ 1. the hero: drag a turned grating
proc hero() =
  var shift = 0.0
  var angle = degToRad(6.0)
  const p = 6.0
  let w = widget("hero", 0.8, proc (x, y: float): int =
    let a = grating(x, p, soft = soft, duty = duty)
    let cx = x - 180 - shift
    let cy = y - 150
    let u = cx * cos(angle) + cy * sin(angle)
    two(ink, a, ink2, grating(u, p, soft = soft, duty = duty)))
  var last = 0.0
  var down = false
  w.canvas.addEventListener("pointerdown", proc (e: Event) =
    down = true; last = e.offsetX; w.canvas.capture(e))
  w.canvas.addEventListener("pointermove", proc (e: Event) =
    if down:
      shift += (e.offsetX - last) * 360 / w.canvas.cssWidth; last = e.offsetX
      say("hero-out", &"top sheet moved <b>{fmt1(abs(shift))} units</b>")
      w.redraw)
  for ev in ["pointerup", "pointercancel"]:
    w.canvas.addEventListener(cstring(ev), proc (e: Event) = down = false)
  say("hero-out", "drag me")
  slider("hero-a", proc (v: float) =
    angle = degToRad(v)
    say("hero-a-v", &"{fmt1(v)}°")
    w.redraw)
  var playing = false
  var t0 = 0.0
  let btn = el("hero-play")
  proc step() =
    if not playing: return
    let t = now()
    shift += (t - t0) * 0.012; t0 = t
    say("hero-out", &"top sheet moved <b>{fmt1(abs(shift))} units</b>")
    w.draw
    raf(step)
  btn.addEventListener("click", proc (e: Event) =
    playing = not playing
    btn.innerHTML = (if playing: "⏸ Stop" else: "▶ Drift")
    if playing:
      t0 = now(); raf(step))

# ------------------------------------------------------------------ 2. beats: two periods
proc beats() =
  var p1 = 8.0
  var p2 = 9.0
  # four bands: A, B, A×B, and A×B seen from afar (blurred over one period)
  let w = widget("beat", 0.72, proc (x, y: float): int =
    let a = grating(x, p1, soft = soft, duty = duty)
    let b = grating(x, p2, soft = soft, duty = duty)
    if y < 40: one(ink, a)
    elif y < 48: paperC
    elif y < 88: one(ink2, b)
    elif y < 100: paperC
    elif y < 180: two(ink, a, ink2, b)
    elif y < 196: paperC
    else:
      # what the eye sees from a distance: the average of A×B over one period around x
      const n = 48
      var acc = 0.0
      let span = max(p1, p2)
      for k in 0 ..< n:
        let xx = x + (float(k) / n - 0.5) * span
        acc += grating(xx, p1, duty) * grating(xx, p2, duty)
      let t = acc / n
      # as a curve: dark under the line, paper above
      let top = 196.0
      let hgt = 64.0
      let yv = top + hgt * (1 - (t - (2 * duty - 1)) / (1 - duty))   # the average goes from 2·duty−1 to duty
      if y > yv: one(mark, 0.35) else: paperC)
  proc update() =
    let P = moirePeriod(p1, p2)
    say("beat-out", &"fringe period <b>{fmt1(P)} units</b> = {fmt1(p1)}·{fmt1(p2)} / |{fmt1(p1)} − {fmt1(p2)}|")
    w.redraw
  slider("beat-p1", proc (v: float) = p1 = v; say("beat-p1-v", fmt1(v)); update())
  slider("beat-p2", proc (v: float) = p2 = v; say("beat-p2-v", fmt1(v)); update())

# ------------------------------------------------------------------ 3. turn one grating
proc turn() =
  var theta = degToRad(5.0)
  const p = 5.0
  let w = widget("turn", 0.8, proc (x, y: float): int =
    let cx = x - 180
    let cy = y - 150
    let u = cx * cos(theta) + cy * sin(theta)
    two(ink, grating(cx, p, soft = soft, duty = duty), ink2, grating(u, p, soft = soft, duty = duty)))
  slider("turn-a", proc (v: float) =
    theta = degToRad(v)
    say("turn-a-v", &"{fmt1(v)}°")
    say("turn-out", &"fringe spacing <b>{fmt1(rotationPeriod(p, theta))} units</b> from lines {fmt1(p)} apart: " &
        &"<b>×{fmt1(rotationPeriod(p, theta) / p)}</b>")
    w.redraw)

# ------------------------------------------------------------------ 4. the lever: a tiny slide, a big move
proc lever() =
  const p1 = 8.0
  const p2 = 8.4
  var d = 0.0
  let M = magnification(p1, p2)
  let w = widget("lever", 0.62, proc (x, y: float): int =
    if y < 36:
      # the sliding sheet alone, with a red pointer that moves with it
      if y > 26 and abs(x - (168 + d)) < 1.2: markC
      else: one(ink2, grating(x - d, p2, soft = soft, duty = duty))
    elif y < 46: paperC
    else:
      # the fringe pointer follows where the dark band's middle went: x0 + d·M
      let fringe = 168 + d * M
      let fp = moirePeriod(p1, p2)
      let fx = fringe - fp * floor((fringe - 10) / fp)    # keep it on screen
      if y > 200 and abs(x - fx) < 2.0: markC
      else: two(ink, grating(x, p1, soft = soft, duty = duty), ink2, grating(x - d, p2, soft = soft, duty = duty)))
  slider("lever-d", proc (v: float) =
    d = v
    say("lever-out", &"top sheet moved <b>{fmt1(abs(d))} units</b>, the fringes moved <b>{fmt1(abs(d * M))} units</b> " &
        &"(×{fmt1(abs(M))}, the other way)")
    w.redraw)

# ------------------------------------------------------------------ 5. rings, rays and lines
proc rings() =
  var kind = 0                        # 0 rings+rings, 1 rings+lines, 2 rays+rays
  var cx2 = 200.0
  var cy2 = 170.0
  const p = 7.0
  proc ringT(x, y, cx, cy: float): float = grating(sqrt((x - cx) ^ 2 + (y - cy) ^ 2), p, soft = soft, duty = duty)
  proc rayT(x, y, cx, cy: float): float =
    # 72 spokes; soft edges measured in px along the circle
    let r = max(1.0, sqrt((x - cx) ^ 2 + (y - cy) ^ 2))
    let ang = arctan2(y - cy, x - cx) + PI
    grating(ang * r, 2 * PI * r / 72, soft = soft, duty = duty)
  let w = widget("rings", 1.0, proc (x, y: float): int =
    let c1 = 180.0
    case kind
    of 0: two(ink, ringT(x, y, c1, c1), ink2, ringT(x, y, cx2, cy2))
    of 1: two(ink, ringT(x, y, c1, c1), ink2, grating(x - cx2, p, soft = soft, duty = duty))
    else: two(ink, rayT(x, y, c1, c1), ink2, rayT(x, y, cx2, cy2)))
  # the canvas is drawn in a 360 px wide frame of reference: map finger positions to it
  proc toFrame(e: Event): (float, float) =
    let k = 360 / w.canvas.cssWidth
    (e.offsetX * k, e.offsetY * k)
  var down = false
  w.canvas.addEventListener("pointerdown", proc (e: Event) =
    down = true; w.canvas.capture(e)
    (cx2, cy2) = toFrame(e); w.redraw)
  w.canvas.addEventListener("pointermove", proc (e: Event) =
    if down:
      (cx2, cy2) = toFrame(e); w.redraw)
  for ev in ["pointerup", "pointercancel"]:
    w.canvas.addEventListener(cstring(ev), proc (e: Event) = down = false)
  for i, id in ["rings-0", "rings-1", "rings-2"]:
    let k = i
    let b = el(id)
    b.addEventListener("click", proc (e: Event) =
      kind = k
      for j, other in ["rings-0", "rings-1", "rings-2"]:
        el(other).setAttribute("aria-pressed", cstring(if j == k: "true" else: "false"))
      w.redraw)

# ------------------------------------------------------------------ 6. aliasing: a zone plate seen through pixels
proc alias() =
  var w: Widget
  w = widget("alias", 1.0, proc (x, y: float): int =
    # cos(π r²/λR): rings that get finer and finer away from the centre
    let r2 = (x - 180) ^ 2 + (y - 180) ^ 2
    let t = 0.5 + 0.5 * cos(PI * r2 / 260)
    one(ink, t))
  slider("alias-b", proc (v: float) =
    w.blk = v
    say("alias-b-v", &"{fmt1(v)} units")
    w.redraw)
  let b = el("alias-smooth")
  b.addEventListener("click", proc (e: Event) =
    w.smooth = not w.smooth
    b.setAttribute("aria-pressed", cstring(if w.smooth: "true" else: "false"))
    b.innerHTML = (if w.smooth: "Averaging each pixel (anti-aliased)" else: "Sampling each pixel's centre")
    w.redraw)

# ------------------------------------------------------------------ 7. the glacier
proc glacier() =
  var t = 0.0                         # months
  var view = 0                        # 0 both, 1 before, 2 after
  const p = 7.0                       # grating period: one "survey line" every p units
  const half = 110.0                  # half the valley width, px
  const uMax = 2.2                    # px a month in the middle (toy)
  let w = widget("glacier", 0.85, proc (x, y: float): int =
    let yc = y - 153                  # the valley's axis
    if abs(yc) > half:
      # the rock walls: a calm grey, with a soft edge
      return one(rock, clamp((abs(yc) - half) / 40, 0.0, 0.5))
    let before = grating(x, p, soft = soft, duty = duty)
    # the ice speeds up downstream (toward an icefall, say): ×0.5 at the left edge, ×1.5 at the right
    let after = grating(x - flow(yc, half, uMax, n = 1) * (0.5 + x / 360) * t, p, soft = soft, duty = duty)
    case view
    of 1: one(ink, before)
    of 2: one(ink2, after)
    else: two(ink, before, ink2, after))
  slider("glacier-t", proc (v: float) =
    t = v
    let mid = flow(0, half, uMax, n = 1) * t   # at the middle of the picture (×1)
    say("glacier-t-v", &"{fmt1(v)} months")
    say("glacier-out", &"at the centre of the picture the ice moved <b>{fmt1(mid)} units</b> = {fmt1(mid / p)} line spacings")
    w.redraw)
  for i, id in ["glacier-0", "glacier-1", "glacier-2"]:
    let k = i
    el(id).addEventListener("click", proc (e: Event) =
      view = k
      for j, other in ["glacier-0", "glacier-1", "glacier-2"]:
        el(other).setAttribute("aria-pressed", cstring(if j == k: "true" else: "false"))
      w.redraw)

# ------------------------------------------------------------------ start
proc main() =
  paper = hexRgb(cssVar("--paper"))
  ink = hexRgb(cssVar("--ink-a"))
  ink2 = hexRgb(cssVar("--ink-b"))
  rock = hexRgb(cssVar("--rock"))
  mark = hexRgb(cssVar("--mark"))
  paperC = pk(paper)
  markC = pk(mark)
  hero(); beats(); turn(); lever(); rings(); alias(); glacier()
  for w in all: w.redraw
  var lastW = 0.0
  onResize(proc () =
    let cw = el("hero-c").cssWidth
    if abs(cw - lastW) > 1:
      lastW = cw
      for w in all: w.redraw)

main()
