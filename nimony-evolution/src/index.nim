## How Nimony (the compiler that becomes Nim 3) evolved, from the NIR survey of 2023 to the
## avoidtemps plugin of 22 Nov 2026, with every term explained where it shows up.
## Build: sh deps.sh && nim r index.nim (writes ../index.html; NIMONY_EVO_DEPS moves the deps folder)
import std/[os, strformat, strutils]
import nimib
import tabelline, tabelline/nimib
import lib/[style, blocks]
import review          # tabelline's review mode, from claude-artifacts shared/review (unchanged copy)

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.title = "Nimony, explained: how Nim 3's compiler grew up"
nb.useExplainerStyle
nbReview(tpage = "nimony-evolution", tsource = "nimony-evolution/src/index.nim")

# Sources. Forum posts are linked by thread and post id; dates are the post's day (UTC).
func f(thread, post: int): string = &"https://forum.nim-lang.org/t/{thread}#{post}"
const
  repo = "https://github.com/nim-lang/nimony"
  docs = repo & "/blob/master/doc/"
  blog = "https://nim-lang.org/araq/"

# Every term card also goes into the index at the end.
var index: seq[tuple[term, short, chapter: string]]
var chapter = ""
template term(tname, tshort, ttext: string; taka = ""; tsince = "") =
  index.add (term: tname, short: tshort, chapter: chapter)
  nbTerm(tname, ttext, taka, tsince)
template chap(tid, ttitle, tspan: string) =
  chapter = ttitle
  nbChapter(tid, ttitle, tspan)

nbText: "# Nimony, explained"

nbLede: """
Nimony is Andreas Rumpf's (Araq's) new Nim compiler, the one meant to become **Nim 3**. For two
years he has posted its progress on the Nim forum one line at a time: "NJVL", "Shoggoth",
"Arkham", "BIF", "avoidtemps". This is the story told in order, from the forum threads, the
[nimony repo](https://github.com/nim-lang/nimony) (2,348 commits) and Araq's blog, with every term
explained at the point where it shows up.
"""
nbVersion(1, "22 Nov 2026")

nbTldr: """
- **What it is.** A from-scratch Nim compiler built as a chain of small tools that pass
  **NIF** files to each other (NIF is a Lisp-like text format, "JSON for compilers"). Because every
  step reads and writes files, incremental and parallel builds come almost for free.
- **Why.** After twenty years the old compiler could not get incremental compilation, type-checked
  generics or a clean phase order. Araq: "I don't know how to bring all this good stuff into Nim's
  old codebase without going insane."
- **How it went.** First "hello world" on 22 Feb 2025; a minimal language ("aufbruch") by May
  2025; release 0.2 in Nov 2025; it compiled itself in Apr 2026; its own native backend
  (**Arkham**, no C compiler) bootstrapped in Aug 2026; Araq calls it feature complete in Oct 2026
  and a "great christmas release" is planned.
- **Side effect.** The ideas flowed back: Nim **2.4** (28 Oct 2026) ships incremental compilation
  built the Nimony way. Nim 2.x and Nimony now "compete for the Nim 3 title".
- **avoidtemps** (your example) is a *type plugin*: mark a type with it and the compiler rewrites
  `let e = a*b + c - d` into `var e = a; e *= b; e += c; e -= d`, so no temporary values are
  created. Promised in May 2025, shipped today, 22 Nov 2026.
"""

nbToc @[
  ("avoidtemps", "Start with your example: avoidtemps"),
  ("prehistory", "2023 to 2024: NIR, a survey, then NIF"),
  ("hello", "Feb to May 2025: hello world to a minimal Nim"),
  ("growing", "May to Nov 2025: closures, passive procs, release 0.2"),
  ("ic", "Dec 2025 to Jun 2026: IC for Nim 2, NJ, borrow checking, self-hosting"),
  ("native", "Jun to Sep 2026: Leng, Shoggoth, Arkham, no C compiler"),
  ("complete", "Oct to Nov 2026: feature complete, the fuzzer, avoidtemps"),
  ("today", "The pipeline today"),
  ("names", "The names that changed"),
  ("glossary", "Index of terms"),
  ("sources", "Sources"),
]

# =========================================================================================== 0
chap("avoidtemps", "Start with your example: avoidtemps", "promised 3 May 2025, shipped 22 Nov 2026")

nbText: """
Take a small matrix type with the usual operators. Each operator copies its left operand into a
new result and then works in place on it. That is the standard way to write them, and it means
every operator in an expression makes a new matrix. This runs in Nim 2 and counts the copies:
"""

nbCode:
  var copies = 0
  type Matrix = object
    a: array[4, array[4, float]]
  proc `=copy`(d: var Matrix; s: Matrix) =
    inc copies
    d.a = s.a

  proc `*=`(x: var Matrix; y: Matrix) =
    for i in 0..3:
      for j in 0..3: x.a[i][j] *= y.a[i][j]
  proc `+=`(x: var Matrix; y: Matrix) =
    for i in 0..3:
      for j in 0..3: x.a[i][j] += y.a[i][j]
  proc `-=`(x: var Matrix; y: Matrix) =
    for i in 0..3:
      for j in 0..3: x.a[i][j] -= y.a[i][j]

  proc `*`(x, y: Matrix): Matrix = (result = x; result *= y)
  proc `+`(x, y: Matrix): Matrix = (result = x; result += y)
  proc `-`(x, y: Matrix): Matrix = (result = x; result -= y)

  proc main =
    var a, b, c, d: Matrix
    copies = 0
    let e1 = a*b + c - d                  # what you write
    echo "a*b + c - d:        ", copies, " copies"
    copies = 0
    var e2 = a                            # what avoidtemps turns it into
    e2 *= b
    e2 += c
    e2 -= d
    echo "rewritten in place: ", copies, " copy"
    doAssert e1 == e2
  main()

nbText: """
Three matrices are made and two of them die at once: they are **temporaries**. With 16 floats
that is a small waste; with a big matrix or a vector of a million elements it is the cost that
dominates. C++ solves this with "expression templates", a famous piece of template trickery. Nim 2
had **term rewriting macros**, a pattern-matching feature that few people used and that was hard
to keep working.

In Nimony you attach the rewrite to the type:
"""

nbCodeSkip:
  type
    Matrix {.plugin: "std/deps/avoidtemps".} = object
      a: array[4, array[4, float]]

nbTerm("avoidtemps", &"""
A **type plugin** that ships in Nimony's standard library
([`lib/std/deps/avoidtemps.nim`]({repo}/blob/master/lib/std/deps/avoidtemps.nim), 302 lines).
For every module that uses the marked type, it rewrites chains of `+ - * /` in `let`/`var`
declarations into one copy followed by in-place operators. A right operand that is itself a
chain gets a single temporary: `let e = a - (b*c + d)` becomes
`var e = a; var t = b; t *= c; t += d; e -= t`. An assignment `x = y*z` to a local `x` becomes
`x = y; x *= z` when the right side does not mention `x`.

Attaching it is a **promise** by the type's author that `x op y` means
`(var t = x; t op= y; t)`: the plugin cannot see the operators (they live in another module), so
it trusts the promise. It leaves globals and `var` parameters alone, because a parameter on the
right side could alias them. `std/vectors` (the new `Vec[N, T]` type, merged the same day) is its
first user.
""", taka = "expression templates, term rewriting macros",
  tsince = &"Outlined in [Araq's design post]({blog}nimony.html) (3 May 2025) and the manual (Aug 2025); real on [22 Nov 2026]({f(14201, 86812)}) ([PR #3089]({repo}/pull/3089))")
