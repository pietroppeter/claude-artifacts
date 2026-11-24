## The Elm Architecture (TEA), from scratch, in Nim 2.4: what exists in Nim today, and a small
## runtime whose every type is one of Nim 2.4's new sum types.
## Build: sh deps.sh && nim r tea.nim (from this folder, with Nim 2.4 on the PATH; writes ../index.html)
import std/[os, strformat, strutils]
import nimib
import tabelline, tabelline/nimib
import lib/[style, blocks]
import review          # tabelline's review mode, from claude-artifacts shared/review (unchanged copy)

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.title = "The Elm Architecture, from scratch, in Nim 2.4"
nb.useExplainerStyle
nbReview(tpage = "tea-in-nim", tsource = "tea-in-nim/src/tea.nim")

const
  catalog = "https://tea.rinn7e.com/"
  catalogRepo = "https://github.com/rinn7e/tea-ecosystem"
  elmGuide = "https://guide.elm-lang.org/architecture/"
  nim240 = "https://nim-lang.org/blog/2026/10/28/nim-240.html"

# The sizes quoted on the page, counted from the files (lines that are not blank).
let
  coreLines = lineCount("tea/core.nim")
  browserLines = lineCount("tea/browser.nim")
  appLines = lineCount("apps/counter.nim") + lineCount("apps/dice.nim") + lineCount("apps/stopwatch.nim")

nbText: "# The Elm Architecture, from scratch, in Nim 2.4"

nbPrompt("Pietro", "24 Nov 2026", """
There are not TEA (The Elm Architecture) in Nim? From this it seems so https://tea.rinn7e.com/
make a better search. Now that we have better sum types with Nim 2.4 we should be able to make a
small PoC that explained the TEA concepts from scratch
""")

nbLede: """
The Elm Architecture (TEA) writes an interactive program as a loop. A **Msg** says what happened,
**update** turns it into the next **Model**, and **view** draws the model. Two things make this
worth it. Because update is a plain function, you can test a program by feeding it messages,
without a browser. And because every change goes through update, the list of messages is the
whole history of the program. This page looks for TEA in Nim, then builds it from scratch with
Nim 2.4's new sum types. Its three demos run in your browser, compiled from the Nim you read.
"""

nbTldr: &"""
- **What exists**: a [catalog of TEA frameworks]({catalog}) lists 100 in 27 languages, none in
  Nim. Nim has one TEA library for terminals ([bobabrew](https://github.com/bresilla/bobabrew),
  new this year), and older Karax examples. Nothing for the browser with commands and
  subscriptions.
- **Nim 2.4 sum types** fit TEA's messages exactly: no enum to declare, `SetStep(step: 5)` builds
  a message, a `case` must handle every message, and a field can only be read in its own branch.
- **The PoC**: the HTML, the effects (`Cmd`) and the event sources (`Sub`) are sum types too.
  A runtime of {coreLines + browserLines} lines runs three apps ({appLines} lines): a counter,
  dice and a stopwatch.
- **Rough edges** in Nim 2.4.2: three small ones, each shown with the compiler's own error.
"""

# ============================================================================================ 1
nbText: &"""
## Is there TEA in Nim?

[TEA Ecosystem]({catalog}) is a catalog that grades TEA frameworks against Elm, part by part
(Model, Msg, update, view, Cmd, Sub, and ports, Elm's typed channels to JavaScript). As of 23 Nov
2026 [its data]({catalogRepo}) has 100 entries in 27 languages and none in Nim. Searching nimble,
GitHub and the Nim forum finds this ("core" is Model, Msg, update and view):
"""

nbTable toTableData(@[
  (project: "[bobabrew](https://github.com/bresilla/bobabrew) 2026", core: "✓", cmd: "✓", sub: "as a Cmd"),
  (project: "[KaraxExamples](https://github.com/bluenote10/KaraxExamples) 2017", core: "update in place", cmd: "–", sub: "–"),
  (project: "[forum gists](https://forum.nim-lang.org/t/4006) 2018", core: "✓", cmd: "–", sub: "–"),
  (project: "[redux.nim](https://github.com/pragmagic/redux.nim) 2017", core: "a reducer", cmd: "outside", sub: "–"),
  (project: "[Karax](https://github.com/karaxnim/karax)", core: "by hand", cmd: "–", sub: "–"),
]), rownameCol = "project":
  tabHeader "TEA in Nim, 24 Nov 2026"
  colsLabel:
    core: "core"
    cmd: "Cmd"
    sub: "Sub"
  fmtMarkdown ["project"]

