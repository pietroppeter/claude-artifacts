import nimib, std/[os, strformat]

nbInit
nb.title = "Affinity Propagation, animated with nimanim"
# write the page next to src/, wherever the build is run from
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"

nbText: """
# Affinity Propagation, animated with nimanim

[nimanim](https://github.com/himanshm/nimanim) is a young, manim-inspired 2D animation
library for Nim: Cairo draws the frames, ffmpeg encodes them. To give it a dry run,
I used it to explain [affinity propagation](https://en.wikipedia.org/wiki/Affinity_propagation),
the clustering algorithm where points pass messages to each other until a few of them
emerge as *exemplars*, and the number of clusters is not fixed in advance.

This page is a [nimib](https://github.com/pietroppeter/nimib) document: the code blocks
below run when the page is built, and their output is shown under them.
"""

nbRawHtml: """
<video controls preload="metadata" poster="poster.jpg" style="width:100%;border-radius:6px"
  src="affinity_propagation.mp4">
  Your browser does not play MP4: <a href="affinity_propagation.mp4">download the video</a>.
</video>
<p class="nb-small">59 seconds, 1280×720, rendered by nimanim in about 16 seconds.
Source: <a href="src/scene.nim">src/scene.nim</a>.</p>
"""

nbText: """
## The algorithm in a few lines of Nim

Same 14 points as in the video: three groups, upper left, lower left and middle.
"""

nbCode:
  type
    Point = tuple[x, y: float]
    Mat = seq[seq[float]]

  let pts: seq[Point] = @[
    (-5.6, 1.9), (-4.9, 2.5), (-4.6, 1.6), (-5.3, 1.1), (-4.1, 2.2),
    (-5.0, -1.6), (-4.3, -2.3), (-5.6, -2.4), (-4.4, -1.3),
    (-1.9, 0.1), (-1.2, 0.7), (-1.5, -0.6), (-0.7, -0.1), (-2.2, 0.9)]
  let n = pts.len

  proc zeros(n: int): Mat =
    for i in 0 ..< n: result.add newSeq[float](n)

nbText: """
**Similarity** is the negative squared distance. The diagonal `s(k,k)` is the
*preference*: how much each point wants to be an exemplar. A common default is the
median of the other similarities.
"""

nbCode:
  import std/algorithm

  proc similarity(pref: float): Mat =
    result = zeros(n)
    for i in 0 ..< n:
      for k in 0 ..< n:
        let (dx, dy) = (pts[i].x - pts[k].x, pts[i].y - pts[k].y)
        result[i][k] = if i == k: pref else: -(dx*dx + dy*dy)

  var offDiag: seq[float]
  let s0 = similarity(0.0)
  for i in 0 ..< n:
    for k in 0 ..< n:
      if i != k: offDiag.add s0[i][k]
  offDiag.sort()
  let median = offDiag[offDiag.len div 2]
  echo &"median similarity: {median:.2f}"

nbText: """
Then two kinds of messages go back and forth, with damping so they settle smoothly:

- **responsibility** `r(i,k)`, sent from `i` to `k`: how well `k` suits `i` as an
  exemplar, compared with `i`'s best alternative;
- **availability** `a(i,k)`, sent from `k` to `i`: how much support `k` already has from
  other points for being an exemplar.

A point is an exemplar when `r(k,k) + a(k,k) > 0`. Each other point joins the exemplar
most similar to it.
"""

nbCode:
  proc affinityPropagation(S: Mat, iters = 200, damping = 0.8): seq[int] =
    var R = zeros(n)
    var A = zeros(n)
    for _ in 1 .. iters:
      for i in 0 ..< n:
        for k in 0 ..< n:
          var best = -Inf
          for k2 in 0 ..< n:
            if k2 != k: best = max(best, A[i][k2] + S[i][k2])
          R[i][k] = damping * R[i][k] + (1 - damping) * (S[i][k] - best)
      for i in 0 ..< n:
        for k in 0 ..< n:
          var support = 0.0
          for i2 in 0 ..< n:
            if i2 != i and i2 != k: support += max(0.0, R[i2][k])
          let a = if i == k: support else: min(0.0, R[k][k] + support)
          A[i][k] = damping * A[i][k] + (1 - damping) * a
    for k in 0 ..< n:
      if R[k][k] + A[k][k] > 0: result.add k

  proc assign(S: Mat, exemplars: seq[int]): seq[int] =
    for i in 0 ..< n:
      if i in exemplars:
        result.add i
        continue
      var (best, choice) = (-Inf, -1)
      for e in exemplars:
        if S[i][e] > best: (best, choice) = (S[i][e], e)
      result.add choice

  let S = similarity(median)
  let exemplars = affinityPropagation(S)
  echo "exemplars: ", exemplars
  echo "cluster of each point: ", assign(S, exemplars)

