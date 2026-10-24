## appalette: color palettes of an image by affinity propagation.
##
## 1. `colorSet`: the image's pixels are binned (5 bits per RGB channel), and
##    the bins are cut into at most `maxColors` boxes by a variance-based
##    median cut in CIELAB. Each box is one color, with its pixel count.
## 2. `similarities`: s(i, k) = -w(i) * ΔE00(i, k), the CIEDE2000 difference
##    (chroma's `deltaE00`) weighted by w(i) = (count(i) / mean count)^alpha:
##    alpha = 1 weighs colors by their area, alpha = 0 counts every color once.
## 3. `sweep`: affinity propagation (naffprop's `ap.nim`) for preferences from
##    the one that gives a single exemplar up, until there are more than `kMax`
##    exemplars. Every run is a palette: its exemplars are colors of the image.
## 4. `stablePalettes`: the numbers of colors that persist over the widest
##    ranges of (log) preference, as the natural palettes of the image.
##
## Pure Nim, compiles to C and to JS (the in-browser demo).

import std/[math, algorithm]
import chroma
import ap

export ColorLAB, ColorRGB, Matrix, deltaE00

const
  binBits = 5
  binShift = 8 - binBits
  nBins* = 1 shl (3 * binBits)

type
  ColorSet* = object
    lab*: seq[ColorLAB]     ## one per color: the pixel-weighted mean of its box
    rgb*: seq[ColorRGB]
    count*: seq[int]        ## pixels of each color
    binColor*: seq[int32]   ## for each RGB bin (`binOf`), its color; -1 if no pixel

  Palette* = object
    preference*: float
    exemplars*: seq[int]    ## colors (indices in the ColorSet)
    labels*: seq[int]       ## for each color, the position of its exemplar
    iterations*: int
    converged*: bool
    netsim*: float

  StablePalette* = object
    k*: int                 ## number of colors
    palette*: int           ## index in the sweep of the run picked for this k
    first*, last*: int      ## runs (indices in the sweep) with k colors in a row
    width*: float           ## the range of log(-preference) they span

  ApParams* = object
    damping*: float
    convits*: int
    maxits*: int

func defaultApParams*(): ApParams = ApParams(damping: 0.9, convits: 30, maxits: 500)

func binOf*(r, g, b: int): int {.inline.} =
  (r shr binShift) shl (2 * binBits) or (g shr binShift) shl binBits or (b shr binShift)

proc toLab*(r, g, b: float): ColorLAB =
  ## sRGB in [0, 255] to CIELAB (D65), with chroma.
  rgb(uint8(clamp(r, 0, 255).round), uint8(clamp(g, 0, 255).round),
      uint8(clamp(b, 0, 255).round)).to(ColorLAB)