nbText: """
The only full TEA in Nim is bobabrew, a port of [Bubble Tea](https://github.com/charmbracelet/bubbletea)
(Go's TEA framework for terminal apps), new enough that the catalog has not found it. On the web,
Nim has Model, Msg, update and view written by hand on top of Karax, but nobody wrote the other
half: **commands** (update returns the effects it wants instead of doing them) and
**subscriptions** (the model says what to listen to, the runtime starts and stops it).
"""

nbFold("Each project, and how I searched", """
- **[bobabrew](https://github.com/bresilla/bobabrew)** (Aug 2026): TEA for terminal UIs. As of
  24 Nov 2026 it has all 62 Bubble Tea examples ported and one commit, and is not on nimble.
  Commands (`Batch`, `Tick`, `Every`) are there, subscriptions are commands that reschedule
  themselves (as in Bubble Tea), and messages are an open type hierarchy (`msg of KeyPressMsg`),
  not a closed sum type.
- **[KaraxExamples](https://github.com/bluenote10/KaraxExamples)** (2017): two demos "going in
  the direction of the Elm architecture", with an enum for messages and an update that changes
  the model in place.
- **The forum** asked "[Are there examples of the 'Elm architecture' for Nim?](https://forum.nim-lang.org/t/4006)"
  in July 2018. Araq answered: "if you use a clean Model+Update distinction and only use the
  update part in Karax's event handlers, you get the Elm architecture with Karax", and two gists
  followed (one uses the patty macros for sum types). Since then TEA comes up only in passing:
  in the "Wishlist: Ideal UI library for Nim" thread, Nerve ([28 Feb 2024](https://forum.nim-lang.org/t/10301#73287))
  pointed to Rust's Iced for its GPU-drawn widgets, adding "maybe we don't have to exactly adopt
  the Elm functional-reactive application model".
- **[redux.nim](https://github.com/pragmagic/redux.nim)** (2017) and
  [redux-nim](https://github.com/M4RC3L05/redux-nim) (2022): Redux stores, where effects run
  outside the reducer. The catalog calls these TEA-adjacent.
- **[Karax](https://github.com/karaxnim/karax)**, Nim's virtual-DOM framework, is not TEA
  (handlers change any state, then Karax redraws), but TEA can be written on top of it.
- **Not TEA**: owlkettle (GTK) and Fidget are declarative views over mutable state; loom
  (NimTui, 2026) uses signals.
- **Searched**: nimble's `packages.json` (elm, tea, redux, mvu, elmish, karax), GitHub
  repositories in Nim mentioning Elm or Bubble Tea, and the forum search (elm, elm architecture,
  bubbletea, redux).
""")

# ============================================================================================ 2
nbText: &"""
## TEA in one loop

In Elm's [guide]({elmGuide}) the architecture is `Model`, `update` and `view`; a real program
adds commands and subscriptions. Here is the loop, with the Nim signatures this page builds:
"""

nbLoop("Only the runtime is impure: it holds the model, listens to events, performs commands. Everything you write is a function of its arguments.", @[
  (kind: "msg", name: "Msg", sig: "SetStep(step: 5)", what: "a value saying **what happened**: a click, a timer tick, the result of an effect"),
  (kind: "update", name: "update", sig: "proc update(msg: Msg, model: Model): (Model, Cmd[Msg])", what: "the next model, and the effects it **asks** for (a `Cmd`)"),
  (kind: "model", name: "Model", sig: "Model(count: 7, step: 5)", what: "the whole state of the program, one plain value"),
  (kind: "view", name: "view", sig: "proc view(model: Model): Html[Msg]", what: "the page as **data**, with a message on each button"),
  (kind: "runtime", name: "the runtime", sig: "dispatch(msg)", what: "turns a click in the view, the result of a `Cmd` or a tick of a `Sub` into the next Msg"),
])

