## Faretto: can Nim code be alive? Pharo's liveness (image, inspector, become, MetaLinks,
## the debugger), explained to a Nim programmer, and a small live VM over Nimony's NIF
## (faretto/) that does a little of it. Every faretto block on this page runs when the page
## is built. Build: sh deps.sh && nim r index.nim (from this folder; writes ../index.html).
## Needs libpcre3, and Nimony's `nimony` on the PATH (or $NIMONY).
import std/[os, strformat, strutils, monotimes, times]
import nimib
import tabelline except Value
import tabelline/nimib
import lib/[style, blocks, build]
import faretto/[vm, live]
import review          # tabelline's review mode, from claude-artifacts shared/review (unchanged copy)

nimonyBin = getEnv("NIMONY", findExe("nimony"))
doAssert nimonyBin.len > 0, "faretto needs nimony: put it on the PATH or set $NIMONY"
removeDir scratch

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.title = "Faretto: can Nim code be alive, like Pharo?"
nb.useExplainerStyle
nbReview(tpage = "faretto", tsource = "faretto/src/index.nim")

const
  talk = "https://pretalx.com/compute-paris-2026/talk/AN8PTZ/"
  pharoRepo = "https://github.com/pharo-project/pharo"
  pharoVm = "https://github.com/pharo-project/pharo-vm"
  metaLinkSrc = "https://github.com/pharo-project/pharo/blob/Pharo14/src/Reflectivity/MetaLink.class.st"
  reflectivityPaper = "https://arxiv.org/abs/2002.06182"
  nimonyRepo = "https://github.com/nim-lang/nimony"
  nimonyDesign = "https://github.com/nim-lang/nimony/blob/master/doc/design.md"
  squeakJs = "https://squeak.js.org/"
  srcDir = "https://github.com/pietroppeter/claude-artifacts/tree/main/faretto/src"

let
  vmLines = lineCount("faretto/vm.nim")
  nifLines = lineCount("faretto/nif.nim")
  liveLines = lineCount("faretto/live.nim")
  nimonyV = nimonyVersion()
  nimonyC = nimonyCommit()

nbText: "# Faretto: can Nim code be alive?"

nbPrompt("Pietro", "26 Nov 2026", """
Listening to Marcus Denker talk on Pharo. Could Nim with Nimony and NIF actually make code
"alive" and have a backend/VM that makes Nim code like in pharo? Do a small playful exploration
for me to learn more about this problem space (teach me about pharo), use a lighthouse inspired
theme and build a faretto PoC. Go Wild and merge to artifacts
""")

nbLede: &"""
In Pharo you never stop the program to change it. The program is a world of live objects,
and you edit it from the inside, while it runs: you redefine a method and the next call uses it,
you open any object and look into it, you fix a bug in the debugger and carry on. Nim works the
other way: write, compile, run, stop, again. This page explains what Pharo does and how, and
then builds **faretto** (Italian for a small lighthouse): a toy live VM, {vmLines + nifLines + liveLines}
lines of Nim, that runs the *type-checked NIF* that [Nimony]({nimonyRepo}) (the compiler of
Nim 3) writes, and gets a surprising amount of Pharo's liveness from it. The lighthouse below
is running on it, in your browser.
"""

nbTldr: &"""
- **Pharo is alive** because the program is an *image*, a snapshot of every object (classes,
  methods and stack frames included) that you change while it runs. Late binding makes a new
  method visible at the next call; `become:` swaps two objects everywhere; the debugger, the
  inspector and Marcus Denker's **MetaLinks** are ordinary Pharo code poking at that world.
- **Nimony gives us the raw material**: NIF, a tree format with resolved symbols and line
  information, and a front end that type-checks a module in about 25 ms.
- **faretto** runs that NIF in a tree-walking interpreter, and gets redefinition while running,
  an inspector, `become`, type reshaping with instance migration, MetaLinks, a halt/restart
  debugger, and an image saved as NIF that another process resumes.
- **The catch** is speed (here hundreds of times slower than native) and everything that
  native Nim does with memory layouts. A plausible design is a live interpreter during development,
  native code from the same NIF for production.
- **Static types help** liveness more than they hurt: Nimony rejects a bad redefinition
  before it reaches a running image, where Pharo would accept it and fail later.
"""

