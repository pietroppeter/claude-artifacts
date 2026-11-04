import std/[json, os]
import nimib
import style

nbInit
# write the page next to src/, wherever the build is run from
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.doc.context["title"] = %"Declarative Dragging, in Nim"
nb.doc.context["stylesheet"] = %pageStyle
nb.doc.context["highlight"] = %""
nb.doc.context["disableHighlightJs"] = %true
func pageHeader(blk: JsonNode, nb: Nb): string =
  """<header><span>a nimib notebook</span><span>after Horowitz · Blinn · Heer, UIST '26</span></header>"""
nb.backend.partials["header"] = pageHeader

nbRawHtml: """
<h1>Declarative <em>Dragging</em>,<br>in Nim</h1>
<p class="lede">You don't write drag handlers. You list the states a drag can reach, and the dragging falls out.
A small port of the core idea, written in a nimib notebook and compiled to JavaScript.</p>
<div class="hero-wrap">
  <div>
    <div class="stage" id="hero"></div>
    <div class="caption" id="hero-caption"></div>
  </div>
  <div>
    <div class="panel" id="hero-panel"></div>
    <div class="controls"><button class="btn" id="hero-replay">▶ replay explainer</button></div>
  </div>
</div>
"""

nbText: """
The demo above runs on its own until you grab a tile. The coral dots are the *machinery*: every place the tile **could** land.
The dark panel lists every model state the drag can reach, with its distance from the tile you're holding.
Nobody wrote code that says "tiles shift right when you drag left". That behaviour comes out of one line of Nim:

```nim
closest(toSeq(0 ..< word.len).mapIt(word.moveTo(key, it)))
```

The idea comes from **Declarative Dragging** by Joshua Horowitz, Andrew Blinn and Jeffrey Heer,
which won a [Best Paper award at UIST 2026](https://uist.acm.org/2026/awards/).
Their library, [Dragology](https://github.com/declarative-dragging/dragology), is TypeScript, React and SVG.
This page rebuilds the core in about 120 lines of Nim. The same engine code runs twice:
natively while nimib builds the page (that's how the outputs below were printed), and in your browser through `nim js`.
"""

nbRawHtml: """<h2><span class="num">01 · THE IDEA</span>A drag is a choice between futures</h2>"""

nbText: """
Hand-coded drag-and-drop is fiddly. You track pointer deltas, hit-test drop zones, keep the model in sync and animate
everything else out of the way. D2 turns this around. **A view is a function of the model.** When an element is grabbed:

1. The **spec** lists the model states this drag may reach (e.g. "this tile in each slot").
2. Each state is rendered **speculatively**, off-screen and never painted, to see *where the dragged element would land* in it.
3. While the element floats under the pointer, the state whose landing spot is **closest** gets shown for everything else.
4. On release, that state is committed.

Behaviours like `closest`, `vary` and `within` are **composable operators**. Snapping, continuous parameters and fallbacks
are built by combining them, not by writing more event-handler code. Here's the whole engine.
It has no DOM in it, so it compiles on both backends:
"""

