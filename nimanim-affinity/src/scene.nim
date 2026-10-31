## Affinity Propagation, explained with nimanim.
##
## Build (from the page folder, after `sh src/deps.sh`; see src/README.md):
##   nim c -r -d:release src/scene.nim
## writes affinity_propagation.mp4 to the current directory.

import std/[algorithm, strformat, math]
import nimanim
import cairo  # nimanim does not re-export FontWeight/FontSlant

# ---------------------------------------------------------------------------
# Data + the algorithm itself (plain Nim, independent of the renderer)
# ---------------------------------------------------------------------------

const pts: seq[Point2] = @[
  # cluster A (upper left)
  (-5.6, 1.9), (-4.9, 2.5), (-4.6, 1.6), (-5.3, 1.1), (-4.1, 2.2),
  # cluster B (lower left)
  (-5.0, -1.6), (-4.3, -2.3), (-5.6, -2.4), (-4.4, -1.3),
  # cluster C (middle)
  (-1.9, 0.1), (-1.2, 0.7), (-1.5, -0.6), (-0.7, -0.1), (-2.2, 0.9),
]
let n = pts.len

type Mat = seq[seq[float]]
proc newMat(n: int): Mat =
  result = newSeq[seq[float]](n)
  for i in 0..<n: result[i] = newSeq[float](n)

proc similarity(pref: float): Mat =
  result = newMat(n)
  for i in 0..<n:
    for k in 0..<n:
      if i == k: result[i][k] = pref
      else:
        let d = pts[i] - pts[k]
        result[i][k] = -(d.x*d.x + d.y*d.y)

proc medianOffDiag(): float =
  var v: seq[float]
  for i in 0..<n:
    for k in 0..<n:
      if i != k:
        let d = pts[i] - pts[k]
        v.add(-(d.x*d.x + d.y*d.y))
  v.sort()
  v[v.len div 2]

type Snapshot = object
  R, A: Mat

proc runAP(S: Mat, iters: int, damping = 0.8): seq[Snapshot] =
  var R = newMat(n)
  var A = newMat(n)
  result.add(Snapshot(R: R, A: A))
  for it in 0..<iters:
    # responsibilities
    var Rn = newMat(n)
    for i in 0..<n:
      for k in 0..<n:
        var best = -Inf
        for k2 in 0..<n:
          if k2 != k: best = max(best, A[i][k2] + S[i][k2])
        Rn[i][k] = S[i][k] - best
    for i in 0..<n:
      for k in 0..<n:
        R[i][k] = damping * R[i][k] + (1 - damping) * Rn[i][k]
    # availabilities
    var An = newMat(n)
    for i in 0..<n:
      for k in 0..<n:
        var acc = 0.0
        for i2 in 0..<n:
          if i2 != i and i2 != k: acc += max(0.0, R[i2][k])
        if i == k: An[i][k] = acc
        else: An[i][k] = min(0.0, R[k][k] + acc)
    for i in 0..<n:
      for k in 0..<n:
        A[i][k] = damping * A[i][k] + (1 - damping) * An[i][k]
    result.add(Snapshot(R: R, A: A))

proc lerpMat(a, b: Mat, t: float): Mat =
  result = newMat(n)
  for i in 0..<n:
    for k in 0..<n: result[i][k] = a[i][k] + (b[i][k] - a[i][k]) * t

proc choice(s: Snapshot, i: int): int =
  ## i's current preferred exemplar: argmax_k a(i,k) + r(i,k)
  var best = -Inf
  for k in 0..<n:
    let v = s.A[i][k] + s.R[i][k]
    if v > best: (best, result) = (v, k)

proc evidence(s: Snapshot, k: int): float = s.R[k][k] + s.A[k][k]

# ---------------------------------------------------------------------------
# Visual helpers (workarounds for things nimanim does not provide yet)
# ---------------------------------------------------------------------------

const
  BG = rgb255(18, 20, 28)
  DIM = rgb255(120, 125, 140)
  RESP = rgb255(255, 140, 60)     # responsibility: orange
  AVAIL = rgb255(70, 200, 210)    # availability: teal
  GOLD = rgb255(255, 205, 70)
  PALETTE = [rgb255(90, 150, 255), rgb255(255, 110, 120), rgb255(120, 220, 130),
             rgb255(200, 130, 255)]
  PR = 0.13                        # point radius