# ============================================================================================ 1
nbText: &"""
## Pharo, in five minutes

[Pharo]({pharoRepo}) is a Smalltalk. It started in 2008 as a fork of Squeak, which descends
from Smalltalk-80 at Xerox PARC, and is developed in large part at Inria in Lille, where Marcus Denker is
a researcher. His talk at Compute Paris was called
[*Pharo: a Live Environment Where Code, Data, and Model Are One*]({talk}). That title is the
idea in one line, so let's unpack it.

**The image.** When you start Pharo you don't start a program: you wake up an *image*, a file
that holds a snapshot of the whole object memory as it was when it was last saved. Windows,
open debuggers, half-finished computations, the compiler, the class `Object` itself: all are
objects in that memory, and saving the image freezes them all. Next to it there is a `.changes`
file, a log of every piece of source you have accepted, and a `.sources` file with the source of
the base system.

**Everything is an object.** A class is an object (an instance of its metaclass). A method is
an object (a `CompiledMethod`, kept in the class's method dictionary, keyed by its selector). A running
call is an object too: a `Context`, and `thisContext` gives you the current one, with its
receiver, its variables, and the context that called it. So tools are just programs that look at
and change these objects.

**Late binding.** `capo tick` means: send the message `tick` to `capo`. Which code runs is
looked up when the message is sent, in `capo`'s class. So when you edit `tick` in the code
browser and press *Accept*, Pharo compiles it and puts the new `CompiledMethod` in the
dictionary. A loop that is running right now picks it up at its next send. Nothing restarts.
"""

nbTable toTableData(@[
  (pharo: "**image**", what: "a snapshot of all objects, saved and resumed", nim: "nothing: a Nim program starts from `main` every time"),
  (pharo: "**Accept** a method", what: "compile one method and install it, while running", nim: "recompile and restart. `--hotCodeReloading` (experimental) swaps code of a running program, with limits"),
  (pharo: "**inspector**", what: "open any live object, see and edit its fields", nim: "a debugger (gdb) or `echo repr(x)`"),
  (pharo: "**debugger**", what: "the live stack: edit a method, *Restart* its frame, *Proceed*", nim: "gdb: look, but not change the code"),
  (pharo: "**`thisContext`**", what: "the current stack frame, as an object", nim: "`getStackTrace()`, as a string"),
  (pharo: "**`become:`**", what: "swap two objects' identities everywhere", nim: "nothing like it"),
  (pharo: "**MetaLinks**", what: "attach code to any node of a method, at run time", nim: "macros, but only at compile time"),
  (pharo: "**doesNotUnderstand:**", what: "a missing method is a message the object can catch", nim: "a compile error: the call does not type-check"),
]), rownameCol = "pharo":
  tabHeader "Pharo's live tools, and what a Nim programmer has"
  colsLabel:
    pharo: "Pharo"
    what: "what it is"
    nim: "Nim today"
  fmtMarkdown ["pharo", "what", "nim"]

nbText: &"""
### Denker's corner: reflection below the method

A Smalltalk system has always been able to look at itself (*reflection*): ask an object for its
class, a class for its methods. Marcus Denker's research, since his PhD in Bern, has been about
taking that *below the method*, to single expressions. In Pharo that is **Reflectivity**, and
its central idea is the **MetaLink**. This is the comment of the class, in
[Pharo's sources]({metaLinkSrc}):
"""

nbText: """
> Metalinks are used to annotate AST nodes. An annotated AST is expanded, compiled and
> executed on the fly [...]
> For a given node, metalinks can be put at different positions:
> **before** [...], **instead** [...], **after** [...]
"""

nbText: &"""
A MetaLink says: *when this node runs, also call that object* (before it, after it, or instead of
it), optionally only when a condition holds. Breakpoints, watchpoints on a variable, code
coverage, logging, and even the *object-centric* debugger (break only when *this* object
does something) are all MetaLinks, installed and removed at run time, with no change to the
source. A [paper on its first 10+ years]({reflectivityPaper}) tells the story. Pharo also makes
instance variables first-class objects (*slots*), which is the same idea applied to fields.
We will build MetaLinks for faretto in [Fl(9)](#metalinks).
"""

