## Research explainer: how things move on the web and in games, how parloku moves today, and which
## approaches to try as Nim proofs of concept (for zogyn and parloku). Writes ../index.html.
## Blocks in nbCodeAnd(nbJsFromCode) run at build time (their outputs) and in the browser (the demos).
import std/[os, math, strutils, strformat]
import nimib
import style, review

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.usePage("Animating things, in Nim",
           "Research for zogyn and parloku: how parloku moves today, tweens, springs, timelines and declarative animation, the libraries and the people, and a shortlist for Nim proofs of concept.")
nbReview(tversion = 1, tpage = "animating-in-nim", tsource = "animating-in-nim/src/index.nim")

nbTitle "11 November 2026 · research", "Animating things, <em>in Nim</em>", """
How parloku moves today, how animation is done on the web and in games (tweens, springs,
timelines, physics), whether there is a *declarative dragging* of animation, who the people
are, and four approaches worth a Nim proof of concept. The demos are Nim compiled to JavaScript.
"""
nbVersion 1

nbNote """
**The short answer.** Every animation library is built from a few small pieces: an **easing
curve**, a **tween** (from, to, how long), a **spring** (a target and how bouncy), and a way to
**compose** them in time (sequence, parallel, stagger). The declarative step is the one zogyn
already half has: *render each state, and let the animator move every keyed thing from where it
was to where it is now*. Nim has nothing maintained for this on the web, so a small library is a
real gap, and the pieces fit in a few hundred lines. [Shortlist](#a-shortlist-for-nim-proofs-of-concept) at the end.
"""

nbText: """
## How parloku moves today

I read `src/parloku.nim`, `src/style.nim`, zogyn's `stage.nim` and the garden post on dividing
cells. Seven different techniques, each with its own clock:

| What moves | How it is done | Where |
|---|---|---|
| A tile glides to its new place on release | CSS `transition: transform .34s cubic-bezier(.2,.9,.25,1)` on every `.item`: zogyn's stage keeps one `<g>` per key and only changes its `transform` | zogyn `stage.nim`, parloku `style.nim` |
| Letters in conflict roll like marbles | a `requestAnimationFrame` loop sets an SVG `transform` every frame: `dx = 4·k·sin(2π·2.2·t)`, a turn of `dx / r`, and `k` grows over 3 s | `roll` in `parloku.nim` |
| The two balls: a copy pulled off its letter | geometry, not animation: every pointer move redraws a path of two circles and a neck whose waist shrinks with the distance, until it splits | `neckPath`, `waist` in `parloku.nim`; `devlog_cells.nim` |
| The letter left behind wobbles | a damped sine written by hand, `1 + amp·exp(−dt/140)·sin(dt/26)` (garden post), and a CSS ripple keyframe (game) | `spring` in `devlog_cells.nim`; `.ripple` in `style.nim` |
| The win dances 🌊 🐍 🪀 | a `requestAnimationFrame` loop: each tile's transform is a function of the time since the win, made of windows `hop = sin(π·u)` staggered by word and by letter | `celebrate` and `dance` in `parloku.nim` |
| Confetti, pulse, wiggle, the banner | CSS `@keyframes`, one custom property per piece of confetti | `style.nim` |
| The menu slides up and down | the Web Animations API, `element.animate(keyframes, {duration, delay, easing})`, from an `importjs` | `slideY`, `slideX` in `parloku.nim` |

What this says:

- **The dances are already the cleanest kind of animation**: a pure function of time. Nothing is
  stored; scrub the time and you get the frame. That is a *timeline*, written by hand.
- **The wobble is a spring written by hand.** A spring simulated with two numbers (stiffness and
  damping, or Apple's *duration* and *bounce*) gives the same look, and it can be interrupted.
- **The glide is declarative already**: zogyn changes the state, the browser moves each keyed
  `<g>`. But a CSS transition can't be bent: no springs, no stagger, and a tile caught halfway
  restarts with a jolt.
- **Safari decided some of it**: Safari does not re-read `var()` inside `@keyframes`, so anything
  that changes over time is an SVG transform set from a frame loop (the rule in this project).
- Each one writes its own time, its own easing and its own *when do I stop*, and reduced motion is
  checked in some places. A framework would give these one vocabulary.
"""

nbText: """
## The building blocks

### 1 · Easing: how time is bent

A move from `a` to `b` has a *progress* `u` going from 0 to 1. An easing curve bends `u` before
mixing: slow out, fast in, a little past the end and back. The names every library uses
(`easeInOutCubic`, `easeOutBack`, `easeOutElastic`) are **Robert Penner's**, from his 2001 book
for Flash; CSS's `cubic-bezier(...)` is the same idea as four numbers.
"""

nbCodeAnd(nbJsFromCode):
  type Ease = proc (u: float): float {.nimcall.}

  func mix(a, b, u: float): float = a + (b - a) * u

  func linear(u: float): float = u
  func easeInOutCubic(u: float): float =
    if u < 0.5: result = 4 * u * u * u
    else: result = 1 - pow(-2 * u + 2, 3) / 2
  func easeOutBack(u: float): float =      # goes 10% past the end, comes back
    const c1 = 1.70158
    result = 1 + (c1 + 1) * pow(u - 1, 3) + c1 * pow(u - 1, 2)

nbText: "Sampled at build time, every tenth of the way (the bar is the value):"
nbCode:
  for (name, ease) in [("linear", Ease(linear)), ("easeInOutCubic", easeInOutCubic), ("easeOutBack", easeOutBack)]:
    echo name
    for i in 0 .. 10:
      let v = ease(i / 10)
      echo &"  u={i / 10:.1f} {v:5.2f} " & "█".repeat(int(v * 24))