nbCodeAnd(nbJsFromCode):
  import std/[math, strformat, strutils, sequtils]

  type
    Vec = object
      x, y: float
    Item = object            ## one keyed element of a rendered view
      key: string            ## identity across states (what your eye tracks)
      pos: Vec               ## where it sits in this state
      svg: string            ## what it looks like, drawn around (0, 0)
    Render[S] = proc (s: S): seq[Item]
    Choice[S] = object
      ok: bool
      state: S
      land: Vec              ## where the dragged element lands in `state`
      dist: float
    Picker[S] = object       ## a behaviour, instantiated at drag start
      lands: seq[Vec]        ## speculative landing spots (the coral dots)
      pick: proc (p: Vec): Choice[S]
    Behavior[S] = proc (render: Render[S], key: string): Picker[S]

  func vec(x, y: float): Vec = Vec(x: x, y: y)
  func `+`(a, b: Vec): Vec = vec(a.x + b.x, a.y + b.y)
  func `-`(a, b: Vec): Vec = vec(a.x - b.x, a.y - b.y)
  func norm(a: Vec): float = hypot(a.x, a.y)

  proc locate[S](render: Render[S], s: S, key: string): Vec =
    ## speculative rendering: draw `s` without painting it,
    ## and report where the element `key` would land
    for it in render(s):
      if it.key == key: return it.pos
    vec(NaN, NaN)

  proc closest[S](states: seq[S]): Behavior[S] =
    ## discrete: snap to the state that lands the element nearest
    result = proc (render: Render[S], key: string): Picker[S] =
      var lands: seq[Vec]
      for s in states: lands.add render.locate(s, key)
      result.lands = lands
      result.pick = proc (p: Vec): Choice[S] =
        result.dist = Inf
        for i, s in states:
          let d = norm(lands[i] - p)
          if d < result.dist:
            result = Choice[S](ok: true, state: s, land: lands[i], dist: d)

  proc vary[S](f: proc (t: float): S, lo, hi: float, samples = 64): Behavior[S] =
    ## continuous: sample the parameter's path, then refine
    ## between the nearest samples with a ternary search
    result = proc (render: Render[S], key: string): Picker[S] =
      var ts: seq[float]
      var lands: seq[Vec]
      for i in 0 .. samples:
        let t = lo + (hi - lo) * i.float / samples.float
        ts.add t
        lands.add render.locate(f(t), key)
      result.lands = lands
      result.pick = proc (p: Vec): Choice[S] =
        var best = 0
        for i in 1 .. samples:
          if norm(lands[i] - p) < norm(lands[best] - p): best = i
        var a = ts[max(best - 1, 0)]
        var b = ts[min(best + 1, samples)]
        let distAt = proc (t: float): float = norm(render.locate(f(t), key) - p)
        for _ in 1 .. 30:
          let m1 = a + (b - a) / 3
          let m2 = b - (b - a) / 3
          if distAt(m1) < distAt(m2): b = m2 else: a = m1
        let s = f((a + b) / 2)
        let land = render.locate(s, key)
        Choice[S](ok: true, state: s, land: land, dist: norm(land - p))

  proc within[S](b: Behavior[S], radius: float): Behavior[S] =
    ## snapping: only accept a landing spot closer than `radius`
    result = proc (render: Render[S], key: string): Picker[S] =
      let inner = b(render, key)
      result.lands = inner.lands
      result.pick = proc (p: Vec): Choice[S] =
        result = inner.pick(p)
        if result.dist > radius: result.ok = false

  proc orElse[S](a, b: Behavior[S]): Behavior[S] =
    ## fallback: try `a`, and if it declines use `b`
    result = proc (render: Render[S], key: string): Picker[S] =
      let pa = a(render, key)
      let pb = b(render, key)
      result.lands = pa.lands & pb.lands
      result.pick = proc (p: Vec): Choice[S] =
        result = pa.pick(p)
        if not result.ok: result = pb.pick(p)

nbText: """
That's the whole thing. `Render[S]` is the view, a pure function from model to keyed, positioned items.
`locate` is speculative rendering: call the view on a hypothetical state and read off one item's position.
The paper's library renders real SVG and measures it. Here layout and drawing are one Nim function, so a
speculative render is just a function call.
"""

nbRawHtml: """<h2><span class="num">02 · SPECULATIVE RENDERING</span>Watching the engine think</h2>"""

nbText: """
Here is the model behind the hero: a word, as a sequence of letters, laid out in a 3×2 grid.
`moveTo` is ordinary list surgery. `tileSpec` is the whole interaction spec.
"""

nbCodeAnd(nbJsFromCode):
  const hues = ["#ffe953", "#8fd3c8", "#f6a6a0", "#b9a7e6", "#9fd38f", "#f7c08a"]

  proc moveTo[T](xs: seq[T], x: T, i: int): seq[T] =
    result = xs
    result.delete(xs.find(x))
    result.insert(x, i)

  proc slot(i: int): Vec = vec(60 + float(i mod 3) * 100, 60 + float(i div 3) * 100)

  proc tile(letter: string, hue: string): string =
    &"""<rect x="-38" y="-38" width="76" height="76" rx="16" fill="{hue}" stroke="#1d1b16" stroke-width="3"/>""" &
    &"""<text y="13" text-anchor="middle" font-size="38" font-weight="700" fill="#1d1b16">{letter}</text>"""

  proc renderTiles(word: seq[string]): seq[Item] =
    for i, letter in word:
      let hue = hues["NIMBUS".find(letter) mod hues.len]
      result.add Item(key: letter, pos: slot(i), svg: tile(letter, hue))

  proc tileSpec(word: seq[string], key: string): Behavior[seq[string]] =
    closest(toSeq(0 ..< word.len).mapIt(word.moveTo(key, it)))

nbText: """
Now let's drive the engine by hand while nimib builds the page. We grab **B**, which instantiates the behaviour and
renders all six candidate states speculatively. Then we pretend the pointer sits at (150, 95), between the first two slots:
"""