# ============================================================================================ 2
nbText: &"""
## How is Pharo built? In Pharo

Pietro asked this while I was writing the page, and the answer is part of what makes Pharo what it is.
It has two layers:

- **The image** (the compiler, the class library, the IDE, the debugger) is Pharo code running on
  itself. The [pharo repository]({pharoRepo}) has about 600 packages of it, as text files in
  Git. Since Pharo 7 the release image is *bootstrapped* from those files, rather than being the
  last image, saved again.
- **The VM** ([pharo-vm]({pharoVm}), a fork of OpenSmalltalk-VM) has the bytecode interpreter,
  the Cog JIT compiler, the Spur memory manager and garbage collector, and the *primitives* (a few
  hundred operations the image can't do itself, such as adding two machine integers or
  reading a file). It is written in **Slang**, a subset of Smalltalk that reads like C. You
  develop the VM inside Pharo, where it runs as a simulator you can debug with Pharo's own
  tools (that's VMMaker); for a release, Slang is translated to C and compiled. In the repository:
  `smalltalksrc/Slang`, `smalltalksrc/VMMaker`.

So the only part not written in Smalltalk is the C that the translator generates, plus a thin
layer for each platform.
"""

nbNote(nkAside, &"""
**A Pharo-in-Nim project, as a ladder.** (1) The Smalltalk-80 "Blue Book" VM: the specification
is public and small (bytecodes, an object memory, about a hundred primitives), and the original
Xerox image still runs. One person can do it; [SqueakJS]({squeakJs}) did the much bigger
Squeak VM in JavaScript. (2) A Spur VM that boots a real Pharo image: a big step up (the image format,
hundreds of primitives, FFI). (3) The very Nim twist: a Nim backend for Slang, so that VMMaker
generates the Pharo VM as Nim instead of C.
""")

# ============================================================================================ 3
nbText: &"""
## Nim, Nimony and NIF

Nim already has pieces of liveness. The Nim 2 compiler contains a VM that runs macros and
NimScript at compile time, and libraries embed it as a scripting language. There is an experimental
hot code reloading mode. REPLs such as INim fake it by recompiling. None of them gives you a
world of objects that you change from the inside.

[Nimony]({nimonyRepo}) is the compiler that will become Nim 3. Its phases talk to each other
in **NIF**, a text format for trees, and the [design document]({nimonyDesign}) says what NIF is
for, including this, which is the opposite of Pharo's choice:
"""

nbText: """
> **Compile-time evaluation:** When the compiler needs to run code at compile time [...] it
> does not use a separate interpreter. It turns the snippet into NIF [...], runs it through the
> full pipeline [...] to produce a native executable, runs that executable, and consumes the result.
"""

nbText: &"""
Plugins (Nimony's macros) work the same way: compiled programs that read and write NIF.
So Nimony bets on compiling everything, and not interpreting anything. But the NIF it writes after
type-checking a module (the `.s.nif` file) is exactly what a live system needs: every symbol is
resolved (`tick.0.` is *this* `tick`), generics are instantiated, templates are expanded, string
formatting is lowered to calls, and every node carries its line in the source. This is
`proc lit` of the lighthouse module, as `nimony check` writes it (line information
removed):
"""

let litNif = block:
  let l = boot(readFile("examples/lanterna.nim"), scratch / "show", "lanterna")
  l.vm.procNode("lit").toNif

nbTerm("lanterna.s.nif, proc lit", litNif)

nbText: &"""
Read it as Lisp: `(let :p.0 . . (i 64) (mod (i 64) t.0 6))` declares `p` of type `int64` as `t mod 6`.
The question of this page becomes: **what if something ran this tree directly, and kept the
objects around?** (Built with {nimonyV}, commit {nimonyC}.)
"""

# ============================================================================================ 4
nbText: &"""
## faretto: a live image over NIF

faretto has three parts ([sources]({srcDir})):
"""

nbSteps("One proc of the lighthouse module, from source to a running image.", [
  ("✍️", "Nim source", "the keeper writes or changes a proc"),
  ("🔎", "nimony check", "parses and type-checks the module, writes `.s.nif` (no C, no binary)"),
  ("📖", "the image", "procs by symbol (a method dictionary), an object table, globals, a change log"),
  ("💡", "the VM", "walks the NIF tree of a proc each time it is called"),
])

