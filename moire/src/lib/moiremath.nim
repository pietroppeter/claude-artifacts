## The few formulas of moiré, in plain Nim. The page runs them when it is built (the numbers
## in the text and tables) and the widgets run the very same procs in the browser (`nim js`).
import std/math

func moirePeriod*(p1, p2: float): float =
  ## Two parallel gratings of periods p1 and p2 beat with period p1·p2/|p1−p2|
  ## (the difference of their spatial frequencies 1/p1 − 1/p2). Equal periods: no fringes (inf).
  if p1 == p2: Inf else: p1 * p2 / abs(p1 - p2)

func rotationPeriod*(p, theta: float): float =
  ## Two identical gratings of period p, one turned by theta radians: fringes p / (2·sin(θ/2)),
  ## roughly p/θ for small angles.
  if theta == 0: Inf else: p / (2 * sin(abs(theta) / 2))

func magnification*(p1, p2: float): float =
  ## Slide the grating of period p2 by d: the fringes move by d·p1/(p1 − p2) (signed).
  ## A lever with no moving parts: the vernier of a caliper is the same idea.
  if p1 == p2: Inf else: p1 / (p1 - p2)

func grating*(u, p: float; duty = 0.5; soft = 0.0): float =
  ## Transmission (1 clear, 0 ink) at position u of a line grating of period p. `duty` is the
  ## clear fraction; `soft` (same units as u) blurs the edges so the screen itself does not alias.
  let x = u - p * floor(u / p)             # where we are inside one period, 0 ≤ x < p
  let h = duty * p / 2                      # half the clear part, centred at h
  var d = abs(x - h)
  d = min(d, p - d)                         # distance from the centre of the nearest clear part
  if soft <= 0: (if d < h: 1.0 else: 0.0)
  else: clamp((h - d) / soft + 0.5, 0.0, 1.0)

func flow*(y, halfWidth, uMax: float; n = 3.0): float =
  ## A toy glacier: surface speed across the valley, fastest in the middle (y = 0), still at the
  ## walls (|y| = halfWidth). n ≈ 3 is the shape Glen's flow law gives a glacier sliding little.
  let s = clamp(abs(y) / halfWidth, 0.0, 1.0)
  uMax * (1 - pow(s, n + 1))

func insarFringe*(wavelength: float): float =
  ## Radar interferometry: one fringe (a full colour cycle) is half the radar wavelength of
  ## movement toward or away from the satellite (the signal goes there and back).
  wavelength / 2