nbCode:
  let word = @["N", "I", "M", "B", "U", "S"]
  let picker = tileSpec(word, "B")(renderTiles, "B")
  let pointer = vec(150, 95)
  for i, land in picker.lands:
    let st = word.moveTo("B", i)
    echo &"candidate {i}: {st.join:<8} B lands at ({int(land.x):>3}, {int(land.y):>3})  dist {norm(land - pointer):6.1f}"
  let choice = picker.pick(pointer)
  echo &"→ pointer at (150, 95) shows {choice.state.join}"

nbText: "The same speculative renders, drawn as thumbnails at build time. The coral ring is where B would land, the cross is the pointer:"

nbCode:
  proc thumb(items: seq[Item], hl: string, p: Vec, ring: Vec): string =
    result = """<svg viewBox="0 0 320 220">"""
    for it in items:
      let op = if it.key == hl: 1.0 else: 0.28
      result.add &"""<g transform="translate({it.pos.x},{it.pos.y})" opacity="{op}">{it.svg}</g>"""
    result.add &"""<circle cx="{ring.x}" cy="{ring.y}" r="46" fill="none" stroke="#e4572e" stroke-width="5"/>"""
    result.add &"""<path d="M{p.x-12},{p.y} h24 M{p.x},{p.y-12} v24" stroke="#1d1b16" stroke-width="4"/></svg>"""

  var strip = """<div class="filmstrip">"""
  for i, land in picker.lands:
    let st = word.moveTo("B", i)
    let cls = if st == choice.state: "best" else: ""
    strip.add &"""<figure class="{cls}">{thumb(renderTiles(st), "B", pointer, land)}"""
    strip.add &"""<figcaption>{st.join} · {norm(land - pointer):.0f}px</figcaption></figure>"""
  strip.add "</div>"
nbRawHtml: strip

nbText: """
That's the entire decision procedure. Everything else is the **runtime**: about 90 lines of DOM glue that turn pointer
events into `pick` calls. It renders the chosen state for everyone except the held element, which floats under your finger.
It also keeps one `<g>` per key across renders, so a CSS transition slides the other elements to their new positions.
"""

