## The cloakroom of the future: Henrik Bengtsson's R futureverse, explained to a Nim programmer,
## by building a toy version of it (fv.nim) and running it on this page.
## Build: sh deps.sh && nim r index.nim (from this folder; writes ../index.html). Needs libpcre3.
import std/[os, strformat, strutils, sequtils, monotimes, times, osproc]
import fv, examples/tasks
fvServe()    # when this page is started as a worker process of the processes plan, serve and quit

import nimib
import tabelline, tabelline/nimib
import malebolgia, taskpools
import std/asyncdispatch
import lib/[style, blocks]
import review          # tabelline's review mode, from claude-artifacts shared/review (unchanged copy)

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.title = "Back to the futureverse: R's futures, explained in Nim"
nb.useExplainerStyle
nbReview(tpage = "futureverse-nim", tsource = "futureverse-nim/src/index.nim")

const
  paper = "https://arxiv.org/html/2601.17578v1"
  rjournal = "https://doi.org/10.32614/RJ-2021-048"
  site = "https://www.futureverse.org/"
  futureRepo = "https://github.com/futureverse/future"
  futurizeRepo = "https://github.com/futureverse/futurize"
  malebolgiaRepo = "https://github.com/Araq/malebolgia"
  taskpoolsRepo = "https://github.com/status-im/nim-taskpools"
  fvSrc = "#fv-source"
  checkArgs = "-p:" & quoteShell(currentSourcePath().parentDir) & " -p:" &
    quoteShell(getEnv("FV_DEPS", currentSourcePath().parentDir / "deps") / "malebolgia" / "src")

let fvLines = lineCount("fv.nim")

nbText: "# Back to the futureverse"

nbPrompt("Pietro", "25 Nov 2026", &"""
At compute Paris I have met Henrik, author of a popular library for parallelizing R code. Can you
explain some of the concepts about that, when it makes sense using Nim? I know only the basics of
R, I know it has a functional connection but not more than that. Here are a couple of references
{paper} {site} build and merge an explainer as usual with nimib and publish on Claude artifacts.
Be playful and go wild!
""")

nbLede: &"""
Henrik Bengtsson's **futureverse** ("you keep your code, and you decide where it runs") lets an R programmer write `lapply(xs, slow)`, add one word,
and have it run on all the cores of a laptop, on a few machines, or on a supercomputer, with
nothing else changed. This page explains the ideas behind it for someone who knows Nim and only a
little R. The best way to understand a design is to build it, so we build a toy futureverse
in Nim ({fvLines} lines), and every example on this page runs on it when the page is built.
Fasten your seatbelt: we travel through a cloakroom, a few time machines and a macro.
"""

nbTldr: &"""
- **A future** is a coat-check ticket: you hand in some work, get a ticket at once, and collect
  the value later. Nim has the same idea in [taskpools]({taskpoolsRepo}) (`spawn`/`sync`) and
  in `std/asyncdispatch` (for waiting rather than computing).
- **The big idea** is a split of roles: the *developer* says **what** may run concurrently, the
  *end-user* says **how and where** with `plan()`. The code never names a backend.
- **The hard part** is making parallel code behave like sequential code: the same random numbers
  on any number of workers, output and errors arriving in order, progress bars. Our toy does all
  of it on threads (via [malebolgia]({malebolgiaRepo})) and on worker processes.
- **futurize()**, the newest piece, rewrites a plain map into a parallel one. In Nim that is
  just a macro, and we write it: `xs.mapIt(it * it) |> futurize(seed = 1)`.
- **In Nim** you need all this less often (compiled loops are fast, and threads share memory),
  but the split of roles, the seeds and the relaying are worth borrowing.
"""

# ============================================================================================ 0
nbText: """
## Just enough R

R is a language for statistics. Two things about it matter here. It is **functional**: functions
are values, and the usual way to loop is to hand a function to a *map*, `lapply(xs, f)`, which
applies `f` to every element of `xs` and gives back the list of results. And an R session runs
your code on **one thread**: to use more cores, R starts more R processes and ships the work to
them. The little R this page uses, next to its Nim:
"""