# ============================================================================================ 3
nbText: &"""
## Nim 2.4's sum types, the right shape for Msg

TEA asks for a closed set of messages, some carrying data. Nim always had this as case objects,
with an enum to declare and a `kind` field to switch on. [Nim 2.4]({nim240}) (28 Oct 2026; 2.4.2
on 13 Nov) adds a shorter form: the branch names come from the type itself.
"""

nbCodeInBlock:
  type
    Msg = object
      case
      of Increment, Decrement, Reset: discard
      of SetStep:
        step: int

  proc describe(msg: Msg): string =
    case msg
    of Increment: "plus one step"
    of Decrement: "minus one step"
    of Reset: "back to zero"
    # the pattern binds the field to s
    of SetStep(s): "steps of " & $s

  for msg in [Increment(), SetStep(step: 5), Reset()]:
    echo msg, ": ", describe(msg)

nbText: """
Four things here are exactly what TEA needs. The branch name is the constructor
(`SetStep(step: 5)`). The field of a branch is read by a pattern, `of SetStep(s)`. `$` prints a
message the way you would write it, which is all a message log needs. And the compiler catches the
two classic mistakes. These snippets are compiled when the page is built, and the errors are what
Nim 2.4.2 printed:
"""

nbCompileError("""
type Msg = object
  case
  of Increment: discard
  of SetStep:
    step: int

proc update(msg: Msg, count: int): int =
  # forgot SetStep
  case msg
  of Increment: count + 1
""")

nbCompileError("""
type Msg = object
  case
  of Increment: discard
  of SetStep:
    step: int

let msg = Increment()
# the wrong branch's field
echo msg.step
""")

nbText: """
With classic case objects the second one compiles and, by default, fails at run time with a
`FieldDefect` (field checks are off with `-d:danger`). Here it cannot happen at all.
"""

nbNote(nkNim, &"""
From the [release post]({nim240}): "Under the hood a sum type is still a case object with a
hidden discriminator, so the memory layout and the performance are the same as before", and
"Classic case objects continue to work and are not deprecated." Generic sum types work too
(`Cmd[M]`, `Html[M]` below), and so do recursive ones (`kids: seq[Html[M]]`).
""")

# ============================================================================================ 4
nbText: """
## Step 1: Model, Msg, update, view

The first program is a counter with a step. Its model is two ints and its messages are the four
above:
"""

nbSnippet("apps/counter.nim", ["type"])

nbText: """
`update` makes the next model. It also returns a `Cmd`, the effects it wants, and here it wants
none: `none()` is a helper for `NoCmd()`, the empty command (Step 2 is about commands).
"""

nbSnippet("apps/counter.nim", ["proc update*"])

nbText: """
`view` does not touch the DOM. It returns an `Html[Msg]`, built with small helpers: `el` for an
element, `text`, `cls` for a class, and `onClick Increment()`, which puts a **message** on a
button. `onInput` takes a proc that makes a message from what was typed (`parseStep` here).
"""

nbSnippet("apps/counter.nim", ["proc parseStep", "proc view*"])

nbText: """
`Html` is another sum type: a `Text`, or an `Elem` with a tag, attributes and children. An
attribute is a property, or an event with the message it sends. From
[`tea/core.nim`](#core):
"""

nbSnippet("tea/core.nim", ["Attr*[M]", "Html*[M]"])

nbText: """
Since `update` and `view` are plain functions, this page runs them **at build time**, natively,
before anything reaches a browser. Feed a list of messages to `update`, starting from the initial
model:
"""

import tea/core
import apps/[counter, dice, stopwatch]

nbCode:
  var (model, _) = counter.init()
  for msg in [Increment(), Increment(), SetStep(step: 5), Increment(), Decrement()]:
    (model, _) = counter.update(msg, model)
    echo msg, " → ", model

nbText: """
And `render` turns the last model's view into an HTML string (one line per element here):
"""

nbCode:
  let html = render(counter.view(model))
nbShowText(html.replace("><", ">\n<"))

nbText: """
Here is the same file compiled to JavaScript, running. Every message you send appears in the log
with the model it produced. Type a step, then press the buttons.
"""

nbDemo("counter", "counter.nim, live")

nbJsFromCodeGlobal:
  import tea/browser
  import apps/[counter, dice, stopwatch]

nbJsFromCode:
  mount("counter", counter.program)

nbSource("apps/counter.nim")