index.add (term: "avoidtemps", short: "type plugin that removes temporaries from `a*b + c - d`", chapter: "Start with your example: avoidtemps")

nbText: """
Behind that one line sit most of the ideas this page explains: **plugins** instead of macros,
plugins that are ordinary Nim programs compiled to machine code, and a compiler that speaks
**NIF** between every step so a plugin can read and write the program. Here is how all of that
came to be.
"""

# =========================================================================================== 1
chap("prehistory", "2023 to 2024: NIR, a survey, then NIF", "Nov 2023 to Jan 2025")

nbEvents @[
  ("2 Nov 2023", "Araq announces **NIR**, a new intermediate format \"lower level than Nim's AST\" for future Nim versions, and runs a survey: REPL, not-nil checking, a new C backend, incremental compilation or better borrow checking? The answers are nearly unanimous.", f(10594, 70808)),
  ("5 Nov 2023", "\"Ok, ok, IC it is.\"", f(10594, 70902)),
  ("6 Jul 2024", "A new repo, then called `nim-lang/nif`: \"Spec version 1.0\", \"file extensions are a type system for files\", and **nifler**, the parser tool.", repo & "/commits/master?after=36bde262&path=README.md"),
  ("Jul 2024", "**NIFC** spec and implementation; **gear2**, a mapping of the whole Nim 2 compiler AST to NIF.", ""),
  ("29 Sep 2024", "\"NIF, NIFC, native code...\": the first x86-64 assembler comes out of NIFC. \"Because writing compilers is fun.\"", f(12534, 77145)),
  ("6 Oct 2024", "Asked whether NIR was replaced: \"Yes. NIR was for backends only, NIF is for everything.\"", f(10594, 77209)),
  ("9 Nov 2024", "Commit \"nimony tool: baby steps\". The front end gets its name.", ""),
  ("15 Jan 2025", "\"gear3 is now hexer\": the lowering tool gets its name.", ""),
]

term("NIR", "2023's backend-only IR, replaced by NIF", """
"Nim Intermediate Representation", announced in Nov 2023 inside the old compiler: a typed,
C-like format for *backends only*, with a planned new VM, REPL and C++ backend. It was
abandoned; NIF took over its job and much more.
""", tsince = "[Nov 2023](" & f(10594, 70808) & ")")

term("IC", "incremental compilation: rebuild only what changed", """
**Incremental compilation**: after an edit, recompile only the modules that are affected, not the
whole program. It was the community's top wish in the 2023 survey and the hardest goal of the
project. In Nimony it is not even optional: every build has always been incremental.
""", tsince = "the 2023 survey")

term("NIF", "Nim Intermediate Format, the S-expression text format every tool speaks", &"""
"Nim Intermediate Format", described by Araq as "JSON for compilers". It looks like Lisp:
`(call foo.0 +4 "abc")`. What it adds to Lisp, from the
[spec](https://github.com/nim-lang/nifspec/blob/master/doc/nif-spec.md) and the
[S-expressions post]({blog}sexpressions.html):

- **Two namespaces.** The first word of a node is a *tag* (`call`, `proc`, `if`) and tags never
  collide with program names, so new constructs need no new keywords.
- **Symbols with identity.** `foo.2.mymodule` is the second `foo` of module `mymodule`;
  `foo.0` is local. A definition is written `:foo.0`, a use `foo.0`, so "find all uses" is a text search.
- **Line information on every node**, stored as small offsets from the parent node.
- **An index** at the end of the file maps each exported symbol to a byte offset, so a tool can
  jump to one declaration without parsing the rest: "a text-binary-hybrid sharded database".
- `(` and `)` can never appear inside strings or names (they are escaped), so counting `(` in your
  editor counts the nodes.
""", taka = "nifspec", tsince = "Jul 2024, its own repo [nim-lang/nifspec](https://github.com/nim-lang/nifspec) since Dec 2024")

term("nifler", "the parser: Nim source to NIF", """
The first tool of the chain: it parses Nim source into a NIF dialect, with no symbol table, so it
is fast and can run on just the files that changed. It reused the old compiler's parser until
Sep 2026, when Nimony got its own lexer and parser, generated from a grammar DSL by plugins
(which also proved "Nim's grammar is in fact LL(1)"). Nifler can also evaluate `nim.cfg` and
NimScript files, so tools like nimsuggest get the right `--path` without importing the compiler.
""", tsince = "Jul 2024")

term("NIFC", "the C-shaped NIF dialect, renamed Leng in 2026", """
"NIF representing C": a dialect close to C (types, procs, gotos), from which C code, and later
LLVM and native code, is produced. Renamed **Leng** in Jun 2026, see below.
""", taka = "now Leng", tsince = "Jul 2024")

term("gear2, gear3", "early names: Nim 2's AST as NIF; the first lowering tool", """
**gear2** (Jul 2024) mapped the *entire* semantically checked AST of the Nim 2 compiler to NIF,
every node flag and pragma, with separate `iface` and `impl` sections. It was the first bridge
between old and new. **gear3** (Nov 2024) was the first tool that lowered checked code to NIFC; in
Jan 2025 it was renamed **hexer**, and in Oct 2026 hexer became part of **Shoggoth**.
""", tsince = "Jul 2024")

nbNote(nkAside, """
Why a native x86 backend as early as 2024? Araq: "Generating native code directly is simpler
and more rewarding than generating LLVM's IR", plus a long-term plan to run the generated machine
code at *compile time* instead of keeping Nim's VM. That plan came true in 2026 (see Arkham).
""")

# =========================================================================================== 2
chap("hello", "Feb to May 2025: hello world to a minimal Nim", "progress report, part 1")

nbQuote("""
Tonight the following program worked for the first time: `import std/syncio; echo "hi", "abc"`.
This might not look impressive but it is (IMO): Nimony is a new Nim compiler which does not use
much of the old codebase.
""", f(12693, 78247), "22 Feb 2025")

nbEvents @[
  ("25 Feb 2025", "Plugins first described: \"a program that receives two filenames, input.nif and output.nif\".", f(12693, 78257)),
  ("1 Mar 2025", "`openArray` written as a normal library type with the new `.view` pragma; `.requires` contracts for bounds checks; one polymorphic `[]` instead of two.", f(12693, 78280)),
  ("3 Mar 2025", "`parseopt` works. \"Watching this thread weekly is more exciting than Netflix.\"", f(12693, 78292)),
  ("4 Mar 2025", "`case` on strings compiles to dispatch trees instead of hashing: one scan of the string instead of two.", f(12693, 78315)),
  ("7 Mar 2025", "`seq` works, destructors included.", f(12693, 78366)),
  ("9 Mar 2025", "\"aufbruch\" mode: \"what would a 10 times smaller Nim compressed to its essentials look like?\"", f(12693, 78387)),
  ("11 Mar 2025", "A new `tables` module, written for type-checked generics.", f(12693, 78439)),
  ("27 Mar 2025", "Overflow checking without exceptions: `{.keepOverflowFlag.}` and `overflowFlag()`, mapped to the C compiler's builtins.", f(12693, 78670)),
  ("10 Apr 2025", "Methods and inheritance, with v-tables and O(1) `of` checks (\"displays\").", f(12693, 78841)),
  ("22 Apr 2025", "\"Today the first plugin worked!\"", f(12693, 78990)),
  ("24 Apr 2025", "A thread on why plugins: \"Instead of 5000 lines of code for a VM we have a plugin subsystem that takes about 100 lines.\"", f(12830, 79025)),
  ("28 Apr 2025", "`try`/`except` with the new `ErrorCode` enum, mapped to tuples and gotos.", f(12693, 79075)),
  ("3 May 2025", &"Blog post [Nimony: Design principles]({blog}nimony.html): memory management, error handling, generics, concurrency, plugins, and the avoidtemps example.", blog & "nimony.html"),
  ("13 May 2025", "The control flow graph is rewritten with the \"split streams\" algorithm.", f(12693, 79379)),
  ("14 May 2025", "Nil checking works. \"Nimony is now feature complete. In the sense that all features for a MVP have been implemented.\"", f(12693, 79417)),
]

