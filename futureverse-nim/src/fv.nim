## fv: a toy "futureverse" for Nim, to explain Henrik Bengtsson's R futureverse by building it.
##
## - `plan(sequential())`, `plan(threads(4))`, `plan(processes(4))`: the end-user picks HOW and WHERE.
## - `futureMap(xs, f)`: the developer says WHAT can run concurrently (R: future.apply / furrr).
## - `xs.map(f).futurize(seed = 42)`: a macro that rewrites a sequential map (R: futurize).
## - Inside a task: `say` (output, relayed in order), `gauss`/`dice` (random numbers, reproducible
##   per element with `seed`), exceptions (re-raised on the main thread), `progress = true`.
##
## Threads come from malebolgia (structured: every spawn is awaited inside `awaitAll`).
## Processes are copies of the running program, started with `--fv-worker <task>`: a program that
## uses `processes` must call `registerTask f` for its tasks and then `fvServe()`, before anything else.
import std/[atomics, isolation, json, locks, macros, os, osproc, random, sequtils, streams, strutils, tables]
import malebolgia
export isolation   # malebolgia's spawn needs `isolate` where futureMap is instantiated

type
  BackendKind* = enum bkSequential = "sequential", bkThreads = "threads", bkProcesses = "processes"
  Plan* = object
    kind*: BackendKind
    workers*: int
  RelayedError* = object of CatchableError
    ## An exception raised by a task whose type fv does not rebuild: its name and message.
    origName*: string
  Outcome[U] = object        ## what one element left behind
    value: U
    log: seq[string]
    errName, errMsg: string   ## an exception: only its name and message cross a thread or a process
    rngUsed: bool
  Ctx = object               ## the per-element context, one per thread
    active: bool
    log: seq[string]
    rng: Rand
    rngUsed: bool

var
  ctx {.threadvar.}: Ctx
  currentPlan = Plan(kind: bkSequential, workers: 1)
  progressLock: Lock
  progressDone: Atomic[int]
  progressTotal: int
initLock progressLock

# ------------------------------------------------------------------------------- how many cores?
proc availableCores*(): int =
  ## Like parallelly::availableCores(): the cores this program may use, not the cores the
  ## machine has. Honours `FV_AVAILABLECORES` and a Linux cgroup CPU quota (containers, CI).
  result = countProcessors()
  if existsEnv("FV_AVAILABLECORES"):
    return max(1, getEnv("FV_AVAILABLECORES").parseInt)
  try:
    let q = readFile("/sys/fs/cgroup/cpu.max").splitWhitespace
    if q.len == 2 and q[0] != "max":
      result = min(result, max(1, (q[0].parseInt + q[1].parseInt - 1) div q[1].parseInt))
  except IOError, ValueError: discard
  result = max(1, result)

# ------------------------------------------------------------------------------- the plan
proc sequential*(): Plan = Plan(kind: bkSequential, workers: 1)
proc threads*(workers = 0): Plan =
  ## Threads of this process (malebolgia's pool, at most `ThreadPoolSize` of them).
  Plan(kind: bkThreads, workers: min(if workers > 0: workers else: availableCores(), ThreadPoolSize))
proc processes*(workers = 0): Plan =
  ## Copies of this program, talking JSON over pipes (R's `multisession`, without R).
  Plan(kind: bkProcesses, workers: if workers > 0: workers else: availableCores())

proc plan*(p: Plan) = currentPlan = p
proc plan*(): Plan = currentPlan
proc `$`*(p: Plan): string =
  if p.kind == bkSequential: "sequential" else: $p.kind & "(" & $p.workers & ")"

template withPlan*(p: Plan; body: untyped) =
  ## Use a plan for a block only, then put the previous one back (R: `with(plan(...), local = TRUE)`).
  let saved = plan()
  plan(p)
  try: body
  finally: plan(saved)