nbRawHtml: "<details><summary>show the browser runtime (std/dom, ~90 lines)</summary>"
nbCodeDisplay(nbJsFromCode):
  import std/[dom, tables]

  proc svgNode(tag: cstring): Element {.importjs: "document.createElementNS('http://www.w3.org/2000/svg', #)".}
  proc capture(e: Element, ev: Event) {.importjs: "#.setPointerCapture(#.pointerId)".}
  proc keyAt(ev: Event): cstring {.importjs: "(#.target.closest('[data-key]')?.dataset.key ?? null)".}
  proc setStyle(e: Element, k, v: cstring) {.importjs: "#.style.setProperty(#, #)".}
  proc checked(e: Element): bool {.importjs: "#.checked".}
  proc clientXY(ev: Event): Vec {.importjs: "(e => ({x: e.clientX, y: e.clientY}))(#)".}
  proc rectOf(e: Element): (float, float, float, float) {.importjs:
    "(() => { const r = #.getBoundingClientRect(); return {Field0: r.left, Field1: r.top, Field2: r.width, Field3: r.height}; })()".}

  type Stage[S] = ref object
    state: S
    render: Render[S]
    spec: proc (s: S, key: string): Behavior[S]
    backdrop: proc (s: S): string
    svg, bg, ghosts, fg: Element
    nodes: Table[string, Element]
    looks: Table[string, string]
    w, h: float
    dragKey: string
    grab, at: Vec            # pointer offset at grab; where the held item floats
    picker: Picker[S]
    choice: Choice[S]
    showGhosts: bool
    onMove: proc ()

  proc tr(p: Vec): cstring = cstring(&"translate({p.x:.2f}px, {p.y:.2f}px)")

  proc drawGhosts[S](st: Stage[S]) =
    var g = ""
    if st.dragKey.len > 0 and st.showGhosts:
      let many = st.picker.lands.len > 40
      for l in st.picker.lands:
        if l.x == l.x:  # skip NaN
          let (cls, r) = if many: ("path", 2.6) else: ("land", 7.0)
          g.add &"""<circle class="{cls}" cx="{l.x}" cy="{l.y}" r="{r}"/>"""
      if st.choice.ok:
        let c = st.choice.land
        g.add &"""<line class="tether" x1="{st.at.x}" y1="{st.at.y}" x2="{c.x}" y2="{c.y}"/>"""
        g.add &"""<circle class="best" cx="{c.x}" cy="{c.y}" r="13"/>"""
    st.ghosts.innerHTML = cstring(g)

  proc draw[S](st: Stage[S], s: S) =
    if not st.backdrop.isNil: st.bg.innerHTML = cstring(st.backdrop(s))
    var seen: seq[string]
    for it in st.render(s):
      seen.add it.key
      let held = it.key == st.dragKey
      var n = st.nodes.getOrDefault(it.key)
      if n.isNil:
        n = svgNode("g")
        n.setAttribute("data-key", cstring(it.key))
        n.setStyle("transform", tr(it.pos))
        st.fg.appendChild(n)
        st.nodes[it.key] = n
      if st.looks.getOrDefault(it.key) != it.svg:
        n.innerHTML = cstring(it.svg)
        st.looks[it.key] = it.svg
      let grab = if st.spec(s, it.key).isNil: "" else: " grab"
      let lifted = if held: " lifted" else: ""
      let pos = if held: st.at else: it.pos
      n.setAttribute("class", cstring("item" & grab & lifted))
      n.setStyle("transform", tr(pos))
    for k in toSeq(st.nodes.keys):
      if k notin seen:
        st.fg.removeChild(st.nodes[k])
        st.nodes.del k
        st.looks.del k
    st.drawGhosts()

  proc move[S](st: Stage[S], p: Vec) =
    st.at = p - st.grab
    st.choice = st.picker.pick(st.at)
    let shown = if st.choice.ok: st.choice.state else: st.state
    st.draw(shown)
    if not st.onMove.isNil: st.onMove()

  proc start[S](st: Stage[S], key: string, p: Vec) =
    let behavior = st.spec(st.state, key)
    if behavior.isNil: return
    st.dragKey = key
    st.grab = p - st.render.locate(st.state, key)
    st.picker = behavior(st.render, key)   # speculative renders happen here
    st.fg.appendChild(st.nodes[key])       # float above the others
    st.move(p)

  proc finish[S](st: Stage[S]) =
    if st.dragKey.len == 0: return
    if st.choice.ok: st.state = st.choice.state
    st.dragKey = ""
    st.draw(st.state)                      # the held item glides home
    if not st.onMove.isNil: st.onMove()

  proc setState[S](st: Stage[S], s: S) =
    st.state = s
    st.draw(s)
    if not st.onMove.isNil: st.onMove()

  proc mount[S](id: string, w, h: float, init: S, render: Render[S],
                spec: proc (s: S, key: string): Behavior[S],
                backdrop: proc (s: S): string = nil, ghosts = false): Stage[S] =
    let host = document.getElementById(cstring(id))
    let chk = if ghosts: "checked" else: ""
    host.innerHTML = cstring(&"""<svg class="d2" viewBox="0 0 {w} {h}"><g class="bg"></g>""" &
      &"""<g class="fg"></g><g class="ghosts"></g></svg>""" &
      &"""<label class="ghost-toggle"><input type="checkbox" {chk}> show machinery</label>""")
    let st = Stage[S](state: init, render: render, spec: spec, backdrop: backdrop, w: w, h: h, showGhosts: ghosts)
    st.svg = host.querySelector("svg")
    st.bg = host.querySelector(".bg")
    st.ghosts = host.querySelector(".ghosts")
    st.fg = host.querySelector(".fg")
    let toLocal = proc (ev: Event): Vec =
      let (l, t, rw, rh) = rectOf(st.svg)
      let c = clientXY(ev)
      vec((c.x - l) * w / rw, (c.y - t) * h / rh)
    st.svg.addEventListener("pointerdown", proc (ev: Event) =
      let k = keyAt(ev)
      if k.isNil: return
      ev.preventDefault()
      capture(st.svg, ev)
      st.start($k, toLocal(ev)))
    st.svg.addEventListener("pointermove", proc (ev: Event) =
      if st.dragKey.len > 0: st.move(toLocal(ev)))
    st.svg.addEventListener("pointerup", proc (ev: Event) = st.finish())
    st.svg.addEventListener("pointercancel", proc (ev: Event) = st.finish())
    let box = host.querySelector(".ghost-toggle input")
    box.addEventListener("change", proc (ev: Event) =
      st.showGhosts = box.checked
      st.drawGhosts())
    st.draw(init)
    st
nbRawHtml: "</details>"