term("Nimony", "the new compiler, and the umbrella name of the project", """
The name of the new compiler for the language that will become Nim 3, and the umbrella name for
all its tools ("nifler and hexer have been developed in lock-step"). The
[website](https://nim-lang.github.io/nimony-website/) puts it this way: Nimony is the compiler;
**Nim 3** is the language revision; a full Nim 3 release is Nimony "plus substantial
compatibility work" so that Nim 2 code can migrate. It is not a drop-in replacement for Nim 2:
"Once that happens it will be renamed to Nim 3."
""", tsince = "Nov 2024")

term("type-checked generics and concepts", "generic code is checked where it is written, using concepts", """
Nim 2 checks a generic proc only when it is *instantiated* with a concrete type. Nimony also
checks it where it is *declared*. For that it must know what `T` can do, and a **concept** says
it: `proc fib[T: Fibable](a: T): T` with `Fibable = concept` listing `<=`, `+` and `-`. Without
the concept, `fib` is rejected. The payoff: earlier errors and precise IDE completion. A generic
marked `.untyped` keeps the old behaviour. "Every toy example I throw at Nimony requires a
concept declaration. I think we're really getting into shape here."
""", tsince = "[Feb 2025](" & f(12693, 78265) & ")")

term("`.view` and library openArray", "openArray is no longer compiler magic", """
In Nim 2, `openArray[T]` is a special built-in type. In Nimony it is an ordinary object (a pointer
and a length) whose declaration carries the `.view` pragma, which tells the compiler to apply
borrow rules to it. Fewer special cases in the compiler, and user-defined view types work the
same way.
""", tsince = "[Mar 2025](" & f(12693, 78280) & ")")

term("polymorphic accessors", "one `[]` that is mutable when its container is", &"""
Nim 2 needs two overloads, `[](x: var C): var T` and `[](x: C): lent T`. Nimony needs one,
`[](x: C): var T`, and tracks whether a write through it is allowed (it is when `x` is mutable),
as built-in arrays always did. A bonus: a container access that could *resize* the container still
needs `var`, so the type system knows which accesses are safe. (Overloading on `var T` came back in
May 2026 "for backwards compat".)
""", tsince = &"[Mar 2025]({f(12693, 78280)}), [explained Aug 2025]({f(12978, 80814)})")

term("contracts: `.requires`, `.ensures`, `.assume`, `.assert`", "pre and postconditions checked by a prover", &"""
`.requires` states what a call needs (`i >= 0 and i < s.len` for indexing), `.ensures` what a
routine guarantees. The compiler tries to **prove** each call site: proven costs nothing, violated
is a compile-time error, undecided keeps a run-time check. `.assume` and `.assert` are escape
hatches. Since `seq` indexing is itself a `.requires`, this is how bounds checks disappear.
See the [manual]({docs}language.md#contracts).
""", tsince = "[Mar 2025](" & f(12693, 78284) & ")")

term("aufbruch mode", "the first minimal Nim, later dropped as a name", """
German for "setting out" (and, Araq added, "it got broken up", as in breaking changes). The
name for Nimony's minimal language: IC plus ARC plus type-checked generics, "a 10 times smaller
Nim compressed to its essentials", meant to survive as `--mode:aufbruch`. By Mar 2026: "we moved
beyond that aufbruch thing, we don't need a better name for it, it's gone."
""", tsince = "[Mar 2025](" & f(12693, 78387) & ")")

term("plugins", "Nim programs, compiled to machine code, that transform NIF: the successor of macros", &"""
"Plugins are the final evolved form of Nim's macros." A plugin is a Nim program, compiled to a
native executable, that reads the code to transform from an `.in.nif` file and writes the result
to an `.out.nif` file. Compared with Nim 2's macros, which run in the compiler's VM:
every language feature works (including unsafe code), they see fully type-checked input, they
run incrementally and in parallel, and the implementation is about 100 lines instead of a VM.
Four kinds, from the [plugins doc]({docs}plugins.md):

- **template plugins**: `template foo(x: int) {{.plugin: "foo".}}`, the macro replacement;
- **module plugins**: `{{.plugin: "cps".}}` as a statement receives the *whole module*;
- **type plugins**: attached to a type, run for every module that uses it (avoidtemps);
- **import plugins**: `import foo {{.plugin: "v2".}}` imports a module that a plugin produces,
  even from another language.

Macros came back in May 2026, mapped onto plugins, "so that you can keep your macros for good",
but plugins are "definitely the recommended approach".
""", taka = "compiler plugins", tsince = "[first one ran 22 Apr 2025](" & f(12693, 78990) & ")")

term("ErrorCode and `.raises`", "errors as an enum, every raising proc marked", &"""
A routine that can raise must say `{{.raises.}}` (without listing *what*: the point is that the
call hides control flow). Besides exceptions you can `raise ErrorCode.RangeError`, a plain enum
designed to map to POSIX errno, Windows errors and HTTP status codes. No heap allocation is
needed to raise, so even out-of-memory can be propagated. Heap-based exceptions (`ref object`
subtypes) were added later for compatibility (Feb 2026). See the
[design post]({blog}nimony.html).
""", tsince = "[Apr 2025](" & f(12693, 79075) & ")")

term("OOM handling", "out of memory is an error state, not a crash", &"""
Araq's view: "OOM is a misnomer", one request of one size failed. Containers that cannot
allocate call an overridable `oomHandler` and stay in an empty state; `new` returns `nil`, and
because nil is checked at compile time you must handle it. Inside a `.raises` proc `new`
instead never returns nil: the failure becomes `ErrorCode.OutOfMemError`.
""", tsince = "[design post, May 2025](" & blog & "nimony.html)")

term("`nil ref T` and not-nil by default", "refs and pointers cannot be nil unless you say so", &"""
Three kinds of pointer were discussed for weeks (with dozens of syntax proposals):
unchecked, `nil ref T` (may be nil, every dereference must be guarded), and not-nil. The
result, default since Apr 2026: a plain `ref T` or `ptr T` **cannot hold nil**; write `nil Node`
for one that can. The compiler follows `if x != nil` through control flow. A not-nil pointer has
no default value, so `var a: array[8, Node]` does not compile. Old code can opt out per module
with `{{.feature: "lenientnils".}}` ([doc]({docs}lenientnils.md)).
""", taka = "lenientnils", tsince = &"[syntax May 2025]({f(12693, 79273)}), [default 11 Apr 2026]({f(13651, 84016)})")

term("split streams", "the textbook way to build a control flow graph", """
A standard algorithm for turning structured code into a control flow graph, which nil checking
and other analyses need. Araq had first tried his own approach and replaced it in May 2025:
"I thought I had found a better way than the split streams algorithm but it turns out, it was
just a terrible hack."
""", tsince = "[May 2025](" & f(12693, 79379) & ")")

# =========================================================================================== 3
chap("growing", "May to Nov 2025: closures, passive procs, release 0.2", "progress reports, parts 2 to 4")

