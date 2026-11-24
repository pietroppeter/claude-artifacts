## 2. Dice: update cannot roll a die (that is an effect), so it returns a command.
import ../tea/core

type
  Model* = object
    # 0: not rolled yet
    face*: int
    counts*: array[1..6, int]
    # rolls asked for and not back yet
    rolling*: int

  Msg* = object
    case
    of Roll: discard
    of RollMany:
      n*: int
    of Rolled:
      value*: int

htmlFor(Msg)

proc init*(): (Model, Cmd[Msg]) = (Model(), none())

proc rollCmd(): Cmd[Msg] =
  RandomInt(lo: 1, hi: 6, gotInt: proc (n: int): Msg = Rolled(value: n))

proc update*(msg: Msg, model: Model): (Model, Cmd[Msg]) =
  var m = model
  case msg
  of Roll:
    inc m.rolling
    (m, rollCmd())
  of RollMany(n):
    m.rolling += n
    var cmds: seq[Cmd[Msg]]
    for i in 1 .. n: cmds.add rollCmd()
    (m, Batch(cmds: cmds))
  of Rolled(v):
    m.face = v
    inc m.counts[v]
    dec m.rolling
    (m, none())

const pips = ["·", "⚀", "⚁", "⚂", "⚃", "⚄", "⚅"]

proc view*(m: Model): Html[Msg] =
  var bars: seq[Html[Msg]]
  var most = 1
  for c in m.counts: most = max(most, c)
  for f in 1 .. 6:
    bars.add el("div", [cls "bar"],
      el("span", text pips[f]),
      el("span", [cls "fill", prop("style", "width:" & $(m.counts[f] * 100 div most) & "%")]),
      el("span", [cls "n"], text $m.counts[f]))
  el("div", [cls "app"],
    el("p", [cls "big"], text pips[m.face]),
    el("div", [cls "row"],
      el("button", [onClick Roll()], text "roll"),
      el("button", [onClick RollMany(n: 60)], text "roll 60")),
    el("div", [cls "bars"], bars))

proc subscriptions*(m: Model): seq[Sub[Msg]] = @[]

let program* = Program[Model, Msg](init: init, update: update, view: view,
  subscriptions: subscriptions)