nbText: """
### 2 · Tweens: from, to, how long

A *tween* (from *in-between*, the drawings an assistant animator made between two key poses) is
the smallest animation: a start time, a duration, two values and an easing. Asked for its value at
time `t`, it answers; nothing else is needed.
"""

nbCodeAnd(nbJsFromCode):
  type Tween = object
    a, b: float          # from, to
    start, dur: float    # ms
    ease: Ease

  proc at(tw: Tween, t: float): float =
    let u = clamp((t - tw.start) / tw.dur, 0.0, 1.0)
    result = mix(tw.a, tw.b, tw.ease(u))

nbText: """
### 3 · Springs: a target, not a duration

A spring has no duration. It has a position, a speed and a **target**, and every frame it is
pulled towards the target and slowed by friction. Change the target halfway and it simply bends
towards the new one, keeping its speed: that is why springs feel right under a finger and why
Motion, react-spring, SwiftUI and iOS use them by default. Apple's [*Animate with
springs*](https://developer.apple.com/videos/play/wwdc2023/10158/) (WWDC 2023) gives the two
numbers a designer can think in, **duration** and **bounce**, and how they become stiffness and
damping.
"""

nbCodeAnd(nbJsFromCode):
  type Spring = object
    x, v, target: float   # where it is, its speed, where it goes
    k, c: float           # stiffness and damping (mass 1)

  func spring(duration, bounce: float): Spring =
    ## Apple's parameters: about `duration` seconds to settle, `bounce` 0 (none) to 1
    result.k = pow(2 * PI / duration, 2)
    result.c = 4 * PI * (1 - bounce) / duration

  proc step(s: var Spring, dt: float) =
    ## move `dt` seconds on, in small steps so a slow frame can't make it explode
    var left = dt
    while left > 0:
      let h = min(left, 1 / 240)
      let a = -s.k * (s.x - s.target) - s.c * s.v
      s.v += a * h
      s.x += s.v * h
      left -= h

nbText: "Four springs of half a second, from 0 to 100, with more and more bounce:"
nbCode:
  for bounce in [0.0, 0.15, 0.3, 0.5]:
    var s = spring(0.5, bounce)
    s.target = 100
    var top = 0.0
    var settled = 0.0
    for frame in 1 .. 120:                       # two seconds at 60 frames a second
      s.step(1 / 60)
      top = max(top, s.x)
      if abs(s.x - 100) > 0.5: settled = frame / 60
    echo &"bounce {bounce:.2f}: highest {top:6.1f}, within half a unit after {settled:.2f} s"

nbText: """
Parloku's wobble, `1 + amp·exp(−dt/140)·sin(dt/26)`, is the formula of a spring that was
already moving: a spring written out by hand for one case. The simulated one covers all cases,
including the one where the finger moves again before it stops.

### 4 · Smoothing: chase the target

The cheapest follower moves a fixed part of the way to its target every frame. Written as
`x = lerp(x, target, 0.1)` it runs faster at 120 Hz than at 60. Freya Holmér's [*Lerp smoothing
is broken*](https://www.youtube.com/watch?v=LSNQuFEDOyQ) explains the fix, an exponential decay
that depends on the time passed, not on the frames:
"""

nbCodeAnd(nbJsFromCode):
  func smooth(x, target, rate, dt: float): float =
    ## the same result at any frame rate: after 1/rate seconds, 63% of the way
    result = mix(x, target, 1 - exp(-rate * dt))

nbCode:
  for fps in [30, 60, 120]:
    var naive, good = 0.0
    for frame in 1 .. fps div 2:                 # half a second
      naive = mix(naive, 100, 0.1)
      good = smooth(good, 100, 6, 1 / fps)
    echo &"{fps:3} fps, after 0.5 s: lerp 0.1 per frame {naive:5.1f}   smooth {good:5.1f}"

nbText: """
Tap **go** and watch the same move done four ways. Tap again before they arrive: the tweens
start over from where they are (a jolt in speed), the spring turns round smoothly.
"""
nbStage "race", "The same move from left to right: linear, easeInOutCubic and easeOutBack tweens of 0.7 s, and a spring of 0.7 s with a bounce of 0.3."

nbText: """
Now let something follow your finger (or, if you leave it, a path of its own). The tween is
restarted at every move of the pointer, as a naive library would do; the smoothed one chases;
the spring has momentum and swings past.
"""
nbStage "follow", "Drag on the box. Grey: a 0.4 s tween restarted at every pointer move. Blue: exponential smoothing. Red: a spring (0.6 s, bounce 0.3)."

nbText: """
### 5 · Constraints: things that drag other things

Some motion is not a tween at all: the body of a snake goes where the head went. The simplest
rule, used in games since the eighties and shown beautifully in argonaut's [*A simple procedural
animation technique*](https://www.youtube.com/watch?v=qlfh_rv6khY), is a **distance
constraint**: each segment stays a fixed distance from the one before it, pulled along the line
between them.
"""

nbCodeAnd(nbJsFromCode):
  type V = tuple[x, y: float]
  func `+`(a, b: V): V = (a.x + b.x, a.y + b.y)
  func `-`(a, b: V): V = (a.x - b.x, a.y - b.y)
  func `*`(a: V, k: float): V = (a.x * k, a.y * k)
  func norm(a: V): float = hypot(a.x, a.y)

  proc follow(body: var seq[V], head: V, gap: float) =
    ## the head goes to `head`; every other segment stays `gap` from the one before it
    body[0] = head
    for i in 1 ..< body.len:
      let d = body[i] - body[i - 1]
      let n = d.norm
      if n > 0.001: body[i] = body[i - 1] + d * (gap / n)