nbEvents @[
  ("2 Jun 2025", "Nimony builds with its own tool, **nifmake**, instead of `make`.", f(12978, 79797)),
  ("6 Jun 2025", "`import abc {.plugin: \"v2\".}` works: a module compiled by the Nim 2 compiler is imported into Nimony.", f(12978, 79840)),
  ("11 Jun 2025", "Closures; two days later the compiler avoids their heap allocation when the closure does not escape, which makes capturing `var` parameters legal.", f(12978, 79953)),
  ("15 Jun 2025", "\"The terrible and popular defer statement has been implemented.\"", f(12978, 79963)),
  ("7 Jul 2025", "The first `.passive` proc runs. \"Usually this is called an async proc but for now passive is the working title.\"", f(12978, 80257)),
  ("25 Jul 2025", "Plan: release 0.4 with math, strutils, unicode, encodings (Sep 2025); bootstrap the compiler (Dec 2025?!).", f(12978, 80574)),
  ("13 Aug 2025", "On async runtimes: a compiler with plugins plus, maybe, a \"distribution\" called **Nimlody** with a coherent library.", f(13316, 80910)),
  ("14 Aug 2025", "A new, simpler configuration system; per-OS `-d:` switches are deliberately not supported (\"If you need a when statement in your code, so be it.\").", f(12978, 80959)),
  ("22 Aug 2025", "The [Nimony website and manual](https://nim-lang.github.io/nimony-website/) go up.", f(12978, 81084)),
  ("8 Sep 2025", "Compile-time evaluation: \"You nerd-sniped me into implementing a decent compile-time engine via a staticExec like mechanism.\"", f(13357, 81325)),
  ("23 Sep 2025", "Whole-program dead code elimination; `check --usages` and `--def` (find usages, goto definition).", f(13357, 81462)),
  ("21 Oct 2025", "**NJVL** announced. CPS conversion done *after* destructor injection \"just works\".", f(13471, 81725)),
  ("1 Nov 2025", "**Nimony 0.2.0**, \"against all good advice\", with an honest review by planetis (a Tic-Tac-Toe game with an AI in a worker thread).", "https://nim-lang.github.io/nimony-website/version0_2.html"),
]

term("nifmake", "make for NIF files: what makes builds incremental and parallel", &"""
A make-like engine over a dependency graph written in NIF. The driver writes the graph (which
module needs which), nifmake runs every tool whose inputs are newer than its outputs, as many at
once as there are cores. The trick that spares work: each module also writes a small
**interface file** (`M.s.idx.nif`), rewritten only when what *other* modules read from it
changed, so editing the body of a non-generic proc recompiles nobody else. See the
[IC rules]({docs}internals/ic.md).
""", tsince = "[Jun 2025](" & f(12978, 79797) & ")")

term("v2 import plugin", "use Nim 2 modules from Nimony", """
An import plugin that shells out to the Nim 2 compiler (`nim nif`) to translate a Nim 2 module
into Nimony's NIF, including the index. It is the bridge for libraries not yet ported, and it
takes part in incremental builds.
""", tsince = "[Jun 2025](" & f(12978, 79840) & ")")

term("lambda lifting", "how closures become plain procs", """
The classic compiler step that turns a nested proc capturing local variables into a top-level
proc plus an explicit environment object. Nimony also checks whether the environment can live on
the stack (the closure does not escape), which avoids the heap allocation entirely.
""", tsince = "Jun 2025")

term("CPS", "continuation-passing style: the transform behind passive procs and iterators", """
**Continuation-passing style.** The compiler cuts a routine at the points where it may pause and
turns each piece into a small function that returns "what to run next" (a *continuation*: a
function pointer plus an environment). The local variables move into a heap object. A loop
(the *trampoline*) keeps calling "what to run next" until nothing is left. Tail calls and
closure iterators come out of it for free. Nim 2 has CPS as a library (nim-works/cps); in Nimony
it is a compiler pass.
""", tsince = "[planned Feb 2025](" & f(12693, 78277) & ")")

term("passive procs", "async without colored functions: `.passive` and no `await`", &"""
Nimony's answer to `async`/`await`: mark a proc `{{.passive.}}` and write no `await` at all.
"It's passive, it needs to be stepped through by a scheduler." Calling a passive proc from
another passive proc is a suspension point; calling it from normal code runs it to completion,
so it looks like a blocking call. The pieces, from [passive_procs.md]({docs}passive_procs.md):

- `Continuation`: a function pointer plus an environment; `fn == nil` means finished;
- `delay(call)`: make a continuation without running it, to hand to a scheduler (its parameters
  must not alias the caller's frame, take them as `sink`);
- `suspend()` / `delay()`: park the current task, to be resumed when I/O is ready;
- `complete(c)`: run a continuation to completion from ordinary code;
- the **scheduler** is replaceable, so a thread pool and an event loop are the same mechanism:
  "Async event loop unified with multi-threading."

A user report: tokyovigilante's CPS web server Hashi reached parity with Mummy.
""", taka = "async, coroutines", tsince = &"[first ran 7 Jul 2025]({f(12978, 80257)}), [working Mar 2026]({f(13651, 83618)})")

term("Nimlody", "an idea: a batteries-included distribution on top of Nimony", """
An idea from Aug 2025: keep the compiler's standard library small and ship a "distribution"
called Nimlody, a set of libraries designed together (including an async event loop), probably
bundled with the compiler. Not heard of since; meanwhile Nimony's own stdlib grew (JSON, regex,
httpclient with TLS, crypto).
""", tsince = "[Aug 2025](" & f(13316, 80910) & ")")

term("compile-time evaluation by compiling", "no VM: constants are computed by a compiled program", &"""
Nim 2 runs compile-time code (`const`, macros) in a VM with many restrictions. Nimony does not
have a VM: it compiles the snippet through the full pipeline to a native executable, runs it, and
reads the result back, like plugins. "Restrictions on compile time execution? Yes, these are all
gone." See [design.md]({docs}design.md).
""", tsince = "[Sep 2025](" & f(13357, 81325) & ")")

term("NJVL", "\"no jumps, versioned locations\": an IR experiment, now dead", &"""
An intermediate representation with **no jumps**: `return`, `break` and `goto` become boolean
*control flow variables* ("cfvars", set once and never reset), and **versioned locations**:
every write to a variable gets a version number, like SSA but for any location and without
SSA's *phi nodes* (the merge points that are "subtle to understand and to get rid of"). The
promise: inlining, move analysis, destructor injection, CSE and nil checking all become simple
tree walks. Follow-ups: a `bind` construct to merge CSE, copy propagation and scalar
replacement (Oct 2025), and "SSU" (static single *use*, Nov 2025).

It shaped the project for a year: in Jan 2026 it became **NJ**, the planned common backend for
Nim 2 and Nimony; in Mar 2026 the proof engine was moved onto it. Then the repo moved to the
**multi-join IR** instead, and on 31 Aug 2026 the commit "njvl: remove the superseded pipeline"
deleted it. The repo's instructions for AI agents now say: "NJVL is dead. Do not resurrect it."
""", taka = "NJ, cfvars, versioned locations", tsince = &"[21 Oct 2025]({f(13471, 81725)})")

term("phi nodes and SSA", "the standard IR form NJVL tried to avoid", """
**SSA** (static single assignment) is the form most optimizing compilers use: every variable is
assigned exactly once, so `x = 1; x = 2` becomes `x1 = 1; x2 = 2`. Where two branches meet, a
**phi node** says "x3 is x1 or x2, depending on where we came from". Phi nodes are what NJVL's
versioned locations replaced with fixed join points in the tree.
""")

# =========================================================================================== 4
chap("ic", "Dec 2025 to Jun 2026: IC for Nim 2, NJ, borrow checking, self-hosting", "progress reports, parts 5 and 6")