nbText: """
Three exemplars (points 2, 5 and 9), one per group, and nobody told the algorithm there were three.
The preference is the knob that controls how many clusters come out: raise it and
more points want to be exemplars, lower it and fewer can afford to be. That is the bonus scene at the end of the video.
"""

nbCode:
  for factor in [0.05, 0.1, 0.25, 1.0, 4.0, 8.0]:
    let ex = affinityPropagation(similarity(factor * median))
    let word = if ex.len == 1: "exemplar " else: "exemplars"
    echo &"preference = {factor:>4} × median → {ex.len} {word} {ex}"

nbText: """
## How the animation was made

nimanim has shapes, text, easing functions and manim-style `play` / `wait`, but no
updaters (`ValueTracker`, `add_updater`) and no arrows. Two things made it workable anyway:
every mobject field is public, and `scene.wait(1/fps)` renders exactly one frame.
So a homemade updater is five lines:
"""

nbCodeSkip:
  proc tween(s: Scene, duration: float, body: proc(t: float),
             easing: EasingFunc = smoothstep) =
    let frames = max(1, int(duration * fps.float + 0.5))
    for f in 1..frames:
      body(easing(f / frames))
      s.wait(1.0 / fps.float)

nbText: """
The message passing section runs the algorithm for 40 iterations and, for each one,
tweens from one state to the next: an arrow from every point to its current favourite
exemplar (`argmax a(i,k) + r(i,k)`) and a gold ring whose size follows the exemplar
evidence `r(k,k) + a(k,k)`. Arrows are a line plus a triangle, rebuilt every frame.
"""

nbCodeSkip:
  for it in 0 ..< 40:
    let a = hist[it]
    let b = hist[it + 1]
    iterText.text = &"iteration {it + 1}"
    s.tween(0.3, proc(t: float) =
      showState(Snapshot(R: lerpMat(a.R, b.R, t), A: lerpMat(a.A, b.A, t))),
      linear)

nbText: """
The full scene is [src/scene.nim](src/scene.nim) (about 500 lines, most of them captions).

## nimanim: notes from the dry run

Tried at commit [`378a459`](https://github.com/himanshm/nimanim/commit/378a4596c630b24d7f9a68c426261e76744fccd4) (v1.3.0).

**What works well**

- The core loop is small and fast: the 59 second video renders in about 16 seconds.
- Circles, lines, polygons, text, easing, `fadeOut`, `scaleTo`, `moveTo` on simple shapes.
- Unicode in text (‖x‖², ≠, Σ, primes) is enough for simple formulas.
- Being able to change anything between frames makes up for the missing features.

**Bugs found**

1. **`write()` showed nothing, then the text popped in at the end.** This is the README's
   headline feature (stroke-by-stroke tracing). In `font.nim` the struct used to walk
   Cairo's path is 24 bytes, while `cairo_path_data_t` is a 16-byte union, so the walk
   reads garbage. Removing one padding field fixes it:
   [patch](src/patches/nimanim-write-fix.patch). The video was rendered with the fix.
   Text `transform()` uses the same code, so it was probably affected too.
2. **Animated `shiftBy` / `moveTo` don't move lines or groups.** The animation only moves
   `center`, but lines are drawn from their endpoints and groups from their children.
   (The instant `shift()` handles both.)
3. **Animations on a group don't reach its children** (fade, scale, rotate).
4. **`fadeIn` and `create` can't fade in a hidden object**: they animate from 0 to the
   *current* opacity, so the object must be added at full opacity.
5. **`newLatex` is hard to use on a dark background**: it needs `texlive-latex-extra`
   (for `standalone.cls`), renders black, and its `color` argument does nothing.
6. Smaller things: no `duration =` on `play` (it's a positional first argument), and
   `FontWeight` needs `import cairo` because nimanim doesn't re-export it.

**Missing compared with manim**: arrows, updaters, `lag_ratio` / animation groups,
color-change animations, text alignment.

## Rebuild

With Nim (1.6 or later), Cairo, FreeType and ffmpeg installed:

```sh
cd nimanim-affinity
sh src/deps.sh                      # pinned deps into src/deps, patches nimanim
nim c -r -d:release src/scene.nim   # affinity_propagation.mp4
nim c -r src/index.nim              # index.html (this page)
```
"""

nbSave
