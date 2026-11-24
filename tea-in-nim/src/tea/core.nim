## The Elm Architecture, from scratch: the part that does not know about the browser.
## Every type here is a Nim 2.4 sum type, so `case` must cover every branch and a field
## can only be read in the branch that has it.
import std/strutils

type
  Attr*[M] = object
    ## what you can put on an element
    case
    of Prop:
      name*, value*: string
    of OnClick:
      ## a click sends this message
      msg*: M
    of OnInput:
      ## typing sends toMsg(the new text)
      toMsg*: proc (s: string): M

  Html*[M] = object
    ## the view returns data, not DOM
    case
    of Text:
      s*: string
    of Elem:
      tag*: string
      attrs*: seq[Attr[M]]
      kids*: seq[Html[M]]

  Cmd*[M] = object
    ## effects as data: update asks, the runtime does
    case
    of NoCmd: discard
    of Batch:
      cmds*: seq[Cmd[M]]
    of RandomInt:
      lo*, hi*: int
      ## how the result comes back
      gotInt*: proc (n: int): M
    of Now:
      gotTime*: proc (t: float): M

  Sub*[M] = object
    ## what the program wants to listen to, given its model
    case
    of Every:
      every*: int
      tick*: proc (t: float): M

  Program*[Model, M] = object
    init*: proc (): (Model, Cmd[M])
    update*: proc (msg: M, model: Model): (Model, Cmd[M])
    view*: proc (model: Model): Html[M]
    subscriptions*: proc (model: Model): seq[Sub[M]]

template htmlFor*(M: typedesc) =
  ## Nim cannot infer `M` of `Html[M]` from the expected type of a generic proc, so the
  ## helpers are stamped out for the program's own message type.
  proc text(s: string): Html[M] {.used.} = Text(s: s)
  proc el(tag: string, attrs: openArray[Attr[M]], kids: varargs[Html[M]]): Html[M] {.used.} =
    Elem(tag: tag, attrs: @attrs, kids: @kids)
  proc el(tag: string, kids: varargs[Html[M]]): Html[M] {.used.} =
    Elem(tag: tag, attrs: @[], kids: @kids)
  proc cls(c: string): Attr[M] {.used.} = Prop(name: "class", value: c)
  proc prop(n, v: string): Attr[M] {.used.} = Prop(name: n, value: v)
  proc onClick(m: M): Attr[M] {.used.} = OnClick(msg: m)
  proc onInput(f: proc (s: string): M): Attr[M] {.used.} = OnInput(toMsg: f)
  # no effect
  proc none(): Cmd[M] {.used.} = NoCmd()

func esc(s: string): string =
  s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))

proc render*[M](h: Html[M]): string =
  ## The same view, as an HTML string: handy to look at it outside a browser.
  case h
  of Text(s): esc(s)
  of Elem(tag, attrs, kids):
    var r = "<" & tag
    for a in attrs:
      case a
      of Prop(n, v): r.add " " & n & "=\"" & esc(v) & "\""
      of OnClick(m): r.add " onclick=\"" & esc($m) & "\""
      of OnInput(_): r.add " oninput=\"…\""
    r.add ">"
    for k in kids: r.add render(k)
    r & "</" & tag & ">"

proc `$`*[M](c: Cmd[M]): string =
  case c
  of NoCmd: "NoCmd()"
  of Batch(cs): "Batch(" & $cs.len & " cmds)"
  of RandomInt(lo, hi, _): "RandomInt(lo: " & $lo & ", hi: " & $hi & ", gotInt: …)"
  of Now(_): "Now(gotTime: …)"