nbText: &"""
On Christmas Day 2025 Araq posted a [progress report on IC]({f(13585, 82419)}), but for **Nim 2**:
the design was "taken from Nimony". A pre-pass with nifler builds the import graph, nifmake runs
`nim m` (compile one module, load its dependencies from their `.nif` files) for each module, then
the backend runs over all of them. Nimony itself slowed down: "The progress of Nimony has slowed
down significantly as we bring IC to Nim 2." IC is what pays the bills: "This way even more
innovations can be brought to the 2.x line which is what pays my bills."
"""

nbEvents @[
  ("29 Dec 2025", "IC for Nim 2 generates code for \"Hello world\" on Linux.", f(13585, 82470)),
  ("13 Jan 2026", "Nimony moves to **NIF26**. New plan: Nimony and Nim 2 front ends both target **NJ**, with C, JS, x86-64 and ARM64 backends behind it, in a new repo, **NativeNif**.", f(13651, 82706)),
  ("1 Feb 2026", "Forward declarations are understood and ignored (\"It doesn't need them\"); lifetime hooks become type pragmas.", f(13651, 82885)),
  ("16 Feb 2026", "Nimony can build DLLs that a Nim 2 program imports; heap-based exceptions become possible.", f(13651, 83172)),
  ("26 Feb 2026", "Cyclic modules: `import foo {.cyclic.}`.", f(13651, 83309)),
  ("28 Feb, 19 Mar 2026", &"Blog series: [S-expressions]({blog}sexpressions.html) and [Implementing NIF in Nim]({blog}nif_implementation.html).", f(13651, 83382)),
  ("13 Mar 2026", "Borrow checking is implemented.", f(13651, 83608)),
  ("14 Mar 2026", "Asked how much is vibe-coded: \"Close to 100% these days\", the architecture (token streams, continuations, NJ) having been in place \"before AI got really good\". Later: \"I care about the code, I read it.\"", f(13651, 83639)),
  ("22 Mar 2026", "Strings with small-string optimization and copy-on-write.", f(13651, 83749)),
  ("2 Apr 2026", "Sum types and pattern matching (RFC 559).", f(13651, 83895)),
  ("8 Apr 2026", "\"hello world\" through a new LLVM backend, generating `.ll` text.", f(13651, 83973)),
  ("11 Apr 2026", "Not-nil `ref`/`ptr` become the default.", f(13651, 84016)),
  ("19 Apr 2026", "A **validator** checks plugins and compiler passes.", f(13864, 84093)),
  ("23 Apr 2026", &"Blog post [Relays for Nimony's standard library]({blog}relays.html).", blog & "relays.html"),
  ("27 Apr 2026", "\"Nimony can now compile itself.\" Full bootstrap on Linux on 2 May, Windows 5 May, macOS 10 May.", f(13864, 84172)),
  ("1 May 2026", "**NIF27**: NIF becomes a general data format, easy enough for people to write.", f(13864, 84218)),
  ("13 May 2026", "A cold `check` of the compiler: 1.86 s for Nimony against 3.09 s for Nim 2; hot: 0.13 s.", f(13864, 84363)),
  ("14 May 2026", "Macros, and `{.feature: \"ignoreStyle\".}` for Nim 2's style-insensitive names.", f(13864, 84372)),
  ("22 May 2026", "**dagon** (docs) and a package manager (first nimpac, now **pnak**).", f(13864, 84484)),
]

term("token streams and cursors", "no AST: the program is a flat array of 8-byte tokens", &"""
The design Araq is proudest of ([Implementing NIF]({blog}nif_implementation.html)). Nimony never
builds a tree of node objects. A module is a flat buffer (`TokenBuf`) of `PackedToken`s, 8 bytes
each: 4 bits of kind, 28 bits of payload (an id into a string, symbol or number table), and 4
bytes of packed line information. A "tree" is just `(`, children, `)` in that array, and a
**cursor** walks it, skipping a subtree by counting parentheses. Each pass reads one buffer and
writes a new one.

Why it is safer: the closing `)` tokens are explicit, so a pass that forgets to handle a child
breaks the parenthesis count at once, where a tree-based pass would silently drop `n.left`. A
buffer is sealed while a cursor reads it (no iterator invalidation) and cannot be copied (a
Nim 2 `=copy` hook marked `.error`). "The tree exists only implicitly in the call stack."
Helper structures like symbol tables are built for one pass and thrown away.
""", taka = "PackedToken, TokenBuf, Cursor", tsince = "the design since 2024; [explained Mar 2026](" & blog & "nif_implementation.html)")

term("NIF24, NIF26, NIF27", "versions of the NIF spec, named by year", """
The first line of a NIF file names its version: `(.nif24)`, `(.nif26)`, `(.nif27)`. NIF26 (Jan
2026) brought a better index and NIF's own module system (Nim 2's IC files shrank from 4 MB to 3.3
MB); NIF27 (May 2026) made NIF a general data format, friendlier to write by hand, with
`.lang` blocks so one file can mix languages (`(.lang html (div ...))`). Yes, NIF27 appeared in
2026: the version is ahead of the calendar.
""", tsince = "[NIF26 Jan 2026](" & f(13651, 82706) & "), [NIF27 May 2026](" & f(13864, 84218) & ")")

term("cyclic imports", "two modules may import each other, if both say so", """
Nim 2 forbids import cycles, which forces people to merge modules or make fields public. Nimony
needs no forward declarations, so cycles are possible: every import in the cycle must be marked
`import foo {.cyclic.}`.
""", tsince = "[Feb 2026](" & f(13651, 83309) & ")")

term("borrow checking", "simple, local rules against aliasing and iterator invalidation", &"""
While you hold a borrow (for example iterating with `mitems(data.items)`), you may not mutate
the borrowed path or any **prefix** of it (`data`, `data.items`), but you may read it and you may
mutate disjoint siblings (`data.metadata`). Borrowing is only allowed from **simple paths**
(`data.items[i]`, not `getPtr()[].field`), so the compiler can check it locally. Paths through a
`ref` are rejected because another alias could change them: either move the container out and
back in, or write `uncheckedBorrow app.users` to take the responsibility yourself. Araq's rules,
[posted in Oct 2026]({f(14201, 86426)}); the rules were also modelled in **Lean** (a proof
assistant), which found bugs. "The borrow checker is now considered to be complete" (20 Oct 2026).
Nim 2 will get it next.
""", taka = "uncheckedBorrow", tsince = &"[Mar 2026]({f(13651, 83608)})")

term("sum types and pattern matching", "`case` objects with real patterns, plus Opt[T] and Result[T, E]", """
From RFC 559: a new `case` syntax inside objects and matching on it, positionally:
`of AddOpr(a, b): eval(a) + eval(b)`. In Jul 2026 the stdlib gained `Opt[T]` and `Result[T, E]`
built on them (even though Araq still prefers exceptions to Option for "the auto-return
behavior").
""", tsince = "[Apr 2026](" & f(13651, 83895) & ")")

term("strings: SSO, COW, no terminating zero", "Nimony's own string type", """
Nimony strings dropped C's terminating zero (it costs memory and rules out O(1) slicing), so
converting to `cstring` is explicit and may copy. Since Mar 2026 they use **small-string
optimization** (short strings live inside the string header, no allocation) and **copy-on-write**
(copies share the buffer until one is changed).
""", tsince = "[Mar 2025](" & f(12693, 78674) & "), [SSO/COW Mar 2026](" & f(13651, 83749) & ")")