# ============================================================================================ 5
nbText: """
## Step 2: commands, effects as data

A die cannot be rolled by a pure function: `update` would give a different answer for the same
message. In TEA, update **asks** for a random number by returning a command, and the runtime
sends the result back as a new message. `Cmd` is one more sum type:
"""

nbSnippet("tea/core.nim", ["Cmd*[M]"])

nbText: """
The dice model counts how often each face came up, and `rolling` counts the rolls asked for whose
answer has not come back yet. `Roll` asks for one number, `RollMany` asks for many in one `Batch`,
and `Rolled` is the answer:
"""

nbSnippet("apps/dice.nim", ["proc rollCmd", "proc update*"])

nbText: """
Now testing is the interesting part. Without a runtime, `Roll` gives a command we can look at,
and we can play the runtime's role ourselves, with a die that always shows 4:
"""

nbCode:
  let (asked, cmd) = dice.update(Roll(), dice.init()[0])
  echo "after Roll:\n  ", asked
  echo "command:\n  ", cmd
  case cmd
  of RandomInt(lo, hi, gotInt):
    # the runtime would pick rand(lo..hi)
    let back = (gotInt)(4)
    echo "the runtime sends:\n  ", back
    echo "after it:\n  ", dice.update(back, asked)[0]
  else: discard
  echo "RollMany(n: 60) asks for:\n  ", dice.update(RollMany(n: 60), dice.Model())[1]

nbDemo("dice", "dice.nim, live: Roll asks for a number, Rolled brings it back")

nbJsFromCode:
  mount("dice", dice.program)

nbText: """
Press **roll 60** and look at the log: one `RollMany(n: 60)`, then sixty `Rolled` messages, each
a step of the same pure `update`. The bars are the model's `counts`, drawn by `view`.
"""

nbSource("apps/dice.nim")

# ============================================================================================ 6
nbText: """
## Step 3: subscriptions, a function of the model

A stopwatch needs a clock that ticks while it runs, and only then. In TEA you do not start and
stop timers in update. A `Sub` says what to listen to:
"""

nbSnippet("tea/core.nim", ["Sub*[M]"])

nbText: """
and the program's `subscriptions(model)` says which ones it wants **given this model**. After
every message the runtime compares the answer with what is running: it starts the new
subscriptions and stops the ones that are gone.
"""

nbSnippet("apps/stopwatch.nim", ["proc subscriptions*"])

nbCode:
  let stopped = stopwatch.Model()
  let running = stopwatch.Model(running: true)
  echo "stopped wants ", stopwatch.subscriptions(stopped).len, " subscriptions"
  echo "running wants ", stopwatch.subscriptions(running).len, ": every ",
    (case stopwatch.subscriptions(running)[0]
     of Every(ms, _): $ms & " ms"), " a Tick"

nbText: """
Start needs the time, and reading the clock is an effect too, so `Start` returns
`Now(gotTime: …)` and the runtime answers with `Started(at: …)`:
"""

nbSnippet("apps/stopwatch.nim", ["proc update*"])

nbText: """
Press start, then stop, and the `Tick` messages stop with it: nothing in `update` stopped the
timer, the runtime did, because `subscriptions` stopped asking for it.
"""

nbDemo("stopwatch", "stopwatch.nim, live: Tick comes from a subscription")

nbJsFromCode:
  mount("stopwatch", stopwatch.program)

nbSource("apps/stopwatch.nim")

# ============================================================================================ 7
nbText: &"""
## The runtime

All the impure code is one module, [`tea/browser.nim`](#browser) ({browserLines} lines), compiled
only for the JS backend. `dispatch` is the loop of the diagram:
"""

nbSnippet("tea/browser.nim", ["proc dispatch[Model, M](rt: Runtime[Model, M], msg: M) ="])

nbText: &"""
`render` walks the old and the new `Html` together and changes only the DOM nodes that differ
(it matches children by position: no keys, which is the first thing a real library would add).
Event attributes are set again on every render, so a button always sends the message of the
latest view. `perform` runs each command and dispatches its result; `syncSubs` keeps one
`setInterval` per period that `subscriptions` asks for.

The two modules, whole. `tea/core.nim` ({coreLines} lines) compiles on both backends, which is
what let this page run the apps natively above.
"""

