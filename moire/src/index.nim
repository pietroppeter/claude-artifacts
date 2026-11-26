## Moiré, explained with things to drag: two gratings, beats, turns, the lever, rings,
## aliasing, and a toy Mer de Glace. Every widget is Nim compiled to JavaScript (lib/widgets.nim)
## and uses the same formulas (lib/moiremath.nim) the code blocks below run at build time.
## Build: sh deps.sh && nim r index.nim   (from this folder; writes ../index.html)
import std/[strformat, os, math]
import nimib
import tabelline, tabelline/nimib
import lib/[blocks, moiremath]
import lib/style as pagestyle   # (as: tabelline exports a `style` too)
import review   # tabelline's review mode, from shared/review at the root of this repository (config.nims)

let here = currentSourcePath().parentDir

nbInit
nb.doc.filename = here.parentDir / "index.html"
nb.title = "Moiré: when two patterns make a third"
nb.useMoireStyle
nbReview(tpage = "moire", tsource = "moire/src/index.nim")

const
  inspiration = "https://notebook.link/@arjxn-py/mer-de-glace-story"
  wikiMoire = "https://en.wikipedia.org/wiki/Moir%C3%A9_pattern"
  wikiForbes = "https://en.wikipedia.org/wiki/James_David_Forbes"
  wikiMer = "https://en.wikipedia.org/wiki/Mer_de_Glace"
  wikiVernier = "https://en.wikipedia.org/wiki/Vernier_scale"
  wikiInsar = "https://en.wikipedia.org/wiki/Interferometric_synthetic-aperture_radar"
  wikiTbg = "https://en.wikipedia.org/wiki/Twisted_bilayer_graphene"
  wikiGlen = "https://en.wikipedia.org/wiki/Glen%27s_flow_law"
  wikiAlias = "https://en.wikipedia.org/wiki/Aliasing"
  wikiZone = "https://en.wikipedia.org/wiki/Zone_plate"
  srcDir = "https://github.com/pietroppeter/claude-artifacts/tree/main/moire/src"

nbText: &"""
# Moiré: when <em>two</em> patterns make a third
"""

nbLede: """
Lay one striped sheet over another and a third pattern appears that neither sheet has: broad,
slow, ghostly bands. That is a **moiré**. It is a nuisance when you photograph a screen, and a
superpower when you want to see a movement far too small to see: slide one sheet by a hair and
the bands sweep by a hand's width.

Everything below is for your finger. Drag, slide, tap.
"""

nbWidget("hero", 0.8, "two fine line gratings, one turned by a few degrees, making broad bands",
  [slider("hero-a", "Turn", 0, 20, 0.1, 6), button("hero-play", "▶ Drift")],
  tdrag = "x", thint = "Drag the picture sideways to slide the top sheet.",
  tcaption = "Two sheets of lines 6 units apart, the blue one turned. Each line is thin; the dark bands are not lines at all, they are where the two sheets' lines fall *between* each other.")

nbText: &"""
The word is French: *moiré* is watered silk, a fabric pressed in two folded layers so that their
threads beat against each other and leave a shimmering, wood-grain look. The physics is the same
in every case below: two regular patterns, almost but not quite alike, and an eye (or a camera,
or a sensor) that cannot see the fine detail and sees only the slow difference.

## Two rhythms, one beat

Start with the simplest case: two sets of parallel lines, the same orientation, slightly
different spacing. Where the lines coincide, light gets through the gaps of both sheets; half
a beat later each sheet's lines fill the other's gaps, and the overlap goes dark.

It is the visual twin of two guitar strings slightly out of tune: two notes of 440 and 442 Hz
throb twice a second. Here, frequency is lines per unit of length.
"""

nbWidget("beat", 0.72, "grating A, grating B, their overlap, and the overlap blurred",
  [slider("beat-p1", "Period A", 4, 14, 0.1, 8), slider("beat-p2", "Period B", 4, 14, 0.1, 9)],
  tcaption = "Top to bottom: sheet A, sheet B, the two overlapped, and what is left when you blur the overlap over one line spacing (squint at your phone, or hold it far away). The blur keeps the beat and throws away the lines.")