term("validator", "a checker for plugins and compiler passes", """
A tool, `bin/validator`, that checks that NIF processing code is complete and correct: exhaustive
`case` statements, exhaustive traversal with cursors, and output trees that match the grammar in
`tags.md` for each phase. Every plugin is validated before it runs. "Quite far away from formal
verification, but it's much more than primitive linting."
""", tsince = "[Apr 2026](" & f(13864, 84093) & ")")

term("bootstrap", "the compiler compiles itself", """
A compiler *bootstraps* when it can compile its own source, and the result can compile it again
and produce the same thing. Planned for Dec 2025, done 27 Apr to 10 May 2026 on Linux, Windows
and macOS. Araq credits the "no hacks allowed" policy: "Claude loves NIF27 and my codebase."
""", tsince = "[Apr 2026](" & f(13864, 84172) & ")")

term("relays", "global proc variables that a platform driver fills in", &"""
Araq's pattern for the parts of the stdlib that touch the outside world (clock, events, drawing,
page allocation, file access): a module exports a global proc variable, a *driver* assigns it at
start-up, and portable code calls an ordinary proc that forwards to it. Adapters can wrap a relay
(logging, recording and replaying UI events for tests). Used by the
[uirelays](https://github.com/nim-lang/uirelays) UI library. See the
[blog post]({blog}relays.html).
""", tsince = "[Apr 2026](" & blog & "relays.html)")

term("dagon and pnak", "the doc generator and the package manager", """
Two user-facing tools (Lovecraft names, like most of the toolchain). **dagon** turns checked NIF
into API docs (HTML, or NIF for other tools). **pnak**, "Pnakotic Nimony Archive Kontrol",
fetches dependencies from a `.nimble` file's `requires` and pins them to commits; no SAT solver:
the requirement closest to your project wins.
""", taka = "nimpac", tsince = "[May 2026](" & f(13864, 84484) & ")")

nbNote(nkNim2, &"""
**IC in Nim 2.** In Jul 2026 `nim ic` (instead of `nim c`) landed in Nim devel, with BIF files and
`nim track` (one-shot goto-definition and find-uses, no nimsuggest server). A partial rebuild can
take 0.3 s; Araq's "carefully crafted misleading benchmark" shows 22 s down to 0.45 s. **Nim 2.4.0**
shipped on [28 Oct 2026]({f(14251, 86508)}): "compile your code with `--ic:on`". Araq on IC: "It took
the development of an entirely new compiler and then months of grinding with AI to bring it to
Nim... Easily the hardest problem of my entire career."
""")

# =========================================================================================== 5
chap("native", "Jun to Sep 2026: Leng, Shoggoth, Arkham, no C compiler", "progress reports, parts 6 and 7")

nbEvents @[
  ("4 Jun 2026", "Nim's own allocator ported (mimalloc optional). A new optimizer, **shoggoth**; native code generators for amd64 and arm64, **arkham**: \"hello world\" without a C compiler.", f(13864, 84683)),
  ("7 Jun 2026", "A \"benchmark-winning\" JSON library, built on the NIF API.", f(13864, 84726)),
  ("11 Jun 2026", "Nearly libc-free: Nimony calls the operating system's entry points directly.", f(13864, 84783)),
  ("15 Jun 2026", "Commit \"renamefest: nifc -> leng\", \"because everybody, LLMs included, always confused\" NIF and NIFC.", ""),
  ("26 Jun 2026", "The `||` parallel for loop.", f(13864, 84952)),
  ("1 Jul 2026", "The `.bundle` pragma for custom backends on Leng.", f(14014, 85009)),
  ("4 Jul 2026", "`range` is checked at compile time, completely: unprovable conversions are rejected.", f(14014, 85091)),
  ("4 Jul 2026", "Nim 2's IC switches from text NIF to binary **BIF**: `system.bif` is half the size.", f(13585, 85069)),
  ("28 Jul 2026", "The whole compiler runs on **nifcore**, the latest NIF API.", f(14014, 85407)),
  ("4 Aug 2026", "Nimony with Arkham bootstraps on Linux x86-64: no LLVM, no GCC, no C.", f(14014, 85473)),
  ("10 Aug 2026", "Building the compiler: 5.8 s native (`nimony n`) against 18.2 s via GCC; the code is 1.5 to 1.8 times slower than GCC's.", f(14014, 85524)),
  ("22 Aug 2026", "Nimony + Arkham bootstrap on a Raspberry Pi (arm64).", f(14014, 85675)),
  ("27 Aug 2026", "Memory layouts for embedded chips (ARM Cortex-M, RISC-V 32, AVR).", f(14014, 85717)),
  ("29 Aug 2026", "WebAssembly: `nimony w`.", f(14014, 85733)),
  ("31 Aug 2026", "NJVL's pipeline is removed.", ""),
  ("8 Sep 2026", "**Nimony 0.6.2**, with a guest report by tokyovigilante on a year of porting projects.", "https://nim-lang.github.io/nimony-website/version0_6.html"),
  ("14 Sep 2026", "Nimony's own lexer and parser, generated from a DSL by plugins.", f(14014, 85982)),
  ("15 Sep 2026", "`{.feature: \"staticContracts\".}`: every contract must be proven.", f(14014, 86003)),
  ("18 Sep 2026", "The backend uses the \"Final IR\" consistently: \"the last big refactoring of the compilation pipeline\".", f(14014, 86047)),
  ("20 Sep 2026", "The JavaScript backend: `nimony j`.", f(14014, 86065)),
  ("21 Sep 2026", "Peak memory: 45 MiB for the hungriest front-end process.", f(14014, 86071)),
]

term("Leng", "the low-level, C-like NIF dialect (was NIFC), the Arkham IR", &"""
The dialect that used to be NIFC, renamed in Jun 2026 to end the NIF/NIFC confusion. It is C's
level of abstraction written as NIF: types, procs, structured control flow, no generics or
closures. Every backend reads it: **lengc** turns it into C (or LLVM text), arkham into machine
code, the JS and wasm backends into theirs. Also called the **Arkham IR**.
[Spec]({docs}internals/leng-spec.md).
""", taka = "NIFC, Arkham IR, lengc", tsince = "renamed 15 Jun 2026")

term("Shoggoth", "the middle end: lowering, dead code elimination, optimizer", &"""
Named after the Lovecraftian monster. It first appeared in Jun 2026 as the optimizer working on
Leng (inlining across modules, CSE, a vectorizer, run for `--opt:speed`/`size`). On 6 Oct 2026
**hexer** was folded into it: "Hexer is gone and part of Shoggoth. This one was very important
to me personally as Hexer is no lovecraftian monster." Today Shoggoth takes the checked program
(the **Shoggoth IR**) and lowers it: inline iterators, lambda lifting, inject copies ("dups") and
destructors, turn `if` expressions into statements, map builtins to runtime calls, translate
exceptions, generate Leng, then whole-program dead code elimination.
""", taka = "hexer, Shoggoth IR", tsince = &"[Jun 2026]({f(13864, 84683)}), [hexer merged Oct 2026]({f(14201, 86241)})")

term("Arkham and nifasm", "the native backend: machine code with no C compiler", &"""
**arkham** (Arkham is Lovecraft's fictional town) turns Leng into machine code for x86-64 and
arm64 (Cortex-M and RISC-V 32 partly), and **nifasm**, a *typed* assembler, assembles and links
it into ELF, Mach-O or PE executables: no C compiler, assembler or system linker. It lives in
[nim-lang/nativenif](https://github.com/nim-lang/nativenif). You use it with `nimony n`. Why?
"To prove that the Leng IR is capable of doing it. To keep the foundations clean of .emit hacks.
To offer you a type checked assembler in Nim syntax." And C: "I'll drag the C backend along for
portability and interop, I just won't pretend compiling-to-C is a good long-term codegen
strategy."
""", taka = "NativeNif, `nimony n`", tsince = "[Jun 2026](" & f(13864, 84683) & ")")