nbText: """
That is the whole snake below: the head chases your finger with `smooth`, the letters follow with
`follow`, and the eyes look along the line from the second letter to the head. *Wiggle* adds a
wave that travels down the body; *spring head* swaps `smooth` for a spring.
"""
nbStage "snake", "A word as a snake. Drag on the box, or let it wander. Six letters, 34 units apart."

nbText: """
### 6 · Timelines: animation as a function of time

Put tweens in time (one after the other, together, each a little later than the one before) and
you have a **timeline**, the heart of GSAP, anime.js, Godot's `Tween` and Flash before them.
The purest version needs no objects at all: an animation is a function from time to a value, and
timelines are functions that combine functions. This is Conal Elliott and Paul Hudak's
[*Functional Reactive Animation*](http://conal.net/papers/icfp97/) (ICFP 1997), and it is what
parloku's dances already are.
"""

nbCodeAnd(nbJsFromCode):
  type Anim = proc (t: float): float          # t in ms

  proc hop(dur: float): Anim =
    ## up and down once: 0, then 1 halfway, then 0 again
    result = proc (t: float): float =
      if t > 0 and t < dur: result = sin(PI * t / dur)

  proc delay(a: Anim, ms: float): Anim =
    result = proc (t: float): float = a(t - ms)

  proc either(a, b: Anim): Anim =
    ## both at once: the larger of the two
    result = proc (t: float): float = max(a(t), b(t))

  proc stagger(n: int, gap: float, a: Anim): seq[Anim] =
    ## n copies of `a`, each `gap` ms after the one before
    for i in 0 ..< n: result.add a.delay(float(i) * gap)

  proc snakeDance(n: int): seq[Anim] =
    ## parloku's 🐍 dance, for one word: letter after letter, then everybody together
    let one = stagger(n, 110, hop(380))
    for i in 0 ..< n: result.add either(one[i], hop(450).delay(1100))

nbText: """
Because it is just a function, it can be printed at build time as an animator's **dope sheet**,
one row per letter, one column every 50 ms (`·` still, `█` at the top of the hop):
"""
nbCode:
  let dance = snakeDance(6)
  const marks = [" ", "·", "▁", "▃", "▅", "█"]
  for i, letter in "PAROLE":
    var row = ""
    for col in 0 .. 32:
      row.add marks[int(round(dance[i](float(col) * 50) * 5))]
    echo letter, " │", row, "│"

nbStage "timeline", "The same dance in the browser: press play, or drag the slider to scrub through time. Nothing is stored; each frame is computed from t."

nbText: """
## Is there a declarative dragging of animation?

Declarative Dragging says: don't write drag handlers, **list the states the drag can reach**, and
the interaction falls out. The animation counterpart says: don't write animations, **describe
the states, and let something decide how to move between them**. It exists, in four shapes:

1. **Animation as a value of time.** Fran (1997), and every timeline since: the frame is a
   function of `t`. Declarative because there is nothing to update, only to evaluate.
2. **Implicit, state-driven animation.** Change the state; the framework animates the
   difference. CSS transitions; SwiftUI's `withAnimation { ... }`; Jetpack Compose's
   `animate*AsState`; Flutter's implicit `AnimatedContainer`; Motion's `animate={{ x }}` and its
   **layout animations**; Keynote's Magic Move. The trick under them is
   [FLIP](https://aerotwist.com/blog/flip-your-animations/) (Paul Lewis): measure **F**irst,
   render **L**ast, **I**nvert with a transform, **P**lay to zero. D3's keyed joins and
   transitions (Mike Bostock) do the same for data: a key keeps an element's identity (*object
   constancy*) so it can move instead of vanish.
3. **Grammars of transitions.** Jeffrey Heer, one of the three authors of Declarative Dragging,
   wrote with George Robertson *Animated Transitions in Statistical Data Graphics* (2007), on
   staging and keyed objects, and with Younghoon Kim [**Gemini**](https://idl.uw.edu/papers/gemini)
   (IEEE VIS 2020): a declarative grammar for the animated transition between two charts, with a
   recommender that proposes the staging and timing. It is the closest thing to a *declarative
   dragging of animation* I found: you give the two states, it gives the movie.
4. **State machines.** Rive, Unity's Animator, Godot's AnimationTree: named states with
   animations, and transitions between them triggered by inputs. Declarative about *which*
   animation plays, not about how a value moves.

**For zogyn this is good news**: it already has the hard half. A view is a pure function from the
model to keyed, positioned items. Today the browser's CSS transition moves each key from its
old place to its new one; a zogyn animator would do the same in Nim, with springs, stagger,
enter and exit, and no jolt when a move is interrupted. A `Transition[S]` could sit next to
`Behavior[S]`: given the state before and after, say what moves first, what waits, what pops.
"""

nbText: """
Here is that half, in Nim: each render gives every key a place; the animator keeps one spring
(or one tween) per key and only changes its target. The code below runs in the demo under it.
"""