nbText: &"""
- `faretto/nif.nim` ({nifLines} lines): reads and writes NIF.
- `faretto/vm.nim` ({vmLines} lines): the image and the interpreter, with the inspector, `become`,
  MetaLinks, the debugger and saving the image. It does not import `os`, so it also compiles to
  JavaScript.
- `faretto/live.nim` ({liveLines} lines): hands source to `nimony check` and loads what comes back.

The program it runs is an ordinary Nim module, `examples/lanterna.nim`. It compiles and runs with
Nimony as it is (`halt` does nothing there):
"""

nbSource("examples/lanterna.nim", topen = true)

nbText: """
Boot an image from it. faretto checks the module with Nimony, loads its types, procs and
globals, and runs its top-level code once, like loading code into a fresh Pharo image:
"""

nbCode:
  let keeper = boot(readFile("examples/lanterna.nim"), scratch / "page", "lanterna")
  let faro = keeper.vm
  let capo = faro.global("capo")
  echo faro.output     # what the module's top-level echo printed
  echo faro.call("night", capo, intV(12)).s
  echo faro.call("report", capo).s

nbText: """
The `capo` object outlives every call: the second night starts at second 12. Here is the image's
method dictionary. Each entry is the NIF tree that Nimony wrote, with its source next to it:
"""

block:
  var rows: seq[tuple[name, version, nodes, lines: string]]
  for sym, p in faro.img.procs:
    var n = 0
    for x in walk(p.body): inc n
    rows.add (name: "`" & p.name & "`", version: $p.version, nodes: $n, lines: $p.source.countLines)
  nbTable toTableData(rows), rownameCol = "name":
    tabHeader "The method dictionary of the boot image"
    colsLabel:
      name: "proc"
      version: "version"
      nodes: "NIF nodes"
      lines: "source lines"
    fmtMarkdown ["name"]

# ============================================================================================ 5
nbText: """
## The lighthouse is running

This is faretto, compiled to JavaScript with `nim js`, running the boot image of this page.
Every 450 ms it calls the image's own `tick(capo)` and lights the lamp when the result is `█`.
Your browser can't run Nimony, so the page build did: each chip below holds the NIF that
`nimony check` wrote for one version of `lit`, and accepting it replaces one entry of the method
dictionary while the light keeps turning. The names are real light characteristics, as
nautical charts print them: *Fl(2)* is a group of two flashes, *Oc* occulting, *Iso* isophase,
*Mo(U)* the letter U in Morse.
"""

nbPlayground(playgroundVariants(), bootImage(), playgroundJs())

nbText: """
Things to try: accept a few versions and watch the change log. Take a snapshot, change
things, restore: the whole image (objects and code) goes back. `become` swaps the LED and
the oil lamp, and the beam turns amber because `capo.lamp` is now the other object. The MetaLink
counts every write to `flashes`, without changing a line of source.
"""

# ============================================================================================ 6
nbText: """
## Accept: change a proc while it runs

The same thing, from Nim. `accept` puts the new proc into the image's copy of the module,
lets Nimony check the *whole* module (so the new proc must fit the rest), and swaps in the procs
whose NIF changed. Nothing is run again, and `capo` keeps its clock:
"""

nbCode:
  let r = keeper.accept("""
proc lit(t: int): bool =
  ## Fl(3) 10s: three flashes, then dark
  let p = t mod 10
  p == 0 or p == 2 or p == 4
""")
  echo "changed: ", r.changed
  echo faro.call("night", capo, intV(20)).s
  echo faro.call("report", capo).s

nbText: &"""
Nimony checked the module in about {keeper.lastMillis.int} ms. Comparing "did this proc change" took
a little care: Nimony numbers local symbols for the whole module (`result.3`), so a change in one
proc renumbers the locals of the procs after it. faretto compares trees with the locals
renumbered per proc (`canonical` in `vm.nim`).
"""

nbNote(nkPharo, """
In Pharo this is *Accept* in a code browser: the new `CompiledMethod` goes into the method
dictionary, and the old one stays alive as long as a running context still uses it. faretto
does the same: a call that is running keeps the tree it started with, and the next call gets the new one.
""")