# ------------------------------------------------------------------------------- inside a task
proc say*(args: varargs[string, `$`]) =
  ## Output from a task. It is captured and relayed by the main thread, in element order, as if
  ## the map ran sequentially (R relays cat(), message() and warning() the same way).
  let s = args.join("")
  if ctx.active: ctx.log.add s else: echo s

proc gauss*(): float =
  ## A standard normal random number from the element's own stream.
  ctx.rngUsed = true
  ctx.rng.gauss()

proc dice*(): int =
  ## A roll of a six-sided die, from the element's own stream.
  ctx.rngUsed = true
  ctx.rng.rand(1..6)

proc mix(seed, i: int): int64 =
  ## splitmix64 of (seed, i): one independent-looking stream per element, whatever runs it.
  var z = cast[uint64](seed) + 0x9E3779B97F4A7C15'u64 * uint64(i + 1)
  z = (z xor (z shr 30)) * 0xBF58476D1CE4E5B9'u64
  z = (z xor (z shr 27)) * 0x94D049BB133111EB'u64
  cast[int64](z xor (z shr 31))

proc runOne[T, U](f: proc(x: T): U {.nimcall, gcsafe.}; x: T; i, seed: int; o: var Outcome[U]) =
  ## Evaluate one element: set up its context, call f, keep what it left behind.
  ctx = Ctx(active: true)
  ctx.rng = if seed >= 0: initRand(mix(seed, i)) else: initRand()   # no seed: from the clock
  try:
    o.value = f(x)
  except CatchableError:
    let e = getCurrentException()
    (o.errName, o.errMsg) = ($e.name, e.msg)
  o.log = move ctx.log
  o.rngUsed = ctx.rngUsed
  ctx.active = false

proc tick() {.gcsafe.} =
  ## One more element done: draw the progress bar when a new tenth is reached.
  let done = progressDone.fetchAdd(1) + 1
  {.cast(gcsafe).}:
    let total = progressTotal
    if total > 0 and done * 10 div total != (done - 1) * 10 div total:
      withLock progressLock:
        let tenths = done * 10 div total
        echo "progress |", "█".repeat(tenths), "·".repeat(10 - tenths), "| ", done, "/", total

# ------------------------------------------------------------------------------- processes
type Entry = object
  name: string
  run: proc(x: JsonNode; i, seed: int): JsonNode {.closure.}

var registry: Table[string, Entry]
var names: Table[pointer, string]

proc registerImpl[T, U](name: string; f: proc(x: T): U {.nimcall, gcsafe.}) =
  names[cast[pointer](f)] = name
  registry[name] = Entry(name: name, run: proc(x: JsonNode; i, seed: int): JsonNode =
    var o: Outcome[U]
    runOne(f, x.to(T), i, seed, o)
    result = %*{"i": i, "log": o.log, "rng": o.rngUsed}
    if o.errName.len > 0: result["err"] = %*{"name": o.errName, "msg": o.errMsg}
    else: result["v"] = %o.value)

template registerTask*(f: typed) =
  ## Make `f` callable by worker processes (they look it up by name).
  registerImpl(astToStr(f), f)

proc fvServe*() =
  ## If this program was started as a worker (`--fv-worker <task>`), serve: read one JSON element
  ## per line on stdin, answer one JSON line on stdout, then quit. Otherwise do nothing.
  if paramCount() >= 2 and paramStr(1) == "--fv-worker":
    let e = registry[paramStr(2)]
    for line in stdin.lines:
      let j = parseJson(line)
      stdout.writeLine $e.run(j["x"], j["i"].getInt, j["seed"].getInt)
      stdout.flushFile
    quit 0