nbTable toTableData(@[
  (r: "`xs <- 1:8`", nim: "`let xs = toSeq(1..8)`", what: "a vector of 1 to 8"),
  (r: "`f <- function(x) x^2`", nim: "`proc f(x: int): int = x*x`", what: "a function is a value"),
  (r: "`lapply(xs, f)`", nim: "`xs.map(f)`", what: "map f over xs"),
  (r: "`purrr::map(xs, f)`", nim: "`xs.map(f)`", what: "the same, from the tidyverse"),
  (r: "`xs |> f()`", nim: "`xs.f()`", what: "the pipe: `x |> f(y)` is `f(x, y)`"),
  (r: "`message(\"hi\")`", nim: "`stderr.writeLine \"hi\"`", what: "a message, which R can catch"),
  (r: "`set.seed(42)`", nim: "`randomize(42)`", what: "seed the random numbers"),
]), rownameCol = "r":
  tabHeader "R and Nim, side by side"
  colsLabel:
    r: "R"
    nim: "Nim"
    what: "what it does"
  fmtMarkdown ["r", "nim", "what"]

nbNote(nkR, &"""
The futureverse is a family of packages: **future** (the core, 2015), **future.apply**
(parallel `lapply` and friends), **furrr** (parallel purrr, by Davis Vaughan), **doFuture**
(for `foreach`), **progressr** (progress bars), **parallelly** (how many cores may I use?),
backends such as **future.mirai** and **future.batchtools**, and since this year
**futurize** (the subject of the [paper Pietro sent]({paper})) and its sibling **progressify**.
The design is in the [R Journal paper of 2021]({rjournal}). And it is not niche: according to
[futureverse.org]({site}), as of November 2026 about 1,300 CRAN packages depend on future
directly or indirectly (5.1% of CRAN), among them Seurat, mlr3, targets and shiny, and in eleven
years it has had no breaking update.
""")

nbTimeline("The futureverse's time-travel log", @[
  (date: "1977", what: "Baker and Hewitt name *futures*"),
  (date: "JUN 2015", what: "first release of future on CRAN"),
  (date: "2021", what: "the design in The R Journal"),
  (date: "JUN 2025", what: "ten years of future"),
  (date: "JAN 2026", what: "futurize: one magic word"),
  (date: "NOV 2026", what: "Henrik meets Pietro at Compute Paris"),
])

# ============================================================================================ 1
nbText: """
## A future is a coat-check ticket

At a Paris cloakroom you hand over your coat, get a numbered ticket at once, and go to the
talk. Later you hand back the ticket and get your coat. A **future** is that ticket, for a
computation: creating it is quick, the work happens somewhere else, and asking for its **value**
waits only if the work is not done yet.
"""

nbSteps("The three verbs of the future package: `future()`, `resolved()`, `value()`.", @[
  (icon: "🧥", title: "`f <- future(expr)`", what: "hand in the work, get a ticket at once"),
  (icon: "🎟️", title: "`resolved(f)`", what: "peek: is my coat ready? (never waits)"),
  (icon: "🧥", title: "`value(f)`", what: "collect it, waiting if needed; errors come back here"),
])

nbR("""
library(future)
plan(multisession)               # more on this in N° 2
a <- future({ Sys.sleep(1); 3^2 })
b <- future({ Sys.sleep(1); 4^2 })
value(a) + value(b)              # about 1 second, not 2
""", "[1] 25")

nbText: &"""
Nim has futures too. With [taskpools]({taskpoolsRepo}) (Status's thread pool) the ticket is
a `Flowvar` and `sync` collects it. This runs as the page is built, on 4 threads:
"""

nbCode:
  proc slowCube(x: int): int =
    sleep 100
    x * x * x

  var tp = Taskpool.new(numThreads = 4)
  let t0 = getMonoTime()
  let a = tp.spawn slowCube(3)       # a ticket, at once
  let b = tp.spawn slowCube(4)
  echo "two tickets after ", (getMonoTime() - t0).inMilliseconds, " ms"
  echo "a + b = ", sync(a) + sync(b), " after ", (getMonoTime() - t0).inMilliseconds, " ms"
  tp.shutdown()