# ---------------------------------------------------------------- hero (hidden: it's choreography, not D2)
nbJsFromCode:
  proc rnd(): float {.importjs: "Math.random()".}
  proc now(): float {.importjs: "performance.now()".}
  proc raf(cb: proc (t: float)) {.importjs: "requestAnimationFrame(#)".}

  let hero = mount("hero", 320, 220, @["N", "I", "M", "B", "U", "S"], renderTiles, tileSpec, ghosts = true)
  let hand = svgNode("g")
  hand.innerHTML = """<circle r="15" fill="#1d1b16" fill-opacity=".18"/><circle r="7" fill="#1d1b16" stroke="#fff" stroke-width="2.5"/>"""
  hand.setAttribute("style", "pointer-events:none")
  hero.svg.appendChild(hand)

  let caption = document.getElementById("hero-caption")
  let panel = document.getElementById("hero-panel")
  let replay = document.getElementById("hero-replay")

  proc say(step, text: string) =
    caption.innerHTML = cstring(&"<b>{step}</b>{text}")

  hero.onMove = proc () =
    var html = """<div class="hd">reachable states · distance</div>"""
    if hero.dragKey.len == 0:
      html.add &"""<div class="idle">model = {hero.state}<br><br>grab a tile: the spec will list one state per slot,
        and each gets rendered speculatively.</div>"""
    else:
      let k = hero.dragKey
      for i, land in hero.picker.lands:
        let st = hero.state.moveTo(k, i)
        let d = norm(land - hero.at)
        let best = if hero.choice.ok and st == hero.choice.state: " best" else: ""
        var w = ""
        for l in st:
          let cls = if l == k: "k" else: ""
          w.add &"""<span class="{cls}">{l}</span>"""
        html.add &"""<div class="row{best}"><span class="w">{w}</span>""" &
          &"""<span><div class="bar" style="width:{min(100.0, d / 2.6):.0f}%"></div></span><span class="d">{d:.0f}</span></div>"""
    panel.innerHTML = cstring(html)

  var auto = true
  var t0 = now()
  var key = "B"
  var dest = 0
  var fromP, toP, rest: Vec
  rest = vec(300, 205)
  var phase = -1

  proc ease(t: float): float =
    if t < 0.5: 4*t*t*t else: 1 - pow(-2*t + 2, 3) / 2
  proc lerp(a, b: Vec, t: float): Vec = a + vec((b.x - a.x) * t, (b.y - a.y) * t)
  proc bez(a, c, b: Vec, t: float): Vec = lerp(lerp(a, c, t), lerp(c, b, t), t)

  proc plan() =
    let w = hero.state
    key = w[int(rnd() * w.len.float) mod w.len]
    let here = w.find(key)
    dest = here
    while dest == here: dest = int(rnd() * w.len.float) mod w.len
    fromP = slot(here)
    toP = slot(dest)
    t0 = now()
    phase = 0

  proc tick(t: float) =
    if not auto:
      hand.setAttribute("opacity", "0")
      return
    hand.setAttribute("opacity", "1")
    let e = now() - t0
    var p = rest
    if e < 900:
      p = lerp(rest, fromP, ease(e / 900))
      if phase < 1: say("1 · GRAB", &"The pointer goes down on <code>{key}</code>."); phase = 1
    elif e < 3400:
      if phase < 2:
        hero.start(key, fromP)
        say("2 · ASK THE SPEC", &"<code>tileSpec</code> lists 6 reachable states (<code>{key}</code> moved to each slot). " &
          "Each is rendered speculatively, which gives the coral dots: where the tile would land.")
        phase = 2
      let u = ease(clamp((e - 1500) / 1900, 0, 1))
      let mid = lerp(fromP, toP, 0.5) + vec(0, -70)
      p = bez(fromP, mid, toP, u) + vec(0, 6 * sin(e / 140))
      if e > 1500 and phase < 3:
        say("3 · FLOAT & PICK", "The tile floats under the pointer. Whichever state lands it <i>closest</i> " &
          "is shown for the other tiles, and they slide to make room.")
        phase = 3
      hero.move(p)
    elif e < 5600:
      if phase < 4:
        hero.finish()
        say("4 · COMMIT", "On release the closest state becomes the model, and the tile glides into its slot. " &
          "No hit-testing, no drop zones, no handlers.")
        phase = 4
      p = lerp(toP, rest, ease(clamp((e - 4300) / 900, 0, 1)))
    else:
      plan()
    hand.setStyle("transform", tr(p))
    raf(tick)

  hero.svg.addEventListener("pointerdown", proc (ev: Event) =
    if auto:
      auto = false
      say("YOUR TURN", "Drag any tile. Toggle <i>show machinery</i> to hide the speculative landing spots."))
  replay.addEventListener("click", proc (ev: Event) =
    if not auto:
      auto = true
      plan()
      raf(tick))
  hero.onMove()
  plan()
  raf(tick)