nbFormula("<i>P</i> = <i>p</i><sub>1</sub> <i>p</i><sub>2</sub> / |<i>p</i><sub>1</sub> − <i>p</i><sub>2</sub>|",
  "the fringe period: 1/P is the difference of the two line frequencies 1/p₁ − 1/p₂")

nbText: """
That formula is in `lib/moiremath.nim`, the one Nim module that both this page (when it was
built) and the widgets (in your browser) use:
"""

nbCode:
  echo moirePeriod(8, 9)       # the widget's starting point
  echo moirePeriod(8, 8.5)     # closer periods: wider fringes
  echo moirePeriod(8, 8.1)     # 1% apart: the beat is 81 lines long

nbNote(nkIdea, """
Multiply two waves and you get their sum frequency and their difference frequency. The sum is
even finer than the lines, so your eye blurs it away; the difference is coarse, and that is
what you see. Moiré is the difference frequency, made visible.
""")

nbText: """
## Turn one sheet

Now take two *identical* sheets and turn one of them. At zero degrees nothing happens; a
small turn makes huge fringes, running almost at right angles to the lines; the more you
turn, the finer they get.
"""

nbWidget("turn", 0.8, "two identical gratings, one rotated, with fringes across them",
  [slider("turn-a", "Angle", 0.3, 30, 0.1, 5)],
  tcaption = "Lines 5 units apart. The fringes run along the bisector of the two sets of lines, so they look almost perpendicular to them for small angles.")

nbFormula("<i>P</i> = <i>p</i> / (2 sin(<i>θ</i>/2)) ≈ <i>p</i> / <i>θ</i>",
  "small angles: one degree turns a grating into fringes about 57 times wider")

nbCode:
  for deg in [0.5, 1.0, 2.0, 5.0, 10.0, 30.0]:
    echo &"{deg:>4}°  fringes {rotationPeriod(1, degToRad(deg)):6.1f} times the line spacing"

let tbgPeriod = rotationPeriod(0.246, degToRad(1.1))
nbText: &"""
The same formula, at the scale of atoms, is one of the big stories of recent physics. Graphene
is a single sheet of carbon atoms in a honeycomb with a spacing of 0.246 nm. Stack two sheets
and twist one by about 1.1°, the "magic angle", and the moiré of the two lattices is a new,
much larger lattice about **{tbgPeriod:.1f} nm** across. Electrons feel it, and in 2018 the
twisted pair turned out to be a superconductor ([twisted bilayer graphene]({wikiTbg})).

## The lever: see a movement twenty times bigger

Here is the trick that makes moiré useful. Take two sheets with periods 8 and 8.4, and slide
the top one by a small amount *d*. The fringes do not move by *d*: they move by
*d* · p₁/(p₁ − p₂), here {abs(magnification(8, 8.4)):.0f} times as far, and the other way.
"""

nbWidget("lever", 0.62, "a sliding grating with a red pointer, and the overlap whose fringe pointer moves twenty times as far",
  [slider("lever-d", "Slide", 0, 8.4, 0.05, 0)],
  tcaption = "Top: the sliding sheet alone, its red pointer moving with it. Below: the overlap, with a red pointer that follows one bright fringe. Slide by one line spacing (8.4) and the fringe pattern moves by a whole fringe (168).")

nbText: &"""
That is a lever with no moving parts, and no friction. You have seen it before on a caliper: a
[vernier scale]({wikiVernier}) puts 10 marks over the length of 9 main-scale marks, and the
mark that lines up tells you the tenth of a millimetre. A vernier is a one-dimensional moiré,
read by eye.
"""

nbCode:
  echo magnification(1.0, 0.9)    # a caliper's vernier: 10 vernier marks in 9 mm
  echo magnification(8, 8.4)      # the widget above

nbText: """
## Rings, rays and lines

Moiré is not only about straight lines. Any two regular patterns will do, and the fringes draw
the curves along which the two patterns are "in step". Two sets of circles make hyperbolas
and ellipses; circles over lines make parabolas; two sets of rays make circles.
"""