var fps = 30

proc tween(s: Scene, duration: float, body: proc(t: float),
           easing: EasingFunc = smoothstep) =
  ## Poor man's manim "updater": run `body` with eased progress once per
  ## frame, rendering one frame each time. nimanim has no updater /
  ## ValueTracker, but `wait(1/fps)` renders exactly one frame.
  let frames = max(1, int(duration * fps.float + 0.5))
  for f in 1..frames:
    body(easing(f / frames))
    s.wait(1.0 / fps.float)

proc fadeAll(s: Scene, ms: seq[Mobject], target: float, duration = 0.6) =
  ## Fade a list of mobjects to `target` opacity (works for lines too,
  ## and for things whose start opacity is 0, unlike `fadeIn`).
  var f0, s0: seq[float]
  for m in ms:
    f0.add(m.fillOpacity); s0.add(m.strokeOpacity)
    m.visible = true
  var fT, sT: seq[float]
  for m in ms:
    # text is drawn with fill only; lines with stroke only
    fT.add(if m.kind == mkText: target else: m.fillOpacity)
    sT.add(if m.kind == mkText: 0.0 else: target)
  s.tween(duration, proc(t: float) =
    for i, m in ms:
      m.fillOpacity = f0[i] + (fT[i] - f0[i]) * t
      m.strokeOpacity = s0[i] + (sT[i] - s0[i]) * t)

proc arrowParts(a, b: Point2, color: Color, width: float,
                inset = PR + 0.05): tuple[shaft, head: Mobject] =
  ## nimanim has no Arrow mobject: build one from a line + triangle.
  let d = b - a
  let L = sqrt(d.x*d.x + d.y*d.y)
  let u: Point2 = (d.x / L, d.y / L)
  let nrm: Point2 = (-u.y, u.x)
  let start = a + u * inset
  let tip = b - u * inset
  let hl = 0.12 + width * 1.5
  let base = tip - u * hl
  let shaft = newLine(start, base, strokeColor = color, strokeWidth = width)
  let head = newPolygon(@[tip, base + nrm * (hl * 0.55), base - nrm * (hl * 0.55)],
                        fillColor = color, strokeColor = color,
                        fillOpacity = 1.0, strokeWidth = 0.01)
  (shaft, head)

proc setArrow(shaft, head: Mobject, a, b: Point2, width, opacity: float,
              color: Color, inset = PR + 0.05) =
  let (s2, h2) = arrowParts(a, b, color, width, inset)
  shaft.p1 = s2.p1; shaft.p2 = s2.p2; shaft.strokeWidth = width
  shaft.strokeColor = color; head.fillColor = color; head.strokeColor = color
  head.center = h2.center; head.vertices = h2.vertices
  shaft.strokeOpacity = opacity; head.fillOpacity = opacity
  head.strokeOpacity = opacity

proc caption(txt: string, y: float, size = 0.34, color = WHITE): Mobject =
  newText(txt, fontSize = size, center = (3.9, y), color = color)

# ---------------------------------------------------------------------------
# The scene
# ---------------------------------------------------------------------------

let pref = medianOffDiag()
let S = similarity(pref)
let hist = runAP(S, 60)
let final = hist[^1]

# Exemplars and cluster colours from the converged state.
var exemplars: seq[int]
for k in 0..<n:
  if evidence(final, k) > 0: exemplars.add(k)
proc clusterOf(i: int): int =
  if i in exemplars: return exemplars.find(i)
  var best = -Inf
  for ci, k in exemplars:
    if S[i][k] > best: (best, result) = (S[i][k], ci)