nbRawHtml: """<h2><span class="num">03 · LEGALITY FOR FREE</span>Tower of Hanoi</h2>"""

nbText: """
Constraints just become *fewer states*. Only a top disk is draggable, and it can only reach pegs whose top disk is
larger. There's no validation anywhere: try dropping a big disk on a small one and it simply has nowhere to settle.
"""

nbCodeAnd(nbJsFromCode):
  type Hanoi = object
    pegs: array[3, seq[int]]   # disk sizes, bottom → top
    moves: int

  proc pegX(i: int): float = 110 + i.float * 190

  proc renderHanoi(h: Hanoi): seq[Item] =
    for p, disks in h.pegs:
      for level, d in disks:
        let w = 40.0 + d.float * 28
        result.add Item(key: &"disk{d}", pos: vec(pegX(p), 196 - level.float * 30),
          svg: &"""<rect x="{-w/2}" y="-14" width="{w}" height="28" rx="9" fill="{hues[d]}" stroke="#1d1b16" stroke-width="3"/>""")

  proc hanoiSpec(h: Hanoi, key: string): Behavior[Hanoi] =
    let d = parseInt(key[4 .. ^1])
    var src = -1
    for i, disks in h.pegs:
      if disks.len > 0 and disks[^1] == d: src = i
    if src < 0: return nil                           # buried disks don't move
    var states = @[h]
    for dst in 0 .. 2:
      if dst != src and (h.pegs[dst].len == 0 or h.pegs[dst][^1] > d):
        var next = h
        discard next.pegs[src].pop
        next.pegs[dst].add d
        inc next.moves
        states.add next
    closest(states)

nbRawHtml: """<div class="stage" id="hanoi"></div><div class="controls"><button id="hanoi-reset">reset</button></div>"""

nbJsFromCode:
  let hanoiStart = Hanoi(pegs: [@[5, 4, 3, 2, 1], @[], @[]])
  proc hanoiBackdrop(h: Hanoi): string =
    result = """<rect x="20" y="212" width="560" height="12" rx="6" fill="#1d1b16"/>"""
    for i in 0 .. 2:
      result.add &"""<rect x="{pegX(i) - 5}" y="40" width="10" height="175" rx="5" fill="#cfc5ad"/>"""
    let note = if h.moves == 31: " · optimal ✦" else: " (31 is optimal)"
    let msg = if h.pegs[2].len == 5: &"solved in {h.moves} moves{note}" else: &"moves: {h.moves}"
    result.add &"""<text class="mono" x="300" y="26" text-anchor="middle" font-size="15" fill="#6b6457">{msg}</text>"""
  let hanoi = mount("hanoi", 600, 240, hanoiStart, renderHanoi, hanoiSpec, hanoiBackdrop)
  document.getElementById("hanoi-reset").addEventListener("click", proc (ev: Event) = hanoi.setState(hanoiStart))

nbRawHtml: """<h2><span class="num">04 · MANY VIEWS, ONE SPEC</span>Permutation playground</h2>"""

nbText: """
This is a nod to the *Permutation Playground* in Andrew's thread. One model, `seq[int]`, drawn three ways:
two-line notation, a permutation matrix and cycle notation. Tiles and matrix dots share **the same spec**, "swap me
with any position". Drag a tile sideways or a dot along its row and both views stay in step, because both are
renders of the same speculative states.
"""

nbCodeAnd(nbJsFromCode):
  const n = 5

  proc swapped(p: seq[int], i, j: int): seq[int] =
    result = p
    swap(result[i], result[j])

  proc cycles(p: seq[int]): seq[seq[int]] =
    var seen = newSeq[bool](p.len)
    for i in 0 ..< p.len:
      if not seen[i] and p[i] != i + 1:
        var c: seq[int]
        var j = i
        while not seen[j]:
          seen[j] = true
          c.add j + 1
          j = p[j] - 1
        result.add c

  proc colX(i: int): float = 50 + i.float * 54
  proc matX(i: int): float = 368 + i.float * 46
  proc matY(v: int): float = 66 + float(v - 1) * 46

  proc renderPerm(p: seq[int]): seq[Item] =
    for i, v in p:
      let hue = hues[v mod hues.len]
      result.add Item(key: &"t{v}", pos: vec(colX(i), 132), svg:
        &"""<rect x="-22" y="-22" width="44" height="44" rx="10" fill="{hue}" stroke="#1d1b16" stroke-width="2.5"/>""" &
        &"""<text y="8" text-anchor="middle" font-size="22" font-weight="700">{v}</text>""")
      result.add Item(key: &"m{v}", pos: vec(matX(i), matY(v)), svg:
        &"""<circle r="16" fill="{hue}" stroke="#1d1b16" stroke-width="2.5"/>""" &
        &"""<text y="6" text-anchor="middle" font-size="15" font-weight="700">{v}</text>""")

  proc permSpec(p: seq[int], key: string): Behavior[seq[int]] =
    let i = p.find(parseInt(key[1 .. ^1]))
    closest(toSeq(0 ..< n).mapIt(p.swapped(i, it)))

  echo "cycles of 3 1 4 2 5 → ", cycles(@[3, 1, 4, 2, 5])