nbText: """
And Nim's standard library has `Future[T]` in `std/asyncdispatch`. Same ticket, different
cloakroom: these futures run on **one** thread, and are for *waiting* (on the network, on a
timer) rather than for computing. Three waits of 300, 100 and 200 ms take 300 ms together:
"""

nbCode:
  let s0 = getMonoTime()
  proc fetch(name: string; ms: int): Future[string] {.async.} =
    await sleepAsync(ms)             # waiting, not working: the thread is free meanwhile
    return name & " ready after " & $(getMonoTime() - s0).inMilliseconds & " ms"

  for s in waitFor all(@[fetch("coat", 300), fetch("hat", 100), fetch("scarf", 200)]):
    echo s

nbNote(nkAside, &"""
Henrik's paper makes this distinction in its first footnote: **concurrent** describes the logical
structure ("these can happen in any order"), **parallel** the physical execution ("these happen
at the same time, on different cores"). A future is a concurrency idea; the backend decides
whether it becomes parallelism. That is why futures are not only about speed: Shiny apps use
them to stay responsive while a slow computation runs in the background, which is exactly the
job of Nim's async futures above.
""")

# ============================================================================================ 2
nbText: """
## plan(): who stands behind the counter

Here is the idea that makes the futureverse more than a thread pool. A package author writing
`future()` or a parallel map **never says where it runs**. The person *using* the code picks
that, once, with `plan()`:
"""

nbR("""
plan(sequential)                              # one attendant: no parallelism (the default)
plan(multisession, workers = 4)               # 4 R processes on this machine
plan(multicore)                               # forked R processes (Linux, macOS)
plan(cluster, workers = c("n1", "n2"))        # R processes on other machines, over SSH
plan(future.callr::callr)                     # a fresh R process per future
plan(future.mirai::mirai_multisession)        # mirai's low-latency workers
plan(future.batchtools::batchtools_slurm)     # jobs on an HPC scheduler (also LSF, SGE, PBS)
plan(future.p2p::cluster, cluster = "alice/friends")  # a prototype: your friends' laptops
""")

nbText: """
The same `lapply(...) |> futurize()` then runs on a laptop, on a lab's machines, or as Slurm jobs
on a cluster. The paper calls this **separation of concerns**: the developer decides *what*,
the end-user decides *how and where*. A rule follows from it: **packages must never call
`plan()`**, because that would take the choice away from the user (the paper found CRAN packages
that do it anyway; Henrik has a blog post titled *Setting Future Plans in R Functions, and Why
You Probably Shouldn't*). And every backend must pass the conformance tests of **future.tests**
before it may call itself one, so, in the site's words, "switching backend never changes your
results, only where they are computed". Roads? Where this code is going, it doesn't need to
know the roads.

Our toy, `fv`, has three plans. A task is a plain Nim proc; here are the four the page uses,
from `examples/tasks.nim`:
"""

nbSnippet("examples/tasks.nim", ["proc slowSquare*", "proc chatty*", "proc noisy*", "proc fragile*"])

nbText: """
`futureMap(xs, f)` is the parallel map (R's `future_lapply`). It runs on whatever plan is
current. Eight elements of 50 ms each:
"""

nbCode:
  let xs = toSeq(1..8)
  for p in [sequential(), threads(4), processes(4)]:
    plan p
    let t = getMonoTime()
    let ys = futureMap(xs, slowSquare)
    echo plan(), ": ", ys, " in ", (getMonoTime() - t).inMilliseconds, " ms"

nbText: &"""
Same code, same answer, a quarter of the time. `processes(4)` starts **four copies of this very
program**, which is the Nim version of R's `multisession`. It is not much slower than threads
here, because starting a compiled program takes a millisecond or two, not the second or so an R
session takes. How it works: the program is started again with `--fv-worker slowSquare`, and
`fvServe()`, the first line of the program, turns it into a worker that reads elements as JSON
lines on stdin and writes results on stdout.
"""