proc colorSet*(pixels: openArray[uint8], channels = 4, maxColors = 256): ColorSet =
  ## The colors of an image given as interleaved 8-bit pixels (RGB or RGBA;
  ## pixels with alpha < 128 are skipped).
  var
    cnt = newSeq[int](nBins)
    sums = newSeq[array[3, float]](nBins)
  var i = 0
  while i + channels <= pixels.len:
    if channels < 4 or pixels[i + 3] >= 128:
      let (r, g, b) = (pixels[i].int, pixels[i + 1].int, pixels[i + 2].int)
      let bin = binOf(r, g, b)
      inc cnt[bin]
      sums[bin][0] += r.float
      sums[bin][1] += g.float
      sums[bin][2] += b.float
    i += channels
  # The occupied bins, at the mean color of their pixels.
  var
    bins: seq[int]
    lab: seq[array[3, float]]
  for bin in 0 ..< nBins:
    if cnt[bin] > 0:
      let c = cnt[bin].float
      let l = toLab(sums[bin][0] / c, sums[bin][1] / c, sums[bin][2] / c)
      bins.add bin
      lab.add [l.l.float, l.a.float, l.b.float]

  # Median cut in Lab. A box is a range of `order`; the box to split next is
  # the one with the largest weighted squared error, with weights the square
  # root of the counts, so that small but distinct regions get their colors.
  type Box = object
    lo, hi: int        # order[lo ..< hi]
    sse: float
    dim: int           # dimension of largest spread
  var order = newSeq[int](bins.len)
  for j in 0 ..< order.len: order[j] = j
  proc weight(j: int): float = sqrt(cnt[bins[j]].float)
  proc measure(lo, hi: int): Box =
    result = Box(lo: lo, hi: hi)
    var w, m: array[3, float]
    var tot = 0.0
    for q in lo ..< hi:
      let j = order[q]
      tot += weight(j)
      for d in 0 .. 2: m[d] += weight(j) * lab[j][d]
    for d in 0 .. 2: m[d] /= tot
    for q in lo ..< hi:
      let j = order[q]
      for d in 0 .. 2: w[d] += weight(j) * (lab[j][d] - m[d]) ^ 2
    result.sse = w[0] + w[1] + w[2]
    result.dim = (if w[0] >= w[1] and w[0] >= w[2]: 0 elif w[1] >= w[2]: 1 else: 2)
  var boxes = @[measure(0, order.len)]
  while boxes.len < maxColors:
    var best = -1
    for q, b in boxes:
      if b.hi - b.lo > 1 and (best < 0 or b.sse > boxes[best].sse): best = q
    if best < 0 or boxes[best].sse <= 0: break
    let b = boxes[best]
    let d = b.dim
    order.toOpenArray(b.lo, b.hi - 1).sort(proc (x, y: int): int = cmp(lab[x][d], lab[y][d]))
    var tot = 0.0
    for q in b.lo ..< b.hi: tot += weight(order[q])
    var acc = 0.0
    var cut = b.hi - 1
    for q in b.lo ..< b.hi:
      acc += weight(order[q])
      if acc >= tot / 2:
        cut = q + 1
        break
    cut = clamp(cut, b.lo + 1, b.hi - 1)
    boxes[best] = measure(b.lo, cut)
    boxes.add measure(cut, b.hi)

  # One color per box, at the pixel-weighted mean of its bins.
  result.binColor = newSeq[int32](nBins)
  for x in result.binColor.mitems: x = -1
  boxes.sort(proc (x, y: Box): int = cmp(x.lo, y.lo))
  for c, b in boxes:
    var m: array[3, float]
    var tot = 0
    for q in b.lo ..< b.hi:
      let j = order[q]
      tot += cnt[bins[j]]
      for d in 0 .. 2: m[d] += cnt[bins[j]].float * lab[j][d]
      result.binColor[bins[j]] = int32(c)
    let l = ColorLAB(l: float32(m[0] / tot.float), a: float32(m[1] / tot.float),
                     b: float32(m[2] / tot.float))
    result.lab.add l
    result.rgb.add l.to(ColorRGB)
    result.count.add tot

proc similarities*(cs: ColorSet, alpha = 0.5): Matrix[float] =
  ## s(i, k) = -w(i) ΔE00(i, k), w(i) = (count(i) / mean count)^alpha; the
  ## diagonal is left 0 (the preferences go there).
  let n = cs.lab.len
  result = zeros[float](n)
  var mean = 0.0
  for c in cs.count: mean += c.float
  mean /= n.float
  for i in 0 ..< n:
    let w = pow(cs.count[i].float / mean, alpha)
    for k in 0 ..< n:
      if i != k:
        result[i, k] = -w * deltaE00(cs.lab[i], cs.lab[k]).float

proc copySims(s: Matrix[float]): Matrix[float] =
  result = zeros[float](s.n)
  for k in 0 ..< s.n * s.n: result.data[k] = s.data[k]

proc palette*(s: Matrix[float], preference: float,
              params = defaultApParams()): Palette =
  ## One run of affinity propagation with the same preference for every color.
  var m = copySims(s)
  let v = m.view
  v.setPreferences([preference])
  let r = affinityPropagation(v, params.maxits, params.convits, params.damping)
  Palette(preference: preference, exemplars: r.exemplars, labels: r.labels,
          iterations: r.iterations, converged: r.converged, netsim: r.netsim)

proc preferenceBounds*(s: Matrix[float]): (float, float) =
  ## naffprop's preference range: from 1-2 exemplars to every point.
  var m = copySims(s)
  preferenceRange(m.view)

proc sweep*(s: Matrix[float], kMax = 24, factor = 0.85,
            params = defaultApParams(),
            onPalette: proc (p: Palette) = nil): seq[Palette] =
  ## Runs from the preference of the lower bound of the preference range,
  ## multiplied by `factor` at every step (preferences are negative, so it
  ## grows towards 0), until a run has more than `kMax` exemplars.
  var p = preferenceBounds(s)[0]
  if p.isNaN or p >= 0: return
  for step in 0 ..< 400:
    let pal = palette(s, p, params)
    result.add pal
    if onPalette != nil: onPalette(pal)
    if pal.exemplars.len > kMax: break
    p *= factor