nbCodeDisplay(nbJsFromCode):
  type Animator = object
    keys: seq[string]
    xs, ys: seq[Spring]           # one spring per key and axis
    tws: seq[(Tween, Tween)]      # or one tween per key and axis
    due: seq[float]               # when a key starts its move (for a stagger)
    pending: seq[V]

  proc retarget(an: var Animator, places: seq[(string, V)], t: float, stagger: float) =
    ## a new render: every key gets its new place, `stagger` ms after the one before it
    for i, (key, at) in places:
      let k = an.keys.find(key)
      an.due[k] = t + float(i) * stagger
      an.pending[k] = at

  proc frame(an: var Animator, t, dt: float, useSprings: bool) =
    for k in 0 ..< an.keys.len:
      if t >= an.due[k] and an.due[k] >= 0:      # its turn: hand the place to the spring or tween
        an.due[k] = -1
        an.xs[k].target = an.pending[k].x
        an.ys[k].target = an.pending[k].y
        an.tws[k] = (Tween(a: an.xs[k].x, b: an.pending[k].x, start: t, dur: 450, ease: easeInOutCubic),
                     Tween(a: an.ys[k].x, b: an.pending[k].y, start: t, dur: 450, ease: easeInOutCubic))
      if useSprings:
        an.xs[k].step(dt)
        an.ys[k].step(dt)
      else:
        an.xs[k].x = an.tws[k][0].at(t)
        an.ys[k].x = an.tws[k][1].at(t)

nbStage "declarative", "Six keyed tiles. Shuffle or sort changes only the state; the animator moves each key to its new place. Tap shuffle twice quickly to interrupt a move."

nbText: """
## On the web

| Library | Model | Notes, and the fit with Nim |
|---|---|---|
| CSS transitions and `@keyframes` | declare the end, the browser interpolates | free and smooth (often off the main thread); no springs, no physics, can't be interrupted gracefully; Safari won't re-read `var()` in keyframes |
| [Web Animations API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Animations_API) | `el.animate(keyframes, timing)` returns an `Animation` you can pause, seek, reverse; CSS `linear()` easing can encode a spring as points | built into every browser (Safari since 13.1); parloku already uses it for the menu; a typed Nim binding is small |
| [View Transitions](https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API) | the browser snapshots before and after a DOM change and morphs elements matched by name | FLIP done by the browser (Safari 18+); for page-level changes more than game pieces |
| [GSAP](https://gsap.com) (GreenSock) | tweens and **timelines** (`gsap.timeline().to(...).to(...)`), stagger, plugins: Flip, Draggable, MorphSVG, Physics2D | the industry standard since Flash; [free since 2025](https://webflow.com/blog/gsap-becomes-free), plugins included, under its own license (not open source; no competing visual builders); about 70 kB; wrappable with `importjs` |
| [Motion](https://motion.dev) (was Framer Motion) | **springs** by default, `animate()` in plain JS, layout animations, gestures; runs on WAAPI where it can | MIT; Matt Perry; [independent since November 2024](https://motion.dev/blog/framer-motion-is-now-independent-introducing-motion); the best model of *state-driven* animation |
| [anime.js](https://animejs.com) | tweens, timelines, stagger, keyframes; v4 (2025) adds springs, a draggable and scroll | MIT; Julian Garnier; small, readable, a good one to wrap or to port |
| [Popmotion](https://popmotion.io) | animation as small functions: `tween`, `spring`, `inertia`, `decay` | Matt Perry's earlier library; its ideas are in Motion; the closest in spirit to a Nim library |
| react-spring | spring physics as hooks: set a target, it springs there | React only, but the idea (targets, not durations) is the one to borrow |
| [tween.js](https://github.com/tweenjs/tween.js) | the classic tween with chaining, used by three.js examples | MIT, tiny: a few hours to rewrite in Nim |
| [Theatre.js](https://www.theatrejs.com) | a timeline editor in the page, keyframes by hand | for authoring by eye, not by code |
| Lottie | After Effects to JSON, played by a runtime | a designer's pipeline |
| [Rive](https://rive.app) | an editor and runtimes with **state machines**: inputs blend and switch animations | declarative about states; for characters and icons |
"""

nbText: """
## In games

Games animate everything, every frame, and their tools are the same pieces with other names:

| Engine or library | How it animates |
|---|---|
| Flash and ActionScript | the timeline and tweening; Robert Penner's [easing equations](http://robertpenner.com/easing/) (2001), still the names in every library; Tweener, then TweenLite by Jack Doyle, which became GSAP |
| [Godot](https://docs.godotengine.org/en/stable/classes/class_tween.html) | `create_tween().tween_property(node, "position", to, 0.4).set_trans(Tween.TRANS_BACK)`: steps run in sequence, `.parallel()` runs them together, `tween_callback` for events; AnimationPlayer and AnimationTree (state machines) for authored motion |
| Unity | the Animator (state machines, blend trees) and AnimationCurve; [DOTween](https://dotween.demigiant.com): `transform.DOMove(to, 1).SetEase(Ease.OutBack)` and `Sequence`; LeanTween |
| LÖVE (Lua) | kikito's [tween.lua](https://github.com/kikito/tween.lua), rxi's [flux](https://github.com/rxi/flux) (`flux.to(obj, 1, {x = 10}):ease("backout"):after(...)`), `hump.timer.tween` |
| Phaser | `this.tweens.add({targets, x, duration, ease, yoyo, repeat})` and tween chains |
| raylib | `reasings.h`, Penner's curves in C, called from your own loop (in Nim through naylib) |
| PICO-8 | by hand: `t()`, `sin`, `cos` in the update loop, exactly like parloku's dances |
| procedural | distance constraints, inverse kinematics, Verlet physics: Rain World's creatures, argonaut's lizards and snakes |

Two ideas from games matter more than any library:

- **Juice.** Martin Jonasson and Petri Purho's [*Juice it or lose it*](https://www.youtube.com/watch?v=Fy0aCDmgnxg)
  (2012) turns a dull Breakout into a joyful one with tweens, squash and stretch, wobble and
  particles, one at a time. Parloku's marbles, ripples and dances are juice.
- **The twelve principles.** Frank Thomas and Ollie Johnston's *The Illusion of Life* (1981):
  squash and stretch, anticipation, follow-through, slow in and slow out (easing), arcs. A snake
  that leans before it moves and whose tail arrives a moment after its head uses three of them.

## In Nim, today

Not much, and nothing maintained for the browser: [micycle8778/tweens](https://github.com/micycle8778/tweens)
(a basic tweening library, 2021), [Skrylar/skEasing](https://github.com/Skrylar/skEasing) (easing
curves, 2018), raylib's easings through naylib for native games, and
[nimanim](https://github.com/himanshm/nimanim), manim-style videos (used for the [affinity
propagation page](../nimanim-affinity/index.html)), which renders frames offline rather than
animating a live page. So a small library that works in `nim js` (and natively, for tests and
dope sheets) fills a real gap, and could live in zogyn next to the dragging.
"""