nbNote(nkNim, &"""
**R ships code; Nim ships only data.** An R worker is an empty R session, so the future package
sends it the expression, the functions it calls and the data they use. A Nim worker is the same
compiled binary, so it already has all the code: only the name of the task and the elements
travel. That is also why a task must be **registered** (`registerTask slowSquare`): the worker
looks it up by name.
""")

nbText: """
How many workers? R's **parallelly** answers with `availableCores()`, which is not the number of
cores of the machine but the number *you may use*: it reads cgroup quotas (containers), HPC
scheduler allocations and a list of environment variables, so a job does not grab all 128
cores of a shared server. `fv` has a tiny version of it:
"""

nbCode:
  echo "countProcessors() = ", countProcessors(), "  (the machine)"
  echo "availableCores()  = ", availableCores(), "  (cgroup quota and FV_AVAILABLECORES)"

nbNote(nkAside, """
On this build machine the two agree. In a container limited to 2 CPUs, `countProcessors()`
would still say the host's count and every thread pool sized from it would oversubscribe.
`std/cpuinfo` could grow an `availableCores` that reads the cgroup quota: a small, useful
Nim PR. (Henrik's blog has a post for R that applies to Nim word for word: *Please avoid
detectCores() in your R packages*.)
""")

# ============================================================================================ 3
nbText: """
## Globals: what is in the coat pockets

Look at a task that uses a variable it did not get as an argument:
"""

nbR("""
rate <- 1.2
f <- function(x) x * rate          # 'rate' is a global of f
ys <- lapply(1:4, f) |> futurize() # the worker must get 'rate' too
""")

nbText: """
A worker process does not have `rate`. So before sending a future, the future package reads the
code of the expression (static analysis, with the **globals** package), finds every name it uses
that is not defined inside it, and ships those values along: the coat *and* what is in its
pockets. This is clever and mostly invisible, and it is where most surprises live (an object
that cannot be copied to another process, like a database connection, breaks).

In Nim, a thread backend does not ship anything: threads share memory. The danger is the
opposite one, two threads touching the same data. Nim's compiler checks it: a proc run on
another thread must be `gcsafe`, so it may not read a global that holds garbage-collected
memory. This snippet does not compile, and the compiler names the global:
"""

nbCompileError("""
var rates = @[1.0, 1.2, 1.5]       # a global seq: memory owned by the main thread

proc f(x: int): float {.gcsafe.} =
  x.float * rates[x mod 3]
""", targs = checkArgs)

nbText: """
So "detect the globals" is a job of the Nim compiler, not of a library, and it is done before
the program runs instead of while it runs. The fix is the one R does for you: pass the data as
an argument (or make it a `const`, which is compiled in). The processes plan sits in between:
a worker process re-runs the program's top-level code up to `fvServe()`, so a global computed
there exists in the worker too, recomputed, not shipped.
"""

nbCompileError("""
import std/sequtils, fv
proc main() =
  let rate = 3
  echo toSeq(1..4).mapIt(it * rate) |> futurize()
main()
""", targs = checkArgs, tcmd = "c --compileOnly", tfold = "The same check, through `futurize` (N° 7): a local variable can't sneak in")

# ============================================================================================ 4
nbText: """
## Random numbers: no time paradoxes

Statisticians parallelize resampling all the time (bootstraps, permutation tests,
simulations), so random numbers are central. Two things go wrong when you run them in parallel
naively. Results change with the number of workers, because each worker's generator hands out
numbers in a different order. And workers seeded carelessly can produce overlapping or
correlated streams.

The futureverse fixes both with `seed = TRUE`: every *element* gets its own stream (L'Ecuyer's
MRG32k3a generator, whose streams are provably far apart), chosen from the element's position.
The result then depends only on the seed, never on the plan: change the past (how many workers,
which machine) and the future stays the same. `fv` does the same with a simpler
trick: element `i` seeds its own generator from `splitmix64(seed, i)`.
"""