proc mapProcesses[T, U](xs: openArray[T]; f: proc(x: T): U {.nimcall, gcsafe.}; seed, workers: int;
                        progress: bool; outs: var seq[Outcome[U]]) =
  let key = cast[pointer](f)
  if key notin names:
    raise newException(ValueError, "processes need `registerTask f` and `fvServe()` at the top of the program")
  let n = min(workers, xs.len)
  var ps: seq[Process]
  for w in 0 ..< n:
    ps.add startProcess(getAppFilename(), args = ["--fv-worker", names[key]], options = {})
  for i, x in xs:     # element i goes to worker i mod n; all input is sent before any is read
    ps[i mod n].inputStream.writeLine $(%*{"i": i, "x": %x, "seed": seed})
  for p in ps: p.inputStream.close
  for p in ps:
    for line in p.outputStream.lines:
      let j = parseJson(line)
      let i = j["i"].getInt
      outs[i].log = j["log"].to(seq[string])
      outs[i].rngUsed = j["rng"].getBool
      if j.hasKey("err"):
        (outs[i].errName, outs[i].errMsg) = (j["err"]["name"].getStr, j["err"]["msg"].getStr)
      else:
        outs[i].value = j["v"].to(U)
      if progress: tick()
    discard p.waitForExit
    p.close

# ------------------------------------------------------------------------------- the map
proc relayError(name, msg: string) =
  ## Raise again, on the main thread, an exception a task raised. The object itself can't cross
  ## (under ORC a ref belongs to the thread that made it), so fv makes a new one of the same
  ## type for the common types of the standard library, and a RelayedError for the others.
  template re(T: typedesc) = raise newException(T, msg)
  case name
  of "ValueError": re ValueError
  of "KeyError": re KeyError
  of "IOError": re IOError
  of "OSError": re OSError
  of "ArithmeticError", "DivByZeroDefect": re ArithmeticError
  else:
    let e = newException(RelayedError, "[" & name & "] " & msg)
    e.origName = name
    raise e

proc runChunk[T, U](f: proc(x: T): U {.nimcall, gcsafe.}; xs: ptr UncheckedArray[T];
                    outs: ptr UncheckedArray[Outcome[U]]; lo, hi, step, seed: int; progress: bool) {.gcsafe.} =
  var i = lo
  while i < hi:
    runOne(f, xs[i], i, seed, outs[i])
    if progress: tick()
    i += step

proc futureMap*[T, U](xs: openArray[T]; f: proc(x: T): U {.nimcall, gcsafe.};
                      seed = -1; progress = false): seq[U] =
  ## `xs.map(f)`, evaluated by the current plan. Output from `say` is relayed in element order;
  ## the first exception (in element order) is raised again here; with `seed` set, the random
  ## numbers of element i depend only on (seed, i), so every plan gives the same result.
  var outs = newSeq[Outcome[U]](xs.len)
  progressDone.store(0)
  progressTotal = if progress: xs.len else: 0
  let p = plan()
  if xs.len > 0:
    case p.kind
    of bkSequential:
      runChunk(f, cast[ptr UncheckedArray[T]](unsafeAddr xs[0]), cast[ptr UncheckedArray[Outcome[U]]](addr outs[0]),
               0, xs.len, 1, seed, progress)
    of bkThreads:
      var m = createMaster()
      let px = cast[ptr UncheckedArray[T]](unsafeAddr xs[0])
      let po = cast[ptr UncheckedArray[Outcome[U]]](addr outs[0])
      m.awaitAll:
        for w in 0 ..< min(p.workers, xs.len):     # worker w takes elements w, w+n, w+2n, ...
          m.spawn runChunk(f, px, po, w, xs.len, min(p.workers, xs.len), seed, progress)
    of bkProcesses:
      mapProcesses(xs, f, seed, p.workers, progress, outs)
  progressTotal = 0
  result = newSeq[U](xs.len)
  var warned = false
  for i in 0 ..< outs.len:          # relay, in order, as if it had run sequentially
    for line in outs[i].log: echo line
    if outs[i].errName.len > 0: relayError(outs[i].errName, outs[i].errMsg)
    if outs[i].rngUsed and seed < 0 and not warned:
      echo "Warning: UNRELIABLE VALUE: element ", i + 1, " used random numbers without a seed. ",
           "Pass a seed to get the same numbers on every plan."
      warned = true
    result[i] = move outs[i].value