nbWidget("rings", 1.0, "two ring patterns; the second one follows your finger",
  [toggle("rings-0", "Rings + rings", true), toggle("rings-1", "Rings + lines"), toggle("rings-2", "Rays + rays")],
  tdrag = "xy", thint = "Touch and drag on the picture to move the blue pattern.",
  tcaption = "Each fringe is a curve where the two patterns are a whole number of periods apart, like the contour lines of a map.")

let nyquistR = proc (blk: float): float = 130 / blk
nbText: &"""
## Aliasing: the moiré inside your camera

A screen, a camera sensor and this very page are grids too: rows of pixels. Draw a pattern
finer than the pixels and the pixel grid beats against it exactly like a second sheet. Signal
processing calls it [aliasing]({wikiAlias}): a fine pattern, sampled too coarsely, pretends to
be a coarse one.

The picture below is a [zone plate]({wikiZone}): rings that get finer and finer away from the
centre. Make the pixels bigger and watch rings appear that are not in the picture. Then switch
to averaging, which is what an anti-aliasing filter (or a camera's slightly blurry optical
low-pass filter) does: the ghosts fade to grey instead.
"""

nbWidget("alias", 1.0, "a zone plate drawn with big pixels, with ghost rings",
  [slider("alias-b", "Pixel size", 1, 8, 0.5, 3), toggle("alias-smooth", "Sampling each pixel's centre")],
  tcaption = "The rings' spacing shrinks as you go out; once it is less than two pixels, each pixel lands on a different part of the next ring, and new false rings appear around new centres.")

nbText: "Where do the ghosts start? Where a ring is less than two pixels wide (the Nyquist limit):"

nbCode:
  # the zone plate is cos(π r² / 260): at radius r it has r / 260 rings per unit
  for pixel in [1.0, 2.0, 3.0, 5.0, 8.0]:
    echo &"pixels of {pixel} units: rings alias beyond r = {nyquistR(pixel):5.1f}"

nbText: &"""
## A glacier in stripes

In the summer of 1842, [James David Forbes]({wikiForbes}) planted a line of marks straight
across the [Mer de Glace]({wikiMer}), the great glacier under Mont Blanc, and came back to
survey them again and again. The line did not stay straight. It bowed downstream: the ice in
the middle of the glacier flows faster than the ice by the rock walls, which drags along them.

Moiré turns that one survey line into a whole map. Paint a grating of lines across the ice
(the black sheet, "before"), let the glacier carry it (the blue sheet, "after"), and lay the
two over each other. Wherever the ice has moved by exactly one line spacing, the two sheets
line up again: each fringe is a **contour of equal movement**.
"""

nbWidget("glacier", 0.85, "a toy glacier between grey rock walls, with a grating painted across it, before and after it flowed",
  [slider("glacier-t", "Time", 0, 24, 0.1, 12), toggle("glacier-0", "Both", true), toggle("glacier-1", "Before"),
   toggle("glacier-2", "After")],
  tcaption = "A toy valley glacier seen from above, flowing to the right and speeding up downstream. Each fringe is a line of equal movement: count them from a wall to the middle to read how many line spacings the ice there has moved. Tap After to see the painted lines bow, as Forbes saw.")

nbText: &"""
The flow across the valley here is a toy, but a reasonable one: speed
u(y) = u<sub>max</sub> (1 − |y/W|<sup>4</sup>), the shape that [Glen's flow law]({wikiGlen})
(ice as a fluid that softens under stress, exponent n ≈ 3) gives a glacier that hardly slides
on its bed. The widget uses a gentler parabola instead, 1 − |y/W|², the shape for a runny,
honey-like fluid (n = 1): real ice is flatter in the middle and shears in a narrow band by the
walls, which would squeeze all the fringes against the rock.
"""

nbCode:
  for y in [0.0, 0.25, 0.5, 0.75, 0.9, 1.0]:
    echo &"{y:4.2f} of the way to the wall: {flow(y, 1, 100):5.1f}% of the centre's speed"