nbCode:
  for p in [sequential(), threads(3), processes(4)]:
    plan p
    let ys = futureMap(toSeq(1..6), noisy, seed = 42)
    echo ($plan()).alignLeft(14), ys.mapIt(it.formatFloat(ffDecimal, 3)).join("  ")

block:   # the claim below, checked at build time
  var draws: seq[seq[float]]
  for p in [sequential(), threads(3), processes(4)]:
    withPlan p: draws.add futureMap(toSeq(1..6), noisy, seed = 42)
  doAssert draws[0] == draws[1] and draws[1] == draws[2]
nbText: "Identical, to the last bit. And if a task uses random numbers *without* a seed, you get the futureverse's famous warning, rather than silently unreproducible results:"

nbCode:
  plan threads(4)
  discard futureMap(toSeq(1..6), noisy)

nbNote(nkR, """
R prints `UNRELIABLE VALUE: Future (‘<none>’) unexpectedly generated random numbers without
specifying argument 'seed'.` For `replicate()`, which is nearly always used for resampling,
futurize turns `seed = TRUE` on by itself.
""")

# ============================================================================================ 5
nbText: """
## Output and errors come back as if nothing happened

Run a map in parallel with most tools and the side effects get lost or scrambled. In R,
`parallel::mclapply` drops messages and warnings, and returns errors as values; the paper notes
that many users assume it behaves like `lapply` and are not aware. In Nim, `echo` from threads
just interleaves. Here malebolgia spawns eight tasks that print as they finish (the larger x,
the shorter the sleep):
"""

nbCode:
  proc rawChatty(x: int) =
    sleep (9 - x) * 15
    echo "x = ", x

  var m = createMaster()
  m.awaitAll:
    for x in 1..8:
      m.spawn rawChatty(x)

nbText: """
The futureverse instead **captures** standard output, messages and warnings on the worker and
**relays** them in the main session, in the order a sequential run would show them, after each
future is collected. They are real R conditions again on arrival, so `suppressMessages()` around
the parallel call still works. `fv` does it with `say`: each element's lines are kept with its
result, and the main thread echoes them in element order:
"""

nbCode:
  plan processes(4)
  echo futureMap(toSeq(1..4), chatty)

nbText: """
Errors too: the first failing element (in order) raises its exception on the main thread, where
an ordinary `try` catches it, with its own type:
"""

nbCode:
  plan threads(4)
  try:
    echo futureMap(toSeq(1..8), fragile)
  except ValueError as e:
    echo "caught a ValueError from a worker: ", e.msg

nbNote(nkCareful, """
`fv` cannot pass the exception *object* across: under Nim's ORC memory manager a ref belongs to
the thread that made it (a first version did pass it, and crashed with a segfault in the cycle
collector). So only the name and message travel, and `fv` makes a new exception of the same type
for the common ones. R serializes the whole condition object, class and all. A Nim library done
properly could move the exception with `std/isolation`.
""")

# ============================================================================================ 6
nbText: """
## Progress from far away

Long maps want a progress bar, and the bar must be in the main session while the work is in the
workers. Henrik's **progressr** solves it the R way: `p()` in the task *signals a condition*,
and the future backends relay those near-live, as they happen, not at the end. `fv` takes a
shortcut, `progress = true` ticks once per element from whichever thread finished it:
"""

nbCode:
  plan threads(4)
  discard futureMap(toSeq(1..20), slowSquare, progress = true)

nbText: """
The paper listed a `progressify()` as future work; by now it has shipped. It injects the `p()`
calls itself, so `lapply(xs, slow) |> progressify() |> futurize()` gets a bar with no other
change. `fv` has one too, a macro that the futurize macro unwraps (one of each is enough):
"""

nbCode:
  plan threads(4)
  discard toSeq(1..10).map(slowSquare) |> progressify() |> futurize()

nbText: "Which brings us to the macros."

# ============================================================================================ 7
nbText: &"""
## futurize: where we're going, we don't need future_lapply

Before futurize, parallelizing meant switching function: `lapply` becomes
`future.apply::future_lapply`, `purrr::map` becomes `furrr::future_map`, `foreach() %do%`
becomes `%dofuture%`, each with its own way of passing options. [futurize]({futurizeRepo})
keeps the code you wrote and adds one word:
"""