# ------------------------------------------------------------------------------- futurize
proc pipe(lhs, rhs: NimNode): NimNode =
  ## `lhs |> rhs`: insert lhs as the first argument of the call rhs.
  if rhs.kind in nnkCallKinds:
    result = rhs.copyNimTree
    result.insert(1, lhs)
  else:
    result = newCall(rhs, lhs)

proc rewrite(call: NimNode; opts: seq[NimNode]): NimNode =
  ## The transpiler: `map(xs, f)` and `xs.mapIt(expr)`, from std/sequtils, become `futureMap`.
  ## It unwraps `( )` and a `progressify(...)` (which becomes `progress = true`).
  var n = if call.kind in {nnkPar, nnkStmtListExpr} and call.len == 1: call[0] else: call
  var opts = opts
  if n.kind == nnkInfix and n[0].eqIdent("|>"):   # an inner pipe reaches the macro unexpanded
    n = pipe(n[1], n[2])
  if n.kind in nnkCallKinds and n.len == 2 and n[0].eqIdent("progressify"):
    n = n[1]
    opts.add nnkExprEqExpr.newTree(ident"progress", newLit(true))
  var fn, xs, arg: NimNode
  if n.kind in nnkCallKinds and n.len == 2 and n[0].kind == nnkDotExpr:   # xs.map(f)
    (fn, xs, arg) = (n[0][1], n[0][0], n[1])
  elif n.kind in nnkCallKinds and n.len == 3:                            # map(xs, f)
    (fn, xs, arg) = (n[0], n[1], n[2])
  else:
    error("futurize: expected map(xs, f) or xs.mapIt(expr), got " & n.repr, n)
  if fn.eqIdent("map"):
    result = newCall(bindSym"futureMap", xs, arg)
  elif fn.eqIdent("mapIt"):
    let it = ident"it"
    let anon = genSym(nskProc, "fvIt")
    result = quote do:
      block:
        proc `anon`(`it`: typeof(`xs`[0])): auto {.nimcall, gcsafe.} = `arg`
        futureMap(`xs`, `anon`)
    let callNode = result[1][1]
    for o in opts: callNode.add o
    return
  else:
    error("futurize: no transpiler for " & fn.repr & " (known: map, mapIt)", n)
  for o in opts: result.add o

macro futurize*(call: untyped; opts: varargs[untyped]): untyped =
  ## `xs.map(f).futurize()`, `xs.mapIt(it * it).futurize(seed = 1)`: run a sequential map with
  ## the current plan. Compile with `-d:futurizeOff` and every futurize is the plain map again.
  when defined(futurizeOff):
    result = call
  else:
    result = rewrite(call, toSeq(opts))

macro progressify*(call: untyped): untyped =
  ## `xs.map(f) |> progressify()`: the same map, with a progress bar, run sequentially (R's
  ## progressify package). Before a futurize, `|> progressify() |> futurize()`, it is unwrapped
  ## by futurize instead, and the bar comes from the workers.
  let m = rewrite(call, @[nnkExprEqExpr.newTree(ident"progress", newLit(true))])
  result = quote do:
    block:
      let saved = plan()
      plan(sequential())
      try: `m`
      finally: plan(saved)

macro transpiled*(call: untyped; opts: varargs[untyped]): string =
  ## What futurize turns `call` into, as source (R: `futurize(eval = FALSE)`).
  newLit(rewrite(call, toSeq(opts)).repr)

macro `|>`*(lhs, rhs: untyped): untyped =
  ## R's native pipe: `x |> f(y)` is `f(x, y)`. So `xs.mapIt(it * 2) |> futurize(seed = 1)` reads
  ## like the R original, and the map reaches the macro unevaluated, as R's `substitute()` sees it.
  pipe(lhs, rhs)