nbSource("tea/core.nim", tanchor = "core")
nbSource("tea/browser.nim", tanchor = "browser")

# ============================================================================================ 8
nbText: """
## Rough edges in Nim 2.4.2

Three things got in the way while writing this, plus a small one. Each was checked again while
building this page; open a fold to see the code and the compiler's error.

**A generic proc cannot learn its type from the expected type.** A helper
`proc text[M](s: string): Html[M]` cannot be called as `text "+"` inside a view that returns
`Html[Msg]`, because nothing in its arguments says what `M` is. Elm infers this, Nim does not,
even with `{.experimental: "inferGenericTypes".}`. The PoC works around it with a template,
`htmlFor(Msg)`, that writes non-generic helpers (`text`, `el`, `onClick`, `cls`, ...) for each
app's own message type. One line per app; a real library would want a macro DSL here anyway.
"""

nbCompileError("""
type
  Html[M] = object
    case
    of Text:
      s: string
    of Elem:
      tag: string
      kids: seq[Html[M]]
  Msg = object
    case
    of Increment: discard

proc text[M](s: string): Html[M] = Text(s: s)
proc button[M](kids: seq[Html[M]]): Html[M] =
  Elem(tag: "button", kids: kids)

let v: Html[Msg] = button(@[text("+")])
""", tfold = "The code, and the error")

nbText: """
**A proc field bound by a pattern cannot be called directly.** In `of RandomInt(lo, hi, gotInt)`,
`gotInt` is bound as a template (that is how bindings become views into the object), so
`gotInt(4)` is read as a template call with an extra argument. `(gotInt)(4)` works, and so does
`let f = gotInt` first (the runtime does this, since it calls the proc later, from a timer).
"""

nbCompileError("""
type Cmd = object
  case
  of RandomInt:
    gotInt: proc (n: int): string
  of NoCmd: discard

let cmd = RandomInt(
  gotInt: proc (n: int): string = "rolled " & $n)
case cmd
of RandomInt(gotInt): echo gotInt(4)
of NoCmd: discard
""", tlines = 7, tfold = "The code, and the error")

nbText: """
**No `==` for sum types.** `Increment() == Increment()` does not compile, as for classic case
objects ("parallel 'fields' iterator does not work for 'case' objects"). Elm compares messages
and models structurally for free; in Nim a library would generate `==` with a macro.
"""

nbNote(nkCareful, """
The small one: the hidden discriminator is an enum named after the type (`CmdKind`), and it shows
up in error messages. `NoCmd[Msg]()` fails with "`NoCmd: CmdKind`, type mismatch", because a
branch name is not generic. Write `NoCmd()` and let the expected type pick `Cmd[Msg]`.
""")

# ============================================================================================ 9
nbText: &"""
## How the PoC grades, and what a real library needs

On the catalog's rubric, as I read it: **Model, Msg, update, view** native (one value, a closed
sum type checked for exhaustiveness, a pure update that returns its effects, a pure view);
**Cmd** native (effects as data, performed by the runtime, results as messages); **Sub** native
(`subscriptions(model)`, started and stopped by the runtime); **ports** missing, which the
catalog does not require. That is the shape of "full TEA", in {coreLines + browserLines} lines of
runtime and {appLines} lines for the three apps. It is a PoC, not a library. The next steps,
roughly in order:

- **keyed children** in the DOM patch, so lists can reorder without redrawing;
- a **macro DSL** for views (Karax's `buildHtml` style), which also replaces `htmlFor`;
- more commands (**HTTP**, local storage, focus) and subscriptions (keys, animation frames,
  window size), and **ports** for JavaScript interop;
- a generated **`==`** for models, so `view` can be skipped when nothing changed;
- nested programs (a child's model in the parent's model, as Elm does).

Two follow-ups are outside this page: [bobabrew](https://github.com/bresilla/bobabrew) would
probably qualify for the catalog (it grades like Bubble Tea, which is there), and the
proc-field binding above looks worth a Nim issue.
"""

nbText: """
---
Built on 24 Nov 2026 with Nim 2.4.2 and nimib. The page's sources: `tea.nim` (this page),
`tea/core.nim`, `tea/browser.nim`, `apps/*.nim`. The demos are compiled from the same `apps`
files that ran natively above.
"""

nbSave