nbR("""
ys <- lapply(xs, slow_fcn) |> futurize()
ys <- map(xs, rnorm, n = 10) |> futurize(seed = TRUE)
b  <- boot(bigcity, ratio, R = 999, stype = "w") |> futurize()
""")

nbText: """
It works because R is lazy: `futurize()` receives its argument *unevaluated*, as a piece of
code (with `substitute()`), finds which map it is (`base::lapply`? `purrr::map`?), and rewrites
it into the parallel version before running it. The paper calls this **transpiling**. It also
unwraps `{ }`, `local()`, `suppressMessages()` to find the map inside, and knows the parallel
switches of domain packages so you don't have to: the site counts 51 of them on CRAN and
Bioconductor, from boot and glmnet to DESeq2 and SingleCellExperiment.

Nim does code-as-data at compile time: a **macro** receives its argument unevaluated, as a syntax
tree. So the Nim futurize is a macro that recognizes `map(xs, f)` and `xs.mapIt(expr)` from
`std/sequtils` and rewrites them into `futureMap`. Nim does not have R's `|>`, but a macro can be
an operator, so we add that too, in five lines:
"""

nbCode:
  plan threads(4)
  let squares = toSeq(1..8).mapIt(it * it + 1) |> futurize(seed = 1)
  echo squares
  echo toSeq(1..8).map(slowSquare) |> futurize()

nbText: "Like `futurize(eval = FALSE)`, `transpiled` shows what the macro writes:"

nbCode:
  echo transpiled(toSeq(1..8).mapIt(it * it + 1), seed = 1)

nbText: """
Note the `{.nimcall, gcsafe.}` that the macro adds to the generated proc. It is what gives the
compiler error at the end of N° 3: a local variable can't be captured by a proc that runs
somewhere else. And R's `futurize(FALSE)`, which turns every futurize off for debugging, is a
compile-time switch here: build with `-d:futurizeOff` and each futurize becomes the plain map.
"""

nbNote(nkR, """
One difference of philosophy. In R, only the **end-user** may switch futurization off, and
packages must never do it. In Nim the end-user of a library is whoever compiles the program,
so a `-d:` define is the natural place for that switch, and for the plan too, if you want it
fixed at compile time.
""")

# ============================================================================================ 8
nbText: """
## So, does Nim need a futureverse?

Partly. Many of the problems the futureverse solves come from R: an interpreter with one thread,
where parallel means processes, and processes mean shipping code and data. In Nim a slow loop is
often fast enough once compiled, and threads share memory with compiler checks. But some of the
ideas have no good Nim equivalent yet:
"""

nbTable toTableData(@[
  (need: "Many CPU-heavy elements", r: "`plan(multisession)` + a parallel map",
   nim: "threads: [malebolgia](https://github.com/Araq/malebolgia), [taskpools](https://github.com/status-im/nim-taskpools), weave. Try plain compiled code first."),
  (need: "Waiting on network or disk", r: "futures, or `promises` in Shiny",
   nim: "`std/asyncdispatch` or chronos, on one thread"),
  (need: "Code that may crash, leak, or call a C library that isn't thread-safe", r: "`multisession`, `callr`",
   nim: "processes: `std/osproc`, or `fv`'s `processes` (the binary is its own worker)"),
  (need: "A cluster, an HPC scheduler", r: "`future.batchtools`, `future.mirai`, `cluster`",
   nim: "nothing ready-made. A Slurm job array of the same binary is the closest."),
  (need: "The user picks the backend", r: "`plan()`, never inside a package",
   nim: "mostly compile-time (`-d:ThreadPoolSize`); a library that creates its own pool takes the choice away"),
  (need: "Same random numbers on any plan", r: "`seed = TRUE` (L'Ecuyer streams)",
   nim: "by hand: one seeded `Rand` per element, as `fv` does"),
  (need: "Output and errors as in a sequential run", r: "built in, relayed",
   nim: "by hand; `echo` from threads interleaves"),
  (need: "How many cores may I use?", r: "`parallelly::availableCores()`",
   nim: "`countProcessors()` ignores cgroup quotas"),
]), rownameCol = "need":
  tabHeader "When the futureverse's ideas make sense in Nim"
  colsLabel:
    need: "you need"
    r: "R futureverse"
    nim: "Nim today"
  fmtMarkdown ["need", "r", "nim"]