# ============================================================================================ 7
nbText: """
## The compiler says no

Here Nim has something Pharo doesn't. Pharo accepts almost any method and fails later, when
it runs (with `doesNotUnderstand:`, in the debugger). Nimony refuses a redefinition that doesn't
type-check, before it reaches the running image, and the image keeps the old proc:
"""

nbCode:
  try:
    discard keeper.accept("proc lit(t: int): bool =\n  t mod 6")
  except VMError as e:
    echo "rejected: ", e.msg
  echo faro.call("night", capo, intV(10)).s    # still Fl(3)

nbText: """
The flip side: Pharo lets you call a method that doesn't exist yet, and write it in the debugger
when the call happens. In Nim the call itself doesn't type-check. A live Nim would need stubs, or
a mode in which a missing proc becomes a hole the debugger can fill.
"""

# ============================================================================================ 8
nbText: """
## The inspector, and `become`

faretto's heap is an **object table**: a reference is an index into a table of objects, as in
the original Smalltalk-80. That makes the inspector easy, and `become` trivial:
"""

nbCode:
  echo "capo  -> ", faro.inspect(capo)
  echo "spare -> ", faro.inspect(faro.global("spare"))
  faro.img.become(faro.field(capo, "lamp"), faro.global("spare"))
  echo faro.call("report", capo).s
  echo "spare -> ", faro.inspect(faro.global("spare"))

nbText: """
`a become: b` swaps two objects' identities: every reference to the LED lamp now finds the oil
lamp, and every reference to the oil lamp finds the LED. With an object table that's one swap
of two entries. Squeak dropped the object table for speed, and for years `become:` meant
walking the whole heap. Pharo's Spur memory manager made it cheap again by turning the old object
into a *forwarder*, fixed lazily when someone uses it.
"""

# ============================================================================================ 9
nbText: """
## Change a type, keep its objects

`become` matters most when a *type* changes. Add a field to `Lamp`, and every existing lamp is
the wrong shape. Pharo's class builder makes a new object of the new shape for each old one, copies the
fields over, and `becomeForward:`s the old one into the new one, so no reference notices. faretto does the
same when an accepted type section changes a type's fields:
"""

nbCode:
  let r2 = keeper.accept("""
type
  Lamp = ref object
    kind: string
    watts: int
    color: string
  Beacon = ref object
    name: string
    lamp: Lamp
    clock: int
    flashes: int

proc report(b: Beacon): string =
  let c = if b.lamp.color == "": "white" else: b.lamp.color
  b.name & ": " & $b.flashes & " flashes, " & b.lamp.kind & " lamp, " & c & " light"
""")
  echo "reshaped: ", r2.reshaped, ", changed: ", r2.changed
  faro.setField(faro.field(capo, "lamp"), "color", strV("red"))
  echo faro.call("report", capo).s
  echo "capo -> ", faro.inspect(capo)

nbNote(nkCareful, """
This is where native code gets hard. A compiled Nim proc knows that `watts` is at byte offset 8
of a `Lamp`; adding a field changes the layout, so every proc that touches a `Lamp` must be
recompiled, and every live `Lamp` moved. faretto gets away with it because its objects are
tables of fields. Nimony's incremental compilation knows which modules depend on which, which
is the information needed to do it for real.
""")

# ============================================================================================ 10
nbText: """
## MetaLinks <a id="metalinks"></a>

A faretto MetaLink is a small object put on a NIF node: when the interpreter reaches that node,
it runs the link *before*, *after* or *instead* of it. Because the NIF keeps line information
and resolved symbols, it's easy to pick the nodes: "the body of `tick`", "every write to the field
`flashes`" (a watchpoint), "line 25". Here are a counter and a watchpoint, then the counter goes away:
"""

nbCode:
  let counter = MetaLink(name: "count ticks", control: before)
  faro.bodyOf("tick").install counter
  var seen: seq[string]
  let watch = MetaLink(name: "watch flashes", control: after,
    action: proc (faro: VM; n: Node; f: Frame): Value =
      let b = f.local("b")
      seen.add &"""flash {faro.field(b, "flashes").i} at t={faro.field(b, "clock").i}"""
      nilV())
  for n in faro.assignmentsTo("flashes"): n.install watch
  echo faro.call("night", capo, intV(10)).s
  echo counter.hits, " ticks counted"
  echo seen
  faro.bodyOf("tick").uninstall counter