term("assembler procs", "machine code written in Nim syntax, one statement per instruction", &"""
An `{{.assembler.}}` proc is machine code in Nim syntax: each statement is one instruction, every
local declares its register (`var t {{.register: "r8".}}: uint64`), and nothing is reordered.
Its use: code whose correctness depends on *which* instructions run, above all constant-time
cryptography (`std/crypto/x25519`, `chacha20poly1305`). The `httpclient` with its own TLS
(Oct 2026) was built to try out this "Nim-as-inline-assembler design".
[Doc]({docs}assembler.md).
""", tsince = "[Aug 2026](" & f(14014, 85729) & ")")

term("BIF", "binary NIF: the same tokens, loaded with mmap", """
"Binary NIF": the token stream written as raw 32-bit tokens with an index, little-endian, with a
version byte (now 5). It trades readability for loading speed (memory-mapped, no parsing).
Converters `nif2bif`/`bif2nif` exist. Third parties wrote codecs (nifkit).
""", tsince = "[Jul 2026](" & f(13585, 85069) & ")")

term("nifcore", "the latest NIF API inside the compiler", """
The third generation of the library that reads and writes NIF inside the toolchain, with lower
memory use, binary BIF support and a plugin API on top. The whole codebase was ported to it by
Jul 2026; plugins too.
""", tsince = "[Jul 2026](" & f(14014, 85407) & ")")

term("multi-join IR (Final IR)", "the control-flow form shared by both IRs, with forward jumps to labels", &"""
What replaced NJVL in practice. Control flow is reduced to three things: `loop` (one back edge,
no condition slot), `ite` (if-then-else), and forward, scoped `(jmp L)` to a `(lab L)`; any number
of jumps may join at one label, hence the name. Control flow inside expressions is lowered to
statements, so any sub-expression can be hoisted into a statement just before its own (the
"hoisting rule" every later pass relies on). The front end lowers to it as its last step and runs
the **prover** on it, so the published module already says which run-time checks are still
needed. The code still calls it "Final IR". [Doc]({docs}internals/multi_join_ir.md).
""", taka = "Final IR", tsince = "[Sep 2026](" & f(14014, 86047) & ")")

term("staticContracts", "a module where every contract must be proven", &"""
`{{.feature: "staticContracts".}}` turns "undecided" into an error for every contract in the
module, so all array indexing is proven in bounds at compile time: "making IndexError
exceptions a thing of the past". `strutils` compiles with it since 28 Oct 2026; since 4 Nov the
prover also reasons about integer overflow. dwhall256's thread walks through the
[strutils diff](https://forum.nim-lang.org/t/14257).
""", tsince = "[Sep 2026](" & f(14014, 86003) & ")")

term("`nimony c`, `n`, `w`, `j`", "one compiler, four kinds of output", """
`nimony c` compiles through C (with a C compiler), `nimony n` natively through Arkham,
`nimony w` to WebAssembly, `nimony j` to JavaScript. An LLVM path exists in lengc too.
""", tsince = "Aug and Sep 2026")

term("`||` parallel for", "structured parallelism without FlowVars", """
`for i in 0 || 1: r[i] = pfib(n - 1 - i)`: like `0 .. 1`, but every iteration runs in parallel.
The compiler checks that the writes `r[i]` do not race, and the parallelism ends with the loop.
No `spawn`, no FlowVar, no `sync`. Araq considers it simpler than his Malebolgia library.
""", tsince = "[Jun 2026](" & f(13864, 84952) & ")")

# =========================================================================================== 6
chap("complete", "Oct to Nov 2026: feature complete, the fuzzer, avoidtemps", "progress report, part 8")

nbEvents @[
  ("2 Oct 2026", "FreeBSD. ORC and YRC ported: all four memory modes plus custom ones with `--mm:<path>`.", f(14201, 86216)),
  ("3 Oct 2026", "`break` and `block` work \"as they should for Nim 3\" (RFC 576).", f(14201, 86220)),
  ("6 Oct 2026", "Better decisions about what to recompile. Hexer is folded into Shoggoth.", f(14201, 86241)),
  ("13 Oct 2026", "`owned ref T`, like Nim devel.", f(14201, 86298)),
  ("16 Oct 2026", "An `httpclient` with its own TLS, to try the assembler design.", f(14201, 86331)),
  ("17 Oct 2026", "Borrowing rules modelled in Lean; bugs found and fixed.", f(14201, 86371)),
  ("20 Oct 2026", "Strict funcs (\"No standard library code broke\"); \"The borrow checker is now considered to be complete.\"", f(14201, 86422)),
  ("27 Oct 2026", "\"Focus is on bugfixes, Nimony is feature complete. But I've been saying this for some time, I think.\"", f(14201, 86496)),
  ("28 Oct 2026", "Nim 2.4.0 released, with IC. `strutils` compiles with staticContracts; the regex engine is much faster.", f(14201, 86518)),
  ("4 Nov 2026", "The prover reasons about integer overflow, \"yet again a big change that caused the rewrite of lots of stdlib code\".", f(14201, 86599)),
  ("13 Nov 2026", "\"A fuzzer has found hundreds of bugs so far. It is not clear how many of these we will be able to fix before the great christmas release...\"", f(14201, 86744)),
  ("22 Nov 2026", "\"The plugin called avoidtemps the manual outlined is now a reality.\"", f(14201, 86812)),
]

term("memory management modes", "atomicArc by default; arc, orc, yrc, or your own", &"""
Nim 2's destructor-based memory management, reimplemented ("Nim 2's way of doing it is basically
perfect"). Values are freed when their owner goes out of scope; `ref`s are reference counted.
`--mm:atomicArc` (default) updates counts atomically so refs can cross threads; `arc` without
atomics; `orc` adds a cycle collector; `yrc` is a thread-safe `orc` whose collector runs
concurrently. A strategy is just a file `lib/std/system/<name>.nim` defining three primitives, so
`--mm:<path>` plugs in your own. [stdlib guide]({docs}stdlib.md).
""", taka = "ARC, ORC, YRC", tsince = "[Oct 2026](" & f(14201, 86216) & ")")

term("`owned ref T`", "a checked unique owner for a ref (RFC 575)", &"""
`owned X` marks the location that holds the *unique owning* edge to a ref cell; ordinary refs to
it can still exist and keep it alive. Copying an owned location is an error (move it instead),
and `{{.feature: "ownedRefs".}}` makes object construction return `owned`. It gives a way to
build parent/child structures without cycles. [Manual]({docs}language.md#owned-references).
""", tsince = "[Oct 2026](" & f(14201, 86298) & ")")

term("strict funcs", "a `func` cannot mutate through refs either", """
Nim 2's `--experimental:strictFuncs`: a `func` may not change anything reachable through its
parameters' refs, not only its own variables. In Nimony `func`, `iterator` and `converter` are
side-effect free by default and `proc` is not. Turning strict funcs on broke no stdlib code.
""", tsince = "[Oct 2026](" & f(14201, 86418) & ")")

term("break and block, case sensitivity", "two small Nim 3 changes, each with an opt-out", """
An unlabeled `break` now only leaves a loop, never a `block`; leave a block with
`break blockName` (opt out with `{.feature: "anonBlockBreaks".}`). Nimony is case sensitive;
`{.feature: "ignoreStyle".}` restores Nim 2's style-insensitive names per module. Signed integer
overflow wraps around (`high(int) + 1 == low(int)`); `{.keepOverflowFlag.}` detects it.
""", taka = "anonBlockBreaks, ignoreStyle", tsince = "Oct 2026; May 2026")