nbRawHtml: """<div class="stage" id="perm"></div>"""

nbJsFromCode:
  proc permBackdrop(p: seq[int]): string =
    result = """<text x="26" y="34" font-size="12" class="mono" fill="#6b6457">TWO-LINE NOTATION</text>"""
    for i in 0 ..< n:
      result.add &"""<text x="{colX(i)}" y="80" text-anchor="middle" font-size="22" fill="#6b6457">{i + 1}</text>"""
      result.add &"""<path d="M{colX(i)},88 v16" stroke="#cfc5ad" stroke-width="2"/>"""
    result.add """<text x="345" y="34" font-size="12" class="mono" fill="#6b6457">PERMUTATION MATRIX</text>"""
    for i in 0 ..< n:
      for v in 1 .. n:
        result.add &"""<rect x="{matX(i) - 23}" y="{matY(v) - 23}" width="46" height="46" fill="none" stroke="#e6dfcf"/>"""
    let cs = cycles(p)
    var txt = if cs.len == 0: "id" else: ""
    var transp = 0
    for c in cs:
      txt.add "(" & c.join(" ") & ")"
      transp += c.len - 1
    let parity = if transp mod 2 == 0: "even" else: "odd"
    result.add """<text x="26" y="214" font-size="12" class="mono" fill="#6b6457">CYCLE NOTATION</text>"""
    result.add &"""<text x="26" y="252" font-size="30" font-weight="700" class="mono">{txt}</text>"""
    result.add &"""<text x="26" y="282" font-size="14" class="mono" fill="#6b6457">sign: {parity} · {transp} transpositions</text>"""
  discard mount("perm", 600, 300, @[3, 1, 4, 2, 5], renderPerm, permSpec, permBackdrop)

nbRawHtml: """<h2><span class="num">05 · COMPOSING BEHAVIOURS</span>A dial for a continuous parameter</h2>"""

nbText: """
Not every drag picks from a list. `vary` takes a function from a real parameter to a state and searches along it.
The knob below sets `k` in the *times-table circle*: point `i` of 200 joins to point `k·i`. `k = 2` gives a cardioid,
`k = 3` a nephroid, and in between the whole thing morphs. That's my kind of dynamical system.

The three buttons swap the spec live. Each is one line, built from the operators above:
"""

nbCodeAnd(nbJsFromCode):
  const ctr = vec(300, 300)
  proc knobAngle(k: float): float = degToRad(120 + (k - 1) / 99 * 300)
  proc ring(a: float, r = 262.0): Vec = ctr + vec(r * cos(a), r * sin(a))

  proc renderDial(k: float): seq[Item] =
    @[Item(key: "knob", pos: ring(knobAngle(k)), svg:
      """<circle r="17" fill="#ffe953" stroke="#1d1b16" stroke-width="3"/><circle r="4" fill="#1d1b16"/>""")]

  let continuous = vary(proc (t: float): float = t, 1, 100, samples = 120)
  let integers = closest(toSeq(1 .. 100).mapIt(it.float))
  let sticky = integers.within(5).orElse(continuous)       # magnetic integers

  var dialMode = "sticky"
  proc dialSpec(k: float, key: string): Behavior[float] =
    case dialMode
    of "vary": continuous
    of "closest": integers
    else: sticky

nbRawHtml: """
<div class="controls" id="dial-modes">
  <button data-mode="vary">vary(t ↦ t, 1, 100)</button>
  <button data-mode="closest">closest(1 .. 100)</button>
  <button data-mode="sticky" class="on">integers.within(5).orElse(vary)</button>
</div>
<div class="stage" id="dial"></div>"""