nbText: """
The source didn't change, and the procs weren't recompiled. A link costs nothing once it is removed,
and when there are no links the interpreter checks one empty list per node. In Pharo, a link makes the method recompile
with a hook in it; in an interpreter, the hook is free to add.
"""

# ============================================================================================ 11
nbText: """
## The debugger: halt, look, fix, restart

`halt()` is a proc of the lighthouse module that does nothing when compiled. faretto treats
a call to it as a breakpoint: it hands the live stack (`thisContext`) to a debugger, here a
proc playing the keeper. The keeper looks at the stack, accepts a fixed `tick` without the halt
(and with a new glyph), and asks to **restart** the frame. faretto throws away that activation of
`tick` and runs it again, with the same arguments and the *new* body, and the night goes on:
"""

nbCode:
  discard keeper.accept("""
proc tick(b: Beacon): string =
  let on = lit(b.clock)
  if on: inc b.flashes
  inc b.clock
  if b.clock mod 10 == 9: halt()     # the keeper wants a look
  glyph(on)
""")
  faro.onHalt = proc (faro: VM; f: Frame): HaltAction =
    echo "halted, the stack:\n", faro.thisContext
    discard keeper.accept("""
proc tick(b: Beacon): string =
  let on = lit(b.clock)
  if on: inc b.flashes
  inc b.clock
  if on: "☼" else: "·"
""")
    restart
  echo faro.call("night", capo, intV(12)).s
  echo faro.call("report", capo).s

nbText: """
The first glyphs are the old `tick`, the rest the new one, in one call of `night`. Restarting
doesn't undo side effects: the abandoned activation had already moved the clock (and maybe
counted a flash), so one second is skipped, which is exactly what Pharo's *Restart* does too:
it rewinds the frame, not the objects.
"""

# ============================================================================================ 12
let imageFile = scratch / "lanterna.image.nif"
writeFile(imageFile, saveImage(faro.img))
let cli = buildCli()

nbText: &"""
## The image is a NIF file

`saveImage` writes the whole image as one NIF file ({getFileSize(imageFile)} bytes): the types,
every proc as Nimony wrote it (with its version and source), the object table, the globals,
the change log (Pharo's `.changes`) and the module's source. This is its heap:
"""

block:
  var heapPart = ""
  for sec in parseNif(readFile(imageFile)).kids:
    if sec.isTag("heap") or sec.isTag("changes"): heapPart.add sec.toNif & "\n"
  nbTerm("lanterna.image.nif, (heap ...) and (changes ...)", heapPart.strip)

nbText: """
`faretto.nim` is a command line VM, like `pharo Pharo.image eval ...`: it loads an image, calls
one proc, and with `--save` writes the image back. Each line below is a new process, and the
lighthouse remembers:
"""

nbTerm("three processes, one image", [
  term(cli, imageFile, "report", "capo"),
  term(cli, imageFile, "night", "capo", "12", "--save"),
  term(cli, imageFile, "report", "capo")].join("\n\n"))

# ============================================================================================ 13
const benchN = 200_000
let nativeMs = nativeNight(benchN)
let fastMs = block:
  let f = scratch / "bench.image.nif"
  writeFile(f, bootImage())
  benchCli(cli, f, benchN)

nbText: &"""
## How slow is a lighthouse?

The price of all this is speed. `night(capo, {benchN})`, measured when the page was built:
"""

nbTable toTableData(@[
  (how: "Nimony, native (`-d:release`)", ms: &"{nativeMs:.1f}", x: "1"),
  (how: "faretto, walking the NIF tree (`-d:release`)", ms: &"{fastMs:.1f}", x: $int(fastMs / nativeMs + 0.5)),
]), rownameCol = "how":
  tabHeader "Ticking the lighthouse"
  colsLabel:
    how: "run by"
    ms: "ms"
    x: "times slower"
  fmtMarkdown ["how"]