proc construct(s: Scene) =
  s.backgroundColor = BG

  # --- Title -----------------------------------------------------------
  let title = newText("Affinity Propagation", fontSize = 0.8, center = (0.0, 0.5),
                      fontWeight = FontWeightBold)
  let sub = newText("clustering by passing messages", fontSize = 0.38,
                    center = (0.0, -0.4), color = DIM)
  sub.fillOpacity = 0.0
  s.add(title, sub)
  s.play(2.0, write(title))
  s.fadeAll(@[sub], 1.0, 0.8)
  s.wait(1.2)
  s.play(fadeOut(title), fadeOut(sub))
  s.remove(title); s.remove(sub)

  # --- Points -----------------------------------------------------------
  var dots: seq[Mobject]
  for p in pts:
    let d = newCircle(PR, p, fillColor = WHITE, strokeColor = WHITE,
                      fillOpacity = 1.0, strokeWidth = 0.02)
    dots.add(d)
  # halos show "exemplar evidence" later on
  var halos: seq[Mobject]
  for p in pts:
    let h = newCircle(PR + 0.12, p, strokeColor = GOLD, strokeOpacity = 0.0,
                      strokeWidth = 0.05)
    halos.add(h)
    s.add(h)
  for d in dots: s.add(d)
  var c1 = caption("14 points.", 2.6)
  var c2 = caption("How many clusters? We don't say.", 2.0, 0.3, DIM)
  s.add(c1, c2)
  var anims: seq[Animation]
  for d in dots: anims.add(create(d, duration = 1.2))
  anims.add(write(c1, duration = 1.0))
  s.play(anims)
  c2.fillOpacity = 0
  s.fadeAll(@[c2], 1.0)
  s.wait(1.0)

  let divider = newLine((0.9, -3.6), (0.9, 3.6), strokeColor = DIM, strokeWidth = 0.01)
  divider.strokeOpacity = 0
  s.add(divider)
  s.fadeAll(@[divider], 0.5, 0.4)

  # --- Similarity ---------------------------------------------------------
  let i0 = 2   # our protagonist point
  s.play(fadeOut(c1), fadeOut(c2))
  c1 = caption("Similarity", 2.9, 0.42, WHITE)
  c2 = caption("s(i,k) = −‖xᵢ − xₖ‖²", 2.2, 0.36, WHITE)
  var c3 = caption("closer points are more similar", 1.6, 0.28, DIM)
  for c in [c1, c2, c3]:
    c.fillOpacity = 0; s.add(c)
  s.fadeAll(@[c1, c2, c3], 1.0)
  s.play(scaleTo(dots[i0], 1.6, duration = 0.5))
  dots[i0].fillColor = GOLD; dots[i0].strokeColor = GOLD

  var simLines: seq[Mobject]
  var minS = 0.0
  for k in 0..<n:
    if k != i0: minS = min(minS, S[i0][k])
  for k in 0..<n:
    if k == i0: continue
    let l = newLine(pts[i0], pts[k], strokeColor = WHITE,
                    strokeWidth = 0.01 + 0.06 * (1 - S[i0][k] / minS))
    l.strokeOpacity = 0
    simLines.add(l)
    s.mobjects.insert(l, 0)
  let simOps = block:
    var o: seq[float]
    for k in 0..<n:
      if k != i0: o.add(0.15 + 0.85 * (1 - S[i0][k] / minS))
    o
  s.tween(1.2, proc(t: float) =
    for j, l in simLines: l.strokeOpacity = simOps[j] * t)
  s.wait(1.0)
  let c4 = caption("s(k,k) = preference: how much each point", 0.8, 0.28, DIM)
  let c5 = caption("wants to be an exemplar (here: the median)", 0.35, 0.28, DIM)
  for c in [c4, c5]:
    c.fillOpacity = 0; s.add(c)
  s.fadeAll(@[c4, c5], 1.0)
  s.wait(2.0)
  s.tween(0.8, proc(t: float) =
    for j, l in simLines: l.strokeOpacity = simOps[j] * (1 - t))
  for l in simLines: s.remove(l)
  s.play(fadeOut(c1), fadeOut(c2), fadeOut(c3), fadeOut(c4), fadeOut(c5))

  # --- Responsibility -----------------------------------------------------
  # Use the messages after the first sweep (availabilities still 0).
  let early = runAP(S, 1, damping = 0.0)[1]
  c1 = caption("Responsibility  r(i,k)", 2.9, 0.42, RESP)
  c2 = caption("i → k: \"how well do you suit me as an exemplar,", 2.2, 0.27, WHITE)
  let c2b = caption("compared to my other options?\"", 1.8, 0.27, WHITE)
  let c3r = caption("r(i,k) = s(i,k) − max  [a(i,k′) + s(i,k′)]", 1.1, 0.3, WHITE)
  let c3s = caption("k′≠k", 0.88, 0.18, DIM)
  c3s.center = (3.55, 0.85)
  for c in [c1, c2, c2b, c3r, c3s]:
    c.fillOpacity = 0; s.add(c)
  s.fadeAll(@[c1, c2, c2b, c3r, c3s], 1.0)

  var rShafts, rHeads: seq[Mobject]
  var rTargets: seq[int]
  var rmin = Inf; var rmax = -Inf
  for k in 0..<n:
    if k == i0: continue
    rmin = min(rmin, early.R[i0][k]); rmax = max(rmax, early.R[i0][k])
  for k in 0..<n:
    if k == i0: continue
    let (sh, hd) = arrowParts(pts[i0], pts[k], RESP, 0.02)
    sh.strokeOpacity = 0; hd.fillOpacity = 0; hd.strokeOpacity = 0
    rShafts.add(sh); rHeads.add(hd); rTargets.add(k)
    s.mobjects.insert(sh, 0); s.add(hd)
  s.tween(1.5, proc(t: float) =
    for j, k in rTargets:
      let v = (early.R[i0][k] - rmin) / (rmax - rmin)   # 0..1
      let w = 0.012 + 0.07 * v * v
      setArrow(rShafts[j], rHeads[j], pts[i0], pts[k], w, t * (0.12 + 0.88 * v * v), RESP))
  let c6 = caption("Mostly says: \"you, my nearest neighbour!\"", 0.1, 0.27, DIM)
  c6.fillOpacity = 0; s.add(c6)
  s.fadeAll(@[c6], 1.0)
  s.wait(2.5)
  s.tween(0.7, proc(t: float) =
    for j in 0..<rShafts.len:
      rShafts[j].strokeOpacity *= (1 - t); rHeads[j].fillOpacity *= (1 - t)
      rHeads[j].strokeOpacity *= (1 - t))
  for m in rShafts & rHeads: s.remove(m)
  s.play(fadeOut(c1), fadeOut(c2), fadeOut(c2b), fadeOut(c3r), fadeOut(c3s), fadeOut(c6))

  # --- Availability --------------------------------------------------------
  let later = hist[12]
  c1 = caption("Availability  a(i,k)", 2.9, 0.42, AVAIL)
  c2 = caption("k → i: \"here's how much support I already", 2.2, 0.27, WHITE)
  let c2c = caption("have from others to be an exemplar\"", 1.8, 0.27, WHITE)
  let c3a = caption("a(i,k) = min(0, r(k,k) + Σ max(0, r(i′,k)))", 1.1, 0.3, WHITE)
  let c3t = caption("i′∉{i,k}", 0.85, 0.18, DIM)
  c3t.center = (4.3, 0.83)
  for c in [c1, c2, c2c, c3a, c3t]:
    c.fillOpacity = 0; s.add(c)
  s.fadeAll(@[c1, c2, c2c, c3a, c3t], 1.0)
  var aShafts, aHeads: seq[Mobject]
  var aTargets: seq[int]
  var amin = Inf; var amax = -Inf
  for k in 0..<n:
    if k == i0: continue
    amin = min(amin, later.A[i0][k]); amax = max(amax, later.A[i0][k])
  for k in 0..<n:
    if k == i0: continue
    let (sh, hd) = arrowParts(pts[k], pts[i0], AVAIL, 0.02)
    sh.strokeOpacity = 0; hd.fillOpacity = 0; hd.strokeOpacity = 0
    aShafts.add(sh); aHeads.add(hd); aTargets.add(k)
    s.mobjects.insert(sh, 0); s.add(hd)
  s.tween(1.5, proc(t: float) =
    for j, k in aTargets:
      let v = (later.A[i0][k] - amin) / max(1e-9, amax - amin)
      let w = 0.012 + 0.06 * v * v
      setArrow(aShafts[j], aHeads[j], pts[k], pts[i0], w, t * (0.1 + 0.9 * v * v), AVAIL))
  let c7 = caption("Points backed by many others speak loudest.", 0.1, 0.27, DIM)
  c7.fillOpacity = 0; s.add(c7)
  s.fadeAll(@[c7], 1.0)
  s.wait(2.5)
  s.tween(0.7, proc(t: float) =
    for j in 0..<aShafts.len:
      aShafts[j].strokeOpacity *= (1 - t); aHeads[j].fillOpacity *= (1 - t)
      aHeads[j].strokeOpacity *= (1 - t))
  for m in aShafts & aHeads: s.remove(m)
  s.play(fadeOut(c1), fadeOut(c2), fadeOut(c2c), fadeOut(c3a), fadeOut(c3t),
         fadeOut(c7), scaleTo(dots[i0], 1.0, duration = 0.6))
  dots[i0].fillColor = WHITE; dots[i0].strokeColor = WHITE

  # --- Everyone at once -------------------------------------------------
  c1 = caption("Now everyone talks at once", 2.9, 0.42)
  c2 = caption("each point points to its favourite exemplar", 2.3, 0.27, DIM)
  c3 = caption("argmax  a(i,k) + r(i,k)", 1.85, 0.27, DIM)
  let c8 = caption("gold ring = evidence r(k,k)+a(k,k) for being an exemplar", 1.4, 0.24, GOLD)
  let iterText = caption("iteration 0", -2.8, 0.36, WHITE)
  for c in [c1, c2, c3, c8, iterText]:
    c.fillOpacity = 0; s.add(c)
  s.fadeAll(@[c1, c2, c3, c8, iterText], 1.0)

  var cShafts, cHeads: seq[Mobject]
  for i in 0..<n:
    let (sh, hd) = arrowParts(pts[i], pts[(i + 1) mod n], WHITE, 0.02)
    sh.strokeOpacity = 0; hd.fillOpacity = 0; hd.strokeOpacity = 0
    cShafts.add(sh); cHeads.add(hd)
    s.mobjects.insert(sh, 0); s.add(hd)

  var evScale = 0.0
  for k in 0..<n: evScale = max(evScale, abs(evidence(final, k)))
  evScale = max(evScale, 1.0)

  proc showState(st: Snapshot, fadeIn = 1.0) =
    for i in 0..<n:
      let k = choice(st, i)
      if k == i:
        cShafts[i].strokeOpacity = 0; cHeads[i].fillOpacity = 0
        cHeads[i].strokeOpacity = 0
      else:
        setArrow(cShafts[i], cHeads[i], pts[i], pts[k], 0.025, 0.75 * fadeIn,
                 rgb255(210, 215, 230))
    for k in 0..<n:
      let e = evidence(st, k)
      let z = 1.0 / (1.0 + exp(-4.0 * e / evScale))  # 0..1
      halos[k].strokeOpacity = fadeIn * clamp((z - 0.25) * 1.6, 0.0, 1.0)
      halos[k].radius = PR + 0.05 + 0.35 * z
      if e > 0:
        dots[k].fillColor = lerpColor(WHITE, GOLD, clamp(e / evScale * 3, 0, 1))
      else:
        dots[k].fillColor = WHITE

  s.tween(0.8, proc(t: float) = showState(hist[0], t))
  let shownIters = 40
  for it in 0..<shownIters:
    let a = hist[it]; let b = hist[it + 1]
    let dur = if it < 6: 0.55 elif it < 20: 0.3 else: 0.15
    iterText.text = &"iteration {it + 1}"
    s.tween(dur, proc(t: float) =
      showState(Snapshot(R: lerpMat(a.R, b.R, t), A: lerpMat(a.A, b.A, t))),
      linear)
  s.wait(1.0)

  # --- Result ----------------------------------------------------------
  s.play(fadeOut(c1), fadeOut(c2), fadeOut(c3), fadeOut(c8))
  c1 = caption(&"{exemplars.len} exemplars emerged", 2.9, 0.42, GOLD)
  c2 = caption("the data chose the number of clusters", 2.3, 0.27, DIM)
  c3 = caption("(lower preference → fewer exemplars)", 1.85, 0.27, DIM)
  for c in [c1, c2, c3]:
    c.fillOpacity = 0; s.add(c)
  var fromCol: seq[Color]
  for d in dots: fromCol.add(d.fillColor)
  s.tween(1.5, proc(t: float) =
    for c in [c1, c2, c3]: c.fillOpacity = t
    for i in 0..<n:
      let col = PALETTE[clusterOf(i) mod PALETTE.len]
      dots[i].fillColor = lerpColor(fromCol[i], col, t)
      dots[i].strokeColor = dots[i].fillColor
      if i notin exemplars:
        cShafts[i].strokeColor = lerpColor(rgb255(210, 215, 230), col, t)
        cHeads[i].fillColor = cShafts[i].strokeColor
        cHeads[i].strokeColor = cShafts[i].strokeColor
    for k in exemplars:
      halos[k].strokeColor = lerpColor(GOLD, PALETTE[exemplars.find(k)], t)
      halos[k].strokeWidth = 0.05 + 0.03 * t)
  var ex: seq[Animation]
  for k in exemplars: ex.add(scaleTo(dots[k], 1.7, duration = 0.5, easing = thereAndBack))
  s.play(ex)
  s.wait(1.0)
  s.play(fadeOut(iterText))

  # Bonus: same data, low preference
  let lowPref = pref * 4.0
  let S2 = similarity(lowPref)
  let hist2 = runAP(S2, 80)
  var ex2: seq[int]
  for k in 0..<n:
    if evidence(hist2[^1], k) > 0: ex2.add(k)
  s.play(fadeOut(c1), fadeOut(c2), fadeOut(c3))
  c1 = caption("Preference ×4 lower...", 2.9, 0.42, WHITE)
  c2 = caption(&"...{ex2.len} exemplars", 2.3, 0.36, GOLD)
  for c in [c1, c2]:
    c.fillOpacity = 0; s.add(c)
  s.fadeAll(@[c1], 1.0)
  # recolor using new assignment
  proc cluster2(i: int): int =
    var best = -Inf
    for ci, k in ex2:
      if i == k: return ci
      if S2[i][k] > best: (best, result) = (S2[i][k], ci)
  var oldCol: seq[Color]
  var oldHalo: seq[float]
  for d in dots: oldCol.add(d.fillColor)
  for h in halos: oldHalo.add(h.strokeOpacity)
  let st2 = hist2[^1]
  s.tween(1.5, proc(t: float) =
    c2.fillOpacity = t
    for i in 0..<n:
      let col = PALETTE[cluster2(i) mod PALETTE.len]
      dots[i].fillColor = lerpColor(oldCol[i], col, t)
      dots[i].strokeColor = dots[i].fillColor
      let k = ex2[cluster2(i)]
      if k == i:
        cShafts[i].strokeOpacity = 0.75 * (1 - t)
        cHeads[i].fillOpacity = 0.75 * (1 - t); cHeads[i].strokeOpacity = cHeads[i].fillOpacity
      else:
        setArrow(cShafts[i], cHeads[i], pts[i], pts[k], 0.025, 0.75, col)
    for k in 0..<n:
      let isEx = k in ex2
      halos[k].strokeOpacity = oldHalo[k] + ((if isEx: 1.0 else: 0.0) - oldHalo[k]) * t
      if isEx:
        halos[k].strokeColor = PALETTE[ex2.find(k) mod PALETTE.len]
        halos[k].radius = PR + 0.35
  )
  discard st2
  s.wait(2.5)

  # --- Outro -------------------------------------------------------------
  var outs: seq[Animation]
  for m in s.mobjects:
    if m.kind != mkLine and m.kind != mkPolygon: outs.add(fadeOut(m, duration = 1.0))
  s.tween(1.0, proc(t: float) =
    for m in s.mobjects:
      if m.kind in {mkLine, mkPolygon}:
        m.strokeOpacity *= (1 - t); m.fillOpacity *= (1 - t))
  s.play(outs)
  let made = newText("made with nimanim", fontSize = 0.4, center = (0.0, 0.0), color = DIM)
  s.add(made)
  s.play(1.5, write(made))
  s.wait(1.0)

let scene = newScene(pixelWidth = 1280, pixelHeight = 720, fps = fps)
renderScene(scene, construct, "affinity_propagation.mp4")
