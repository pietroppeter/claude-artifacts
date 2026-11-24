## 3. A stopwatch: the clock is a subscription, and it exists only while the watch runs.
import std/[strformat, math]
import ../tea/core

type
  Model* = object
    running*: bool
    # ms counted before the current run
    elapsed*: float
    # when the current run started, last tick
    since*, now*: float
    laps*: seq[float]

  Msg* = object
    case
    of Start, Stop, Lap, Reset: discard
    of Started:
      at*: float
    of Tick:
      t*: float

htmlFor(Msg)

proc init*(): (Model, Cmd[Msg]) = (Model(), none())

proc shown*(m: Model): float =
  if m.running: m.elapsed + (m.now - m.since) else: m.elapsed

proc update*(msg: Msg, model: Model): (Model, Cmd[Msg]) =
  var m = model
  case msg
  of Start:
    # update may not read the clock: it asks the runtime for the time
    return (m, Now(gotTime: proc (t: float): Msg = Started(at: t)))
  of Started(t):
    m.running = true
    m.since = t
    m.now = t
  of Tick(t): m.now = t
  of Stop:
    m.elapsed = m.shown
    m.running = false
  of Lap: m.laps.insert(m.shown, 0)
  of Reset: m = Model()
  (m, none())

proc fmtMs(ms: float): string =
  let s = ms / 1000
  &"{int(s) div 60:02}:{floorMod(s, 60.0):04.1f}"

proc view*(m: Model): Html[Msg] =
  var laps: seq[Html[Msg]]
  for i, l in m.laps: laps.add el("li", text &"lap {m.laps.len - i}: {fmtMs(l)}")
  el("div", [cls "app"],
    el("p", [cls "big"], text fmtMs(m.shown)),
    el("div", [cls "row"],
      if m.running: el("button", [onClick Stop()], text "stop")
      else: el("button", [onClick Start()], text "start"),
      el("button", [onClick Lap()], text "lap"),
      el("button", [onClick Reset()], text "reset")),
    el("ol", [cls "laps"], laps))

proc subscriptions*(m: Model): seq[Sub[Msg]] =
  if m.running: @[Every(every: 100, tick: proc (t: float): Msg = Tick(t: t))]
  else: @[]

let program* = Program[Model, Msg](init: init, update: update, view: view,
  subscriptions: subscriptions)