nbText: &"""
What a Nim programmer can take from Henrik, in order of how cheap it is:

1. **Seed per element, not per worker.** Free, and it makes parallel results reproducible.
2. **Relay, don't print.** Keep a task's output and errors with its result, and show them in
   order. Debugging a parallel program becomes debugging a sequential one.
3. **Don't own the pool.** A library should take the executor from its caller (malebolgia's
   `Master` passed down is close to this), the way packages leave `plan()` to the user.
4. **Respect the machine's limits**: an `availableCores` in the standard library.
5. **A test suite for backends.** The futureverse has `future.tests`, which every backend must
   pass to be called compliant. That is how "any backend works" stays true.
6. **The macro.** `futurize` is a {fvLines}-line toy here; a real one would know more maps
   (`collect`, `for` loops with `||`), and a Nim cluster backend would be a fun project.
"""

# ============================================================================================ 9
nbText: """
## Questions for Henrik, next time in Paris

- futurize works on R code at run time; would you have wanted it at compile time, like a macro?
- Which backend do people actually use on HPC today: batchtools or mirai?
- Futures can be cancelled since future 1.49 (2025). Structured concurrency, malebolgia's only
  mode, is still future work in the paper: will the futures of a map always be cancelled when
  one of them fails?
- What is the strangest thing someone parallelized with futures? And has future.p2p run on a
  group of friends' laptops yet?
"""

nbFold("How the toy is built: `fv.nim`, and its limits", &"""
- **Threads**: malebolgia's `awaitAll`/`spawn`. Each of the n workers gets elements w, w+n,
  w+2n, ... (R's futures chunk elements too; `chunk_size` and `scheduling` tune it). Results go
  into a preallocated array through a pointer, so no locks.
- **Processes**: the running binary, started n times with `--fv-worker <task>`, elements as
  JSON lines over pipes (`std/json`, `std/osproc`). All elements are sent before any result is
  read, which is fine for small inputs and would deadlock on big ones.
- **Not done**: lazy futures (`future(lazy = TRUE)`), `resolved()`, cancellation, timeouts,
  remote machines, nested plans (R's `plan(list(cluster, multicore))`), warnings as a kind of
  their own, and moving exception objects. Toy, remember.
- **Where R is going next** (the [roadmap]({site}roadmap.html)): restarting futures whose
  worker died, resource declarations (memory, run time, GPUs) so a future goes only where it
  fits, `availableMemory()` and `availableTime()` in parallelly, shared memory between local
  workers. Each would make a nice Nim experiment.
- Everything on this page was run when the page was built: the timings are real, from a
  {countProcessors()}-core cloud machine.
""")

nbSource("fv.nim", tanchor = "fv-source")
nbSource("examples/tasks.nim")

nbText: &"""
---
Sources: Henrik Bengtsson, [*A Unified Approach to Concurrent, Parallel Map-Reduce in R using
Futures*]({paper}) (arXiv 2601.17578, January 2026) and [*A Unifying Framework for Parallel and
Distributed Processing in R using Futures*]({rjournal}) (The R Journal, 2021); the
[future]({futureRepo}) and [futurize]({futurizeRepo}) sources and vignettes; the
[futureverse site]({site}) (home, backends, packages, roadmap, blog) and its
[in-browser demo]({site}demo.html); the [progressify](https://github.com/futureverse/progressify) README. Nim: [malebolgia]({malebolgiaRepo}), [taskpools]({taskpoolsRepo}),
Nim 2.2.4. Page made with [nimib](https://github.com/pietroppeter/nimib), tables with
[tabelline](https://pietroppeter.github.io/tabelline/).
"""

nbSave