nbJsFromCode:
  proc dialBackdrop(k: float): string =
    const N = 200
    let a0 = knobAngle(1)
    let a1 = knobAngle(100)
    let (s, e) = (ring(a0), ring(a1))
    result = &"""<path d="M{s.x},{s.y} A262 262 0 1 1 {e.x},{e.y}" fill="none" stroke="#e6dfcf" stroke-width="16" stroke-linecap="round"/>"""
    for m in 1 .. 100:
      let a = knobAngle(m.float)
      let big = m mod 10 == 0 or m == 1
      let r2 = if big: 245.0 else: 253.0
      let sw = if big: 2 else: 1
      let (p, q) = (ring(a, 270), ring(a, r2))
      result.add &"""<line x1="{p.x}" y1="{p.y}" x2="{q.x}" y2="{q.y}" stroke="#9a9483" stroke-width="{sw}"/>"""
      if big:
        let t = ring(a, 230)
        result.add &"""<text x="{t.x}" y="{t.y + 4}" font-size="11" class="mono" text-anchor="middle" fill="#9a9483">{m}</text>"""
    for i in 0 ..< N:
      let a = 2 * PI * i.float / N - PI / 2
      let b = 2 * PI * k * i.float / N - PI / 2
      let (p, q) = (ctr + vec(205 * cos(a), 205 * sin(a)), ctr + vec(205 * cos(b), 205 * sin(b)))
      let hue = (i.float / N * 300 + 190) mod 360
      result.add &"""<line x1="{p.x:.1f}" y1="{p.y:.1f}" x2="{q.x:.1f}" y2="{q.y:.1f}" stroke="hsl({hue:.0f},55%,42%)" stroke-opacity=".55" stroke-width=".9"/>"""
    result.add &"""<text x="300" y="586" text-anchor="middle" font-size="28" font-weight="700" class="mono">k = {k:.2f}</text>"""

  let dial = mount("dial", 600, 600, 2.0, renderDial, dialSpec, dialBackdrop, ghosts = true)
  let modes = document.getElementById("dial-modes")
  modes.addEventListener("click", proc (ev: Event) =
    proc modeOf(ev: Event): cstring {.importjs: "(#.target.closest('button')?.dataset.mode ?? null)".}
    proc setOn(root: Element, mode: cstring) {.importjs:
      "#.querySelectorAll('button').forEach(b => b.classList.toggle('on', b.dataset.mode === #))".}
    let m = modeOf(ev)
    if m.isNil: return
    dialMode = $m
    modes.setOn(m)
    dial.draw(dial.state))

nbText: """
With `vary` the knob glides anywhere. With `closest` it clicks between 100 integer states. The third spec reads as plain
English: *snap to an integer if you're within 5px of one, otherwise vary freely*. That gives you magnetic detents,
and you didn't write any new dragging code to get them. This is what the paper means by **composable drag behaviours**.

The paper goes further than this port. It has floating vs. non-floating drags, chained drags where the state you
land in hands off to a new spec, drags that spawn and delete elements, and a cleverer continuous solver.
Still, a pure render function plus `locate` gets you a long way, in a handful of Nim.
"""

nbRawHtml: """<h2><span class="num">06 · REFERENCES</span>Go read the real thing</h2>"""

nbText: """
- **Paper.** Joshua Horowitz, Andrew Blinn, Jeffrey Heer. [*Declarative Dragging*](https://andrewblinn.com/papers/D2.pdf), UIST 2026, Best Paper.
- **Explorable supplement and project page.** [declarative-dragging.github.io](https://declarative-dragging.github.io/): interactive figures, the backstory (Andrew's 2023 whiteboard sketch for tree rewriting) and the math-game origins.
- **Library.** [Dragology](https://github.com/declarative-dragging/dragology): declarative dragging for SVG on the web (TypeScript, React).
- **Awards list.** [UIST 2026 awards](https://uist.acm.org/2026/awards/).
- **Other ports in the wild.** [playhtml prototype](https://github.com/spencerc99/playhtml/pull/678) with `closest`, `vary` and FLIP animation, and [moonshine adopting Dragology](https://github.com/enjalot/moonshine/pull/40).
- **Ancestors.** Satyanarayan, Wongsuphasawat & Heer, [*Declarative Interaction Design for Data Visualization*](https://idl.uw.edu/papers/reactive-vega) (UIST 2014), and Ralph Thomas's [Slalom: towards declarative touch interactions](http://iamralpht.github.io/constraints).

Built with [nimib](https://github.com/pietroppeter/nimib). The engine blocks use `nbCodeAnd(nbJsFromCode)`, so each runs
natively at build time *and* ships to the browser; the runtime uses `nbCodeDisplay(nbJsFromCode)`.
Hit *show source* below for the whole notebook.
"""

nbSave