nbText: """
## The people

Pietro's half-remembered name is **Sarah Drasner**. The others are the ones whose work this page
leans on, or whose work a Nim animation library would learn the most from.

| Who | Known for | Why it matters here |
|---|---|---|
| Sarah Drasner | *SVG Animations* (O'Reilly, 2017); years of CSS-Tricks articles on GSAP and SVG; Vue core team; VP of Developer Experience at Netlify; now a senior director of engineering at Google; *Engineering Management for the Rest of Us* (2022) | parloku is SVG, and her way (SVG plus GSAP timelines, for interfaces that explain) is the closest to ours |
| Rachel Nabors | *Animation at Work* (A Book Apart, 2017); champion of the Web Animations API | how to use animation to explain, and the API parloku already calls |
| Val Head | *Designing Interface Animation* (2016) | when motion helps and when it gets in the way; reduced motion |
| Cassie Evans | SVG animation teaching; works on GSAP | playful SVG, the parloku look |
| Jack Doyle | founded GreenSock (TweenLite in the Flash years, then GSAP) | the timeline API everybody copied |
| Matt Perry | Popmotion, Framer Motion, now Motion | springs by default and layout animation: the model for a zogyn animator |
| Julian Garnier | anime.js | a small, readable library to port or wrap |
| Paul Henschel | react-spring and the pmndrs collective | "set a target, it springs there" |
| Robert Penner | the easing equations (2001) | the vocabulary of every library |
| Paul Lewis | FLIP (2015) | how to animate layout changes cheaply |
| Josh W. Comeau | [*A friendly introduction to spring physics*](https://www.joshwcomeau.com/animation/a-friendly-introduction-to-spring-physics/), playful web animation | springs explained with things that move, like this page wants to |
| Emil Kowalski | the [animations.dev](https://animations.dev) course; Sonner and Vaul | small, careful interface motion today |
| Freya Holmér | math for game developers, splines, *Lerp smoothing is broken* | the right way to chase a target |
| Martin Jonasson and Petri Purho | *Juice it or lose it* (2012) | why parloku's motion makes it fun |
| argonaut | *A simple procedural animation technique* (2024) | snakes and lizards from distance constraints |
| Daniel Shiffman | [*The Nature of Code*](https://natureofcode.com): forces, springs, steering | creatures that move by rules |
| Bartosz Ciechanowski | [explorable articles](https://ciechanow.ski) with live simulations | the standard for explainers with things that move |
| Bret Victor | *Stop Drawing Dead Fish* (2012), *Learnable Programming* | animation made by direct manipulation |
| Conal Elliott | Fran (with Paul Hudak, 1997), functional reactive programming | animation as a function of time |
| Jeffrey Heer, Younghoon Kim, Mike Bostock | animated transitions (2007), Gemini (2020), D3 transitions | declarative transitions; Heer is also a Declarative Dragging author |
"""

nbText: """
## A shortlist for Nim proofs of concept

Four approaches, each small enough for one thread and one dated page with demos, all in Nim
compiled to JavaScript and tried on iPhone Safari:

1. **Tweens and timelines, as functions of time** (GSAP, Godot, flux, Fran). A pure Nim module:
   easings, `tween`, `delay`, `sequence`, `together`, `stagger`, sampled at any `t`. It runs
   natively too, so tests and build-time dope sheets come free. The proof: parloku's three win
   dances rewritten as timelines, side by side with today's code, and scrubbable.
2. **Springs between renders, for zogyn** (Motion's layout animation, SwiftUI, FLIP, Gemini). An
   animator that takes each zogyn render (keyed items) and springs every key (position, scale,
   turn) to its new place, with stagger, enter and exit, and no jolt when a drag interrupts it.
   It replaces the CSS transition in `stage.nim`. The proof: zogyn's docs demos and a parloku
   board using it, with Apple's *duration* and *bounce* as the only two numbers.
3. **Snakes that live** (procedural animation). Parloku's words as creatures: the body follows
   the head along its cells with distance constraints, the eyes turn smoothly towards where the
   head goes, an idle breath and blink, and the snake slithers into place when a word is laid.
   Built on 1 and 2. The proof: a garden page with a playable board.
4. **Let the browser do it** (Web Animations API, and a look at wrapping anime.js or Motion). A
   typed Nim binding for `element.animate`, springs turned into `linear()` easing, and the same
   demos as 1 and 2, to see what the browser does for free on a phone and what it can't do
   (interrupting, following a finger).

My suggestion: **1 and 2 first**, since together they are the framework (a timeline for things
that tell a story, springs for things that answer a finger); **3** right after, as the playful
use that shows whether the framework is pleasant; **4** as a short comparison, to know when a
binding is enough.
"""