term("fuzzer", "random programs that hunt compiler bugs", """
A fuzzer generates many random (but valid) programs and checks that the compiler neither crashes
nor miscompiles them. Since Nov 2026 it has found "hundreds of bugs", now the main work before
the release planned for Christmas 2026.
""", tsince = "[Nov 2026](" & f(14201, 86744) & ")")

# =========================================================================================== 7
chap("today", "The pipeline today", "Nov 2026")

nbText: &"""
This is what `nimony c hello.nim` runs, from [design.md]({docs}design.md) and the repo's
`AGENTS.md`. Every arrow is a file in `nimcache/`, and nifmake reruns only the stages whose
inputs changed.
"""

nbPipeline("From Nim source to an executable", @[
  (tool: "**nifler**", what: "parses each `.nim` file to NIF, no symbol table needed", makes: "`M.p.nif`"),
  (tool: "**nimsem**", what: "symbol lookup, type checking, generics, templates, macros and plugins; injects dereferences; lowers to the multi-join form and runs the prover (contracts, nil, borrow checks)", makes: "the **Shoggoth IR** `M.s.nif`, plus the interface `M.s.idx.nif` other modules read"),
  (tool: "**shoggoth**", what: "lowering: iterator inlining, lambda lifting, dups, control flow expressions to statements, destructors, builtins to runtime calls, exceptions, CPS for passive procs; then whole-program dead code elimination; optional optimizer for `--opt:speed`", makes: "the **Arkham IR**, Leng"),
  (tool: "**lengc** or **arkham + nifasm**", what: "C (or LLVM text) for a C compiler; or machine code and a finished executable directly; or JS, or wasm", makes: "your program"),
])

nbText: """
Around it: **nimony** is the driver that schedules everything through **nifmake**; **hastur**
builds and tests the toolchain itself (`hastur build all`); the **validator** checks every pass's
output; **dagon** writes docs from the checked NIF; **pnak** fetches packages; **niflink** drives
linking for the C path.
"""

term("nimsem and the nimony driver", "the semantic checker, and the program you run", """
**nimony** is what you type; it works out the module graph, writes a build file for nifmake and
lets it run the other tools. **nimsem** is the front end proper: everything from symbol lookup to
the prover. Araq's debugging advice: assume nifler, nifmake and lengc are stable, "most problems
tend to be in Nimony or Shoggoth".
""")

term("hastur", "the build and test driver of the toolchain", """
Another Lovecraft name. `nim c -r src/hastur/hastur build all` builds every tool into `bin/`;
`hastur test`, `hastur bug`, `hastur rep` run tests and reproduce bugs. You need an existing Nim 2
only to build Nimony from source; the nightly builds need nothing.
""")

# =========================================================================================== 8
chap("names", "The names that changed", "a rename map")

nbText: "Most confusion in the forum threads comes from names that changed while the work went on."

nbTable toTableData(@[
  (was: "NIR (2023)", now: "NIF", since: "Oct 2024", why: "NIR was for backends only, NIF is for everything"),
  (was: "nim-lang/nif repo", now: "nim-lang/nimony, spec in nim-lang/nifspec", since: "late 2024", why: "the spec got its own repo in Dec 2024"),
  (was: "gear3", now: "hexer", since: "Jan 2025", why: "commit \"gear3 is now hexer\""),
  (was: "aufbruch mode", now: "(gone)", since: "Mar 2026", why: "Nimony grew past a minimal mode"),
  (was: "NJVL", now: "NJ, then nothing", since: "Jan 2026, removed Aug 2026", why: "replaced by the multi-join IR (Final IR)"),
  (was: "nimpac", now: "pnak", since: "May 2026", why: "the package manager"),
  (was: "NIFC", now: "Leng (Arkham IR), lengc", since: "Jun 2026", why: "everyone confused NIF and NIFC"),
  (was: "hexer", now: "Shoggoth", since: "Oct 2026", why: "\"Hexer is no lovecraftian monster\""),
  (was: "async / await", now: "`.passive`, no await", since: "Jul 2025", why: "a working title that stuck"),
]):
  tabHeader "Old name, new name"
  colsLabel:
    was: "was"
    now: "now"
    since: "when"
    why: "why"
  fmtMarkdown ["now"]

nbNote(nkCareful, """
The forum posts use whatever name was current at the time: a 2025 post saying "NIFC" and a 2026
commit saying "Leng" mean the same thing. Some docs in the repo still mention old names (the
repo's own agent instructions say to ignore stray mentions of NJVL).
""")

# =========================================================================================== 9
chap("glossary", "Index of terms", "every card on this page")

nbTable toTableData(index), rownameCol = "term":
  tabHeader "Terms, in the order they appear"
  colsLabel:
    short: "in one line"
    chapter: "chapter"
  fmtMarkdown ["term", "short"]

# =========================================================================================== 10
chap("sources", "Sources", "read on 22 Nov 2026")

nbText: &"""
**Forum threads** (in order): [NIR](https://forum.nim-lang.org/t/10594) (2023),
[NIF, NIFC, native code](https://forum.nim-lang.org/t/12534) (2024),
[Nimony progress](https://forum.nim-lang.org/t/12693) and progress reports
[part 2](https://forum.nim-lang.org/t/12978), [3](https://forum.nim-lang.org/t/13357),
[4](https://forum.nim-lang.org/t/13438), [5](https://forum.nim-lang.org/t/13651),
[6](https://forum.nim-lang.org/t/13864), [7](https://forum.nim-lang.org/t/14014),
[8](https://forum.nim-lang.org/t/14201);
[Curious about nimony's new features](https://forum.nim-lang.org/t/12708),
[Nimony compiler plugins](https://forum.nim-lang.org/t/12830),
[Nimony async runtimes](https://forum.nim-lang.org/t/13316),
[JS backend](https://forum.nim-lang.org/t/13363),
[NJVL](https://forum.nim-lang.org/t/13471),
[Progress report on IC](https://forum.nim-lang.org/t/13585),
[Nimony async/passive procs](https://forum.nim-lang.org/t/13999),
[staticContracts by example](https://forum.nim-lang.org/t/14257),
[Nim 2.4.0](https://forum.nim-lang.org/t/14251), and a dozen smaller ones (Termux, building,
nifkit, the template plugin).

**Araq's blog:** [Nimony: design principles]({blog}nimony.html) (May 2025),
[S-expressions]({blog}sexpressions.html) (Feb 2026),
[Implementing NIF in Nim]({blog}nif_implementation.html) (Mar 2026),
[Relays]({blog}relays.html) (Apr 2026).

**Repo and site:** [nim-lang/nimony]({repo}) at commit `36bde262` (22 Nov 2026):
[design.md]({docs}design.md), [differences.md]({docs}differences.md),
[language.md]({docs}language.md), [plugins.md]({docs}plugins.md),
[passive_procs.md]({docs}passive_procs.md), [lenientnils.md]({docs}lenientnils.md),
[assembler.md]({docs}assembler.md), the internals docs (IC, multi-join IR, contracts), the git
history; [nifspec](https://github.com/nim-lang/nifspec); the
[Nimony website](https://nim-lang.github.io/nimony-website/) (FAQ, tools, release articles).
"""

nbNote(nkCareful, """
Not read: GitHub discussion #529 (Nimony's early design plan, which this session could not
open; its content lives on in `differences.md`) and the Discord conversations Araq sometimes
refers to. Dates are the day of the forum post, in UTC.
""")

nbSave