let sentinelFringe = insarFringe(5.55)
nbText: &"""
Real glaciers are mapped the same way, with more sophisticated sheets. Satellites compare two
images of the ice taken days apart: optical images by matching patches of texture (feature
tracking, image correlation), radar images by their phase. In
[radar interferometry]({wikiInsar}) the two radar waves themselves are the gratings, and the
interferogram is a moiré made of rainbow fringes: with the C-band radar of the Sentinel-1
satellites (wavelength 5.55 cm), each fringe is **{sentinelFringe:.2f} cm** of movement toward or
away from the satellite.

## Where moiré is at work

A few of the places where two patterns slightly out of step are a tool, or a problem:
"""

var uses: seq[tuple[where, what, kind: string]] = @[
  ("Calipers and micrometers", "The vernier scale: 10 marks over 9 make a 10× lever, read by eye.", "measure"),
  ("Linear and rotary encoders", "Two fine gratings, one on the moving part: a photodiode counts the fringes as they pass.", "measure"),
  ("Strain measurement", "A fine grating bonded to a part; under load it stretches, and its moiré with a reference grating maps the strain (moiré interferometry, around a thousand lines per millimetre).", "measure"),
  ("Shadow moiré", "A grating and its own shadow on a curved surface: the fringes are contour lines of height (used to map the shape of a back, a car panel, a wafer).", "measure"),
  ("Glaciers and earthquakes", "Radar interferograms: each fringe is half a radar wavelength of ground or ice motion.", "measure"),
  ("Twisted materials", "Two atom-thin lattices twisted by a degree make a moiré superlattice that changes how electrons behave.", "physics"),
  ("Chip lithography", "Alignment marks: two gratings, on the mask and on the wafer, show tiny misalignments as large fringe shifts.", "measure"),
  ("Colour printing", "The four ink screens are set at different angles (often 15°, 75°, 0° and 45°) so their moiré is a fine, even rosette, not bands.", "nuisance"),
  ("Photos of screens", "The sensor's pixel grid beats with the screen's: rainbow ripples. Cameras add a low-pass filter, or rely on very small pixels.", "nuisance"),
  ("Banknotes", "Fine line patterns that make moiré when a scanner or copier resamples them.", "security"),
  ("Fabric", "Watered silk (moiré): two layers pressed together, their threads beating.", "craft"),
]
let usesTable = tabella(uses):
  optCssTheme()
  optRowStriping()
  tabHeader "Moiré at work", "two patterns slightly out of step"
  colsLabel {"where": "Where", "what": "What the two patterns are", "kind": "As a"}
nbTable usesTable

nbNote(nkCareful, &"""
The glacier widget is a toy: a straight valley, a made-up speed, no ice thinning. Forbes's
survey and the shape of the flow are real; the numbers are not the Mer de Glace's. This page
was inspired by a [notebook about the Mer de Glace]({inspiration}) by arjxn-py.
""")

nbText: &"""
## How this page is made

A [nimib](https://github.com/pietroppeter/nimib) document. Each widget is a canvas computed pixel
by pixel, at your screen's resolution, by Nim compiled to JavaScript (`lib/widgets.nim`, with
`nim js` when the page is built); both the widgets and the code blocks above call the same
`lib/moiremath.nim`. The table is made with [tabelline](https://pietroppeter.github.io/tabelline/).
The lines are drawn with slightly soft edges, otherwise your screen's own pixel grid would add a
moiré of its own. The sources are [on GitHub]({srcDir}).
"""

nbNote(nkNim, """
The widgets use only `std/dom` and a handful of `importjs` procs for the canvas (getContext,
createImageData, putImageData). The colours come from the CSS custom properties of
`lib/style.nim`, read once at start, so the canvases and the page share one palette.
""")

for f in ["lib/moiremath.nim", "lib/widgets.nim", "index.nim", "lib/blocks.nim", "lib/style.nim", "config.nims", "deps.sh"]:
  nbFile f, folded = true

nbScript compileWidgets(here / "lib" / "widgets.nim", getTempDir() / "moire-build")

nbSave