nbText: """
## Sources

- Parloku: `src/parloku.nim`, `src/style.nim`, `src/devlog_cells.nim`; zogyn: `src/zogyn/stage.nim`.
- Webflow, [GSAP becomes free](https://webflow.com/blog/gsap-becomes-free); Matt Perry,
  [Framer Motion is now independent](https://motion.dev/blog/framer-motion-is-now-independent-introducing-motion).
- Y. Kim and J. Heer, [Gemini](https://idl.uw.edu/papers/gemini) ([arXiv](https://arxiv.org/abs/2009.01429)), IEEE VIS 2020.
- C. Elliott and P. Hudak, [Functional Reactive Animation](http://conal.net/papers/icfp97/), ICFP 1997.
- Apple, [Animate with springs](https://developer.apple.com/videos/play/wwdc2023/10158/), WWDC 2023.
- The videos by Freya Holmér, argonaut, and Martin Jonasson and Petri Purho, linked above.
- What came before this page: [Explainers, review mode and the playful repos](../explainers-and-review/index.html),
  and [Declarative Dragging, in Nim](../declarative-dragging-nim/index.html).
"""

# ------------------------------------------------------------------ the demos (browser only)
nbJsFromCodeGlobal:
  import std/[dom, math, strformat, strutils]

nbJsFromCode:
  proc raf(cb: proc (t: float)) {.importjs: "requestAnimationFrame(#)".}
  proc rectOf(e: Element): (float, float, float, float) {.importjs:
    "(() => { const r = #.getBoundingClientRect(); return {Field0: r.left, Field1: r.top, Field2: r.width, Field3: r.height}; })()".}
  proc clientX(ev: Event): float {.importjs: "#.clientX".}
  proc clientY(ev: Event): float {.importjs: "#.clientY".}
  proc capture(e: Element, ev: Event) {.importjs: "#.setPointerCapture(#.pointerId)".}
  proc setOn(e: Element, on: bool) {.importjs: "#.classList.toggle('on', #)".}
  proc numValue(e: Element): float {.importjs: "parseFloat(#.value)".}
  proc setNum(e: Element, v: float) {.importjs: "#.value = #".}
  proc nowMs(): float {.importjs: "performance.now()".}

  var frames: seq[proc (t, dt: float)]

  proc mountStage(id: string, w, h: float, controls: string): (Element, Element) =
    ## an SVG of w×h units and a row of controls in the box `id`
    let host = document.getElementById(cstring(id))
    host.innerHTML = cstring(&"""<svg viewBox="0 0 {w} {h}"></svg><div class="ctl">{controls}</div>""")
    result = (host.querySelector("svg"), host.querySelector(".ctl"))

  proc toLocal(svg: Element, ev: Event, w, h: float): V =
    let (l, t, rw, rh) = rectOf(svg)
    result = ((clientX(ev) - l) * w / rw, (clientY(ev) - t) * h / rh)

  proc button(ctl: Element, what: string): Element =
    ctl.querySelector(cstring(&"""[data-do="{what}"]"""))

  # ---- the race: four ways to make the same move
  block:
    let (svg, ctl) = mountStage("race", 360, 230, """<button data-do="go">▶ go</button>""")
    let names = ["linear", "inOutCubic", "outBack", "spring"]
    let eases = [Ease(linear), easeInOutCubic, easeOutBack]
    let (x0, x1) = (110.0, 300.0)
    var tws: array[3, Tween]
    for i in 0 .. 2: tws[i] = Tween(a: x0, b: x0, start: 0, dur: 700, ease: eases[i])
    var sp = spring(0.7, 0.3)
    sp.x = x0
    sp.target = x0
    var right = false
    var now = 0.0
    proc go() =
      right = not right
      var to = x0
      if right: to = x1
      for i in 0 .. 2:
        tws[i] = Tween(a: tws[i].at(now), b: to, start: now, dur: 700, ease: eases[i])
      sp.target = to
    ctl.button("go").addEventListener("click", proc (ev: Event) = go())
    svg.addEventListener("pointerdown", proc (ev: Event) = go())
    frames.add proc (t, dt: float) =
      now = t
      sp.step(dt)
      var s = ""
      for i in 0 .. 3:
        let y = 38.0 + float(i) * 52
        var x = sp.x
        if i < 3: x = tws[i].at(t)
        s.add &"""<text class="lbl" x="8" y="{y + 4}">{names[i]}</text>"""
        s.add &"""<line class="track" x1="{x0}" y1="{y}" x2="{x1}" y2="{y}"/>"""
        s.add &"""<circle class="k{i}" cx="{x:.1f}" cy="{y}" r="13"/>"""
      svg.innerHTML = cstring(s)

  # ---- following a finger: tween, smoothing, spring
  block:
    let (w, h) = (360.0, 260.0)
    let (svg, _) = mountStage("follow", w, h, """<span class="read">drag on the box</span>""")
    var target: V = (180.0, 130.0)
    var lastTouch = -10000.0
    var now = 0.0
    var tw: (Tween, Tween)
    var sm: V = target
    var sx = spring(0.6, 0.3)
    var sy = spring(0.6, 0.3)
    sx.x = target.x
    sy.x = target.y
    proc aim(p: V) =
      target = p
      let at: V = (tw[0].at(now), tw[1].at(now))
      tw = (Tween(a: at.x, b: p.x, start: now, dur: 400, ease: easeInOutCubic),
            Tween(a: at.y, b: p.y, start: now, dur: 400, ease: easeInOutCubic))
    tw = (Tween(a: 180, b: 180, start: 0, dur: 400, ease: linear), Tween(a: 130, b: 130, start: 0, dur: 400, ease: linear))
    var held = false
    svg.addEventListener("pointerdown", proc (ev: Event) =
      held = true
      capture(svg, ev)
      lastTouch = now
      aim(svg.toLocal(ev, w, h)))
    svg.addEventListener("pointermove", proc (ev: Event) =
      if held:
        lastTouch = now
        aim(svg.toLocal(ev, w, h)))
    svg.addEventListener("pointerup", proc (ev: Event) = held = false)
    var wander = 0
    frames.add proc (t, dt: float) =
      now = t
      if t - lastTouch > 2500:                 # nobody touching: jump between points of a path
        let k = int(t / 900)
        if k != wander:
          wander = k
          let a = float(k) * 2.4
          aim((180 + 130 * cos(a), 130 + 90 * sin(a * 1.7)))
      sm = (smooth(sm.x, target.x, 6, dt), smooth(sm.y, target.y, 6, dt))
      sx.target = target.x
      sy.target = target.y
      sx.step(dt)
      sy.step(dt)
      var s = &"""<circle class="target" cx="{target.x:.1f}" cy="{target.y:.1f}" r="18"/>"""
      s.add &"""<circle class="k0" cx="{tw[0].at(t):.1f}" cy="{tw[1].at(t):.1f}" r="11"/>"""
      s.add &"""<circle class="k1" cx="{sm.x:.1f}" cy="{sm.y:.1f}" r="11"/>"""
      s.add &"""<circle class="k2" cx="{sx.x:.1f}" cy="{sy.x:.1f}" r="11"/>"""
      s.add &"""<text class="lbl" x="10" y="20">● tween</text><text class="lbl" x="10" y="38" style="fill:var(--blue)">● smooth</text>"""
      s.add &"""<text class="lbl" x="10" y="56" style="fill:var(--red)">● spring</text>"""
      svg.innerHTML = cstring(s)

  # ---- the snake
  block:
    let (w, h) = (360.0, 300.0)
    let (svg, ctl) = mountStage("snake", w, h,
      """<button data-do="wiggle">〰 wiggle</button><button data-do="spring">🫧 spring head</button>""")
    const word = "PAROLE"
    const gap = 34.0
    var body: seq[V]
    for i in 0 ..< word.len: body.add (180.0 - float(i) * gap, 150.0)
    var head: V = body[0]
    var target: V = head
    var sx = spring(0.8, 0.35)
    var sy = spring(0.8, 0.35)
    sx.x = head.x
    sy.x = head.y
    var wiggle = false
    var springy = false
    var held = false
    var now = 0.0
    var lastTouch = -10000.0
    let bw = ctl.button("wiggle")
    let bs = ctl.button("spring")
    bw.addEventListener("click", proc (ev: Event) =
      wiggle = not wiggle
      bw.setOn(wiggle))
    bs.addEventListener("click", proc (ev: Event) =
      springy = not springy
      sx.x = head.x
      sy.x = head.y
      sx.v = 0
      sy.v = 0
      bs.setOn(springy))
    svg.addEventListener("pointerdown", proc (ev: Event) =
      held = true
      capture(svg, ev)
      lastTouch = now
      target = svg.toLocal(ev, w, h))
    svg.addEventListener("pointermove", proc (ev: Event) =
      if held:
        lastTouch = now
        target = svg.toLocal(ev, w, h))
    svg.addEventListener("pointerup", proc (ev: Event) = held = false)
    frames.add proc (t, dt: float) =
      now = t
      if t - lastTouch > 2500:                  # wander on a figure of eight
        let a = t / 2600
        target = (180 + 120 * sin(a), 150 + 80 * sin(2 * a))
      if springy:
        sx.target = target.x
        sy.target = target.y
        sx.step(dt)
        sy.step(dt)
        head = (sx.x, sy.x)
      else:
        head = (smooth(head.x, target.x, 5, dt), smooth(head.y, target.y, 5, dt))
      body.follow(head, gap)
      var shown = body
      if wiggle:                                # a wave travelling from head to tail
        for i in 1 ..< body.len:
          let d = body[i - 1] - body[i]
          let n = max(d.norm, 0.001)
          let side: V = (-d.y / n, d.x / n)
          shown[i] = body[i] + side * (7 * sin(t / 160 - float(i) * 1.1) * float(i) / float(body.len))
      var s = ""
      for i in countdown(body.len - 1, 0):
        let p = shown[i]
        let li = word.len - 1 - i                  # the head is the last letter, as in parloku
        s.add &"""<circle class="tile c{li}" cx="{p.x:.1f}" cy="{p.y:.1f}" r="17"/>"""
        s.add &"""<text class="letter" x="{p.x:.1f}" y="{p.y:.1f}">{word[li]}</text>"""
      let d = shown[0] - shown[1]
      let n = max(d.norm, 0.001)
      let f: V = (d.x / n, d.y / n)                  # the way the head goes
      let side: V = (-f.y, f.x)
      for sgn in [-1.0, 1.0]:
        let e = shown[0] + f * 13 + side * (8 * sgn)
        let p = e + f * 1.8
        s.add &"""<circle class="eye" cx="{e.x:.1f}" cy="{e.y:.1f}" r="4.6"/><circle class="pupil" cx="{p.x:.1f}" cy="{p.y:.1f}" r="2.2"/>"""
      s.add &"""<circle class="target" cx="{target.x:.1f}" cy="{target.y:.1f}" r="6"/>"""
      svg.innerHTML = cstring(s)

  # ---- the timeline, scrubbed
  block:
    let (svg, ctl) = mountStage("timeline", 360, 120,
      """<button data-do="play">▶ play</button><input type="range" min="0" max="1800" step="10" value="0" aria-label="time"><span class="read">t = 0 ms</span>""")
    let dance = snakeDance(6)
    const word = "PAROLE"
    let slider = ctl.querySelector("input")
    let readout = ctl.querySelector(".read")
    let play = ctl.button("play")
    var playing = false
    var t0 = 0.0
    var tm = 0.0
    var now = 0.0
    play.addEventListener("click", proc (ev: Event) =
      playing = true
      t0 = now)
    slider.addEventListener("input", proc (ev: Event) =
      playing = false
      tm = slider.numValue)
    frames.add proc (t, dt: float) =
      now = t
      if playing:
        tm = t - t0
        if tm > 1800:
          tm = 1800
          playing = false
        slider.setNum(tm)
      readout.innerHTML = cstring(&"t = {tm:.0f} ms")
      var s = ""
      for i in 0 ..< 6:
        let hgt = dance[i](tm)
        let x = 45.0 + float(i) * 54
        let y = 80.0 - 34 * hgt
        var turn = 12.0
        if i mod 2 == 1: turn = -12.0
        let r = turn * hgt
        let sc = 1 + 0.2 * hgt
        s.add &"""<g transform="translate({x:.1f} {y:.1f}) rotate({r:.1f}) scale({sc:.3f})"><circle class="tile c{i}" r="20"/><text class="letter">{word[i]}</text></g>"""
      svg.innerHTML = cstring(s)

  # ---- declarative: keyed tiles, the state changes, the animator moves them
  block:
    let (svg, ctl) = mountStage("declarative", 360, 220,
      """<button data-do="shuffle">🔀 shuffle</button><button data-do="sort">↺ sort</button><button data-do="springs" class="on">springs</button><button data-do="tweens">tweens</button><button data-do="stagger">stagger</button>""")
    const word = "PAROLE"
    var order = @[0, 1, 2, 3, 4, 5]               # the state: which letter is in which place
    proc render(order: seq[int]): seq[(string, V)] =
      ## the view: a pure function from the state to keyed places (a 3 × 2 grid)
      for place, letter in order:
        result.add ($word[letter], (90.0 + float(place mod 3) * 90, 70.0 + float(place div 3) * 90))
    var an = Animator()
    for (key, at) in render(order):
      an.keys.add key
      var sx = spring(0.55, 0.3)
      var sy = spring(0.55, 0.3)
      sx.x = at.x
      sx.target = at.x
      sy.x = at.y
      sy.target = at.y
      an.xs.add sx
      an.ys.add sy
      an.tws.add (Tween(a: at.x, b: at.x, start: 0, dur: 1, ease: linear), Tween(a: at.y, b: at.y, start: 0, dur: 1, ease: linear))
      an.due.add -1.0
      an.pending.add at
    var useSprings = true
    var stagger = false
    var now = 0.0
    var seed = 7
    proc changed() =
      var gap = 0.0
      if stagger: gap = 60
      an.retarget(render(order), now, gap)
    ctl.button("shuffle").addEventListener("click", proc (ev: Event) =
      for i in countdown(5, 1):
        seed = (seed * 75 + 74) mod 65537
        let j = seed mod (i + 1)
        swap(order[i], order[j])
      changed())
    ctl.button("sort").addEventListener("click", proc (ev: Event) =
      order = @[0, 1, 2, 3, 4, 5]
      changed())
    let bsp = ctl.button("springs")
    let btw = ctl.button("tweens")
    let bst = ctl.button("stagger")
    bsp.addEventListener("click", proc (ev: Event) =
      useSprings = true
      for k in 0 ..< an.keys.len:
        an.xs[k].x = an.tws[k][0].at(now)
        an.ys[k].x = an.tws[k][1].at(now)
        an.xs[k].v = 0
        an.ys[k].v = 0
      bsp.setOn(true)
      btw.setOn(false))
    btw.addEventListener("click", proc (ev: Event) =
      useSprings = false
      bsp.setOn(false)
      btw.setOn(true))
    bst.addEventListener("click", proc (ev: Event) =
      stagger = not stagger
      bst.setOn(stagger))
    frames.add proc (t, dt: float) =
      now = t
      an.frame(t, dt, useSprings)
      var s = ""
      for k in 0 ..< an.keys.len:
        s.add &"""<g transform="translate({an.xs[k].x:.1f} {an.ys[k].x:.1f})"><rect class="tile c{k}" x="-32" y="-32" width="64" height="64" rx="14"/><text class="letter">{an.keys[k]}</text></g>"""
      svg.innerHTML = cstring(s)

  # ---- one clock for every demo
  var last = -1.0
  proc loop(t: float) =
    var dt = 1 / 60
    if last >= 0: dt = min(0.05, (t - last) / 1000)
    last = t
    for f in frames: f(t, dt)
    raf(loop)
  raf(loop)

nbSave