proc stablePalettes*(runs: openArray[Palette], minRuns = 2): seq[StablePalette] =
  ## Each maximal sequence of consecutive runs with the same number of colors
  ## k (at least `minRuns` runs, k >= 2), with the log-preference range it
  ## spans; when k comes back, the widest sequence is kept. Sorted by width,
  ## widest first. The run picked is the one with the best net similarity.
  var best: seq[StablePalette]
  var i = 0
  while i < runs.len:
    let k = runs[i].exemplars.len
    var j = i
    while j + 1 < runs.len and runs[j + 1].exemplars.len == k: inc j
    if k >= 2 and j - i + 1 >= minRuns:
      # half a step on each side, so a single run spans one step
      let lo = if i > 0: (ln(-runs[i - 1].preference) + ln(-runs[i].preference)) / 2
               else: ln(-runs[i].preference)
      let hi = if j + 1 < runs.len: (ln(-runs[j].preference) + ln(-runs[j + 1].preference)) / 2
               else: ln(-runs[j].preference)
      var pick = i
      for q in i .. j:
        if runs[q].netsim > runs[pick].netsim: pick = q
      let sp = StablePalette(k: k, palette: pick, first: i, last: j, width: abs(lo - hi))
      var found = false
      for b in best.mitems:
        if b.k == k:
          found = true
          if sp.width > b.width: b = sp
      if not found: best.add sp
    i = j + 1
  best.sort(proc (x, y: StablePalette): int = cmp(y.width, x.width))
  best

proc keepWeights*(cs: ColorSet, pal: Palette, keep: openArray[bool],
                  softness = 0.0): seq[float] =
  ## How much of its color each color of `cs` keeps (1) or loses to gray (0),
  ## when only the clusters of the exemplars with `keep[e]` keep their colors.
  ## With softness 0 it is the cluster of the color; with softness > 0 (in ΔE00
  ## units) colors near the border between a kept and a grayed cluster are
  ## blended: a logistic of (ΔE to the nearest grayed exemplar - ΔE to the
  ## nearest kept one) / softness.
  result = newSeq[float](cs.lab.len)
  var anyKept = false
  var allKept = true
  for e in 0 ..< pal.exemplars.len:
    if e < keep.len and keep[e]: anyKept = true
    else: allKept = false
  for c in 0 ..< cs.lab.len:
    let e = pal.labels[c]
    let inKept = e >= 0 and e < keep.len and keep[e]
    if softness <= 0 or not anyKept or allKept:
      result[c] = (if inKept: 1.0 else: 0.0)
      continue
    var dKept, dGray = Inf
    for q, x in pal.exemplars:
      let d = deltaE00(cs.lab[c], cs.lab[x]).float
      if q < keep.len and keep[q]: dKept = min(dKept, d)
      else: dGray = min(dGray, d)
    result[c] = 1 / (1 + exp(-(dGray - dKept) / softness))

proc linear(v: int): float =
  let x = v.float / 255
  if x <= 0.04045: x / 12.92 else: pow((x + 0.055) / 1.055, 2.4)

proc encode(y: float): uint8 =
  let x = if y <= 0.0031308: 12.92 * y else: 1.055 * pow(y, 1 / 2.4) - 0.055
  uint8(clamp(x * 255, 0, 255).round)

var linearLut: seq[float]

proc colorSplash*(pixels: openArray[uint8], channels: int, cs: ColorSet,
                  weights: openArray[float], output: var openArray[uint8]) =
  ## Writes into `output` (RGBA) the image with every pixel blended between
  ## its color and its gray (same luminance) by the weight of its color
  ## (`keepWeights`).
  if linearLut.len == 0:
    for v in 0 .. 255: linearLut.add linear(v)
  var i, o = 0
  while i + channels <= pixels.len:
    let (r, g, b) = (pixels[i].int, pixels[i + 1].int, pixels[i + 2].int)
    let c = cs.binColor[binOf(r, g, b)]
    let m = if c >= 0: weights[c] else: 0.0
    if m >= 1:
      output[o] = uint8(r); output[o + 1] = uint8(g); output[o + 2] = uint8(b)
    else:
      let gray = encode(0.2126 * linearLut[r] + 0.7152 * linearLut[g] +
                        0.0722 * linearLut[b]).float
      output[o] = uint8(round(m * r.float + (1 - m) * gray))
      output[o + 1] = uint8(round(m * g.float + (1 - m) * gray))
      output[o + 2] = uint8(round(m * b.float + (1 - m) * gray))
    output[o + 3] = (if channels == 4: pixels[i + 3] else: 255)
    i += channels
    o += 4

func hex*(c: ColorRGB): string =
  const digits = "0123456789abcdef"
  result = "#"
  for v in [c.r, c.g, c.b]:
    result.add digits[v.int shr 4]
    result.add digits[v.int and 15]
