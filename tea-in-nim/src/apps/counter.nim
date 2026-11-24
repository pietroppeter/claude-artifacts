## 1. A counter: Model, Msg, update, view. No effects yet.
import std/strutils
import ../tea/core

type
  Model* = object
    count*, step*: int

  Msg* = object
    case
    of Increment, Decrement, Reset: discard
    of SetStep:
      step*: int

htmlFor(Msg)

proc init*(): (Model, Cmd[Msg]) = (Model(count: 0, step: 1), none())

proc update*(msg: Msg, model: Model): (Model, Cmd[Msg]) =
  var m = model
  case msg
  of Increment: m.count += m.step
  of Decrement: m.count -= m.step
  of Reset: m.count = 0
  of SetStep(s): m.step = s
  (m, none())

proc parseStep(s: string): Msg =
  try: SetStep(step: parseInt(s))
  except ValueError: SetStep(step: 1)

proc view*(m: Model): Html[Msg] =
  el("div", [cls "app"],
    el("p", [cls "big"], text $m.count),
    el("div", [cls "row"],
      el("button", [onClick Decrement()], text "−" & $m.step),
      el("button", [onClick Increment()], text "+" & $m.step),
      el("button", [onClick Reset()], text "reset")),
    el("label", [cls "row"], text "step ",
      el("input", [prop("type", "number"), prop("value", $m.step),
        onInput(parseStep)])))

proc subscriptions*(m: Model): seq[Sub[Msg]] = @[]

let program* = Program[Model, Msg](init: init, update: update, view: view,
  subscriptions: subscriptions)