nbText: """
faretto is a naive interpreter: values are variant objects, variables live in hash tables keyed by
symbol names, and every node is a `case` on a string. A real one would resolve symbols to
slots once, compile the tree to a compact bytecode, and JIT the hot procs, which is how Pharo
gets its speed (the Cog JIT, and Sista, its optimiser). The interesting design for Nim is
*mixed mode*: the same `.s.nif` goes to an interpreter while you are editing a proc, and to
Nimony's native pipeline for everything else, with calls crossing between the two.
"""

# ============================================================================================ 14
nbText: """
## So, can Nim code be alive?

Partly, and NIF is a surprisingly good base for it. Here is what the PoC shows, and what a real
system would need:
"""

nbTable toTableData(@[
  (what: "Change a proc while running", faretto: "yes: late binding by symbol, 25 ms check", real: "the same, plus native code for procs not being edited (mixed mode)"),
  (what: "Reject bad changes", faretto: "yes, Nimony checks the whole module", real: "check only the modules that depend on it (Nimony's incremental compilation)"),
  (what: "Inspector, thisContext", faretto: "yes: objects are tables, frames are objects", real: "native frames and layouts need debug info, as gdb uses"),
  (what: "`become`, type reshaping", faretto: "yes, with an object table", real: "hard for native objects: every pointer and every layout must change"),
  (what: "MetaLinks", faretto: "yes, on any NIF node", real: "free in the interpreter; for native procs, recompile with a hook, like Pharo"),
  (what: "Debugger: restart a frame", faretto: "yes, after accepting a fix", real: "the same, plus proceed past exceptions"),
  (what: "Image: save and resume", faretto: "yes, as NIF, in another process", real: "the hard part: ARC heaps, threads, files and sockets don't snapshot"),
  (what: "Templates, macros, generics", faretto: "already expanded in `.s.nif`", real: "changing a template means re-checking its users, Nimony knows which"),
  (what: "Speed", faretto: "hundreds of times slower", real: "bytecode and a JIT, or mixed mode"),
]), rownameCol = "what":
  tabHeader "Live Nim: the PoC and the real thing"
  colsLabel:
    what: "Pharo's"
    faretto: "faretto"
    real: "a real live Nim"
  fmtMarkdown ["what", "faretto", "real"]

nbText: """
The code side of liveness is within reach: Nimony type-checks a module fast, NIF names every
symbol and every line, and late binding by symbol is a small change. The object side is the hard
part, because native Nim is about memory layouts that are decided at compile time, and Pharo is
about memory that is never decided. A live Nim probably looks like this: Pharo-style tools and an
image while you are developing, and an ordinary native binary built from the same NIF when you ship.
Pharo did it the other way round, and it took decades of VM work to make it fast.
"""

nbFold("Next steps, if the lighthouse should become a harbour", """
- A NIF bytecode: resolve symbols to slots once, so faretto gets ten times faster without a JIT.
- Mixed mode: call native procs (Nimony's pipeline) from interpreted ones, for `std/` and anything not being edited.
- A doesNotUnderstand hole: accept a call to a proc that doesn't exist yet, and open the debugger there.
- A browser IDE for the playground, with Nimony compiled to WebAssembly so that *Accept* works on any code you type.
- And Pietro's Pharo-in-Nim ladder: the Blue Book VM first.
""")

# ============================================================================================ end
nbText: &"""
---

*Sources:* the abstract of [Marcus Denker's talk]({talk}); [Pharo's sources]({pharoRepo})
(the MetaLink comment is from `src/Reflectivity/MetaLink.class.st`) and [pharo-vm]({pharoVm});
[Reflectivity: its first 10+ years]({reflectivityPaper}); Nimony's [design document]({nimonyDesign}).
pharo.org and the talk's slides were blocked from where this page was built, so the rest of the Pharo
part is from what I know of it, and it has not been checked against a running image.
Tables by [tabelline](https://pietroppeter.github.io/tabelline/), page by
[nimib](https://github.com/pietroppeter/nimib). faretto is a toy: it runs the small part of
Nim that the lighthouse uses (ints, bools, strings, ref objects, `if`, `while`, `for` over
ranges), and nothing else.
"""

nbSave
