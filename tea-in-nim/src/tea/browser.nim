## The runtime: the only impure part. It keeps the model, turns events into messages, runs
## update, patches the DOM, performs the commands and starts and stops the subscriptions.
import std/[dom, random, tables, sequtils]
import core
export core

proc dateNow(): float {.importjs: "Date.now()".}
proc setProp(n: Node, k: cstring, v: cstring) {.importjs: "#[#] = #".}
proc getProp(n: Node, k: cstring): cstring {.importjs: "#[#]".}
proc setHandler(n: Node, k: cstring, f: proc (ev: Event)) {.importjs: "#[#] = #".}
proc clearHandler(n: Node, k: cstring) {.importjs: "#[#] = null".}

type Runtime[Model, M] = ref object
  program: Program[Model, M]
  model: Model
  root: Element
  dom: Node                       # what is on screen
  vdom: Html[M]                   # the Html it came from
  subs: Table[int, Interval]      # running subscriptions, by period
  ticks: Table[int, Sub[M]]       # the latest Sub for each period
  log: Element
  count: int

proc dispatch[Model, M](rt: Runtime[Model, M], msg: M)

proc setAttrs[Model, M](rt: Runtime[Model, M], n: Node, attrs: seq[Attr[M]]) =
  let e = Element(n)
  n.clearHandler("onclick")
  n.clearHandler("oninput")
  for a in attrs:
    case a
    of Prop(k, v):
      if k == "value":
        if $n.getProp("value") != v: n.setProp("value", v.cstring)
      elif e.getAttribute(k.cstring) != v.cstring:
        e.setAttribute(k.cstring, v.cstring)
    of OnClick(m):
      n.setHandler("onclick", proc (ev: Event) = rt.dispatch(m))
    of OnInput(f):
      let toMsg = f
      n.setHandler("oninput", proc (ev: Event) = rt.dispatch(toMsg($n.getProp("value"))))

proc create[Model, M](rt: Runtime[Model, M], h: Html[M]): Node =
  case h
  of Text(s): document.createTextNode(s.cstring)
  of Elem(tag, attrs, kids):
    let n = document.createElement(tag.cstring)
    rt.setAttrs(n, attrs)
    for k in kids: n.appendChild(rt.create(k))
    n

proc sameShape[M](a, b: Html[M]): bool =
  case a
  of Text(_):
    case b
    of Text(_): true
    of Elem(_, _, _): false
  of Elem(t1, _, _):
    case b
    of Text(_): false
    of Elem(t2, _, _): t1 == t2

proc patch[Model, M](rt: Runtime[Model, M], n: Node, old, new: Html[M]): Node =
  ## Change the DOM node `n` (drawn from `old`) so it shows `new`. Returns the node now there.
  if not sameShape(old, new):
    let fresh = rt.create(new)
    n.parentNode.replaceChild(fresh, n)
    return fresh
  case new
  of Text(s):
    if $n.nodeValue != s: n.nodeValue = s.cstring
  of Elem(_, attrs, kids):
    var oldKids: seq[Html[M]]
    case old
    of Elem(_, oldAttrs, ok):
      oldKids = ok
      for a in oldAttrs:            # drop attributes that are gone
        case a
        of Prop(k, _):
          var still = false
          for b in attrs:
            case b
            of Prop(k2, _): still = still or k2 == k
            else: discard
          if not still: Element(n).removeAttribute(k.cstring)
        else: discard
    of Text(_): discard
    rt.setAttrs(n, attrs)
    var domKids: seq[Node]
    for c in n.childNodes: domKids.add c
    for i, k in kids:
      if i < oldKids.len: discard rt.patch(domKids[i], oldKids[i], k)
      else: n.appendChild(rt.create(k))
    for i in kids.len ..< oldKids.len: n.removeChild(domKids[i])
  n

proc perform[Model, M](rt: Runtime[Model, M], cmd: Cmd[M]) =
  case cmd
  of NoCmd: discard
  of Batch(cs):
    for c in cs: rt.perform(c)
  of RandomInt(lo, hi, f):
    let n = rand(lo .. hi)
    let toMsg = f        # a binding is a template: calling it needs a real proc value
    discard setTimeout(proc () = rt.dispatch(toMsg(n)), 0)
  of Now(f):
    let toMsg = f
    discard setTimeout(proc () = rt.dispatch(toMsg(dateNow())), 0)

proc syncSubs[Model, M](rt: Runtime[Model, M]) =
  ## Start what subscriptions(model) asks for and is not running, stop what it no longer asks for.
  var wanted: Table[int, Sub[M]]
  for s in rt.program.subscriptions(rt.model):
    case s
    of Every(ms, _): wanted[ms] = s
  for ms in toSeq(rt.subs.keys):
    if ms notin wanted:
      clearInterval(rt.subs[ms])
      rt.subs.del ms
  rt.ticks = wanted
  for ms in wanted.keys:
    if ms notin rt.subs:
      let period = ms
      rt.subs[ms] = setInterval(proc () =
        if period in rt.ticks:
          case rt.ticks[period]
          of Every(_, f):
            let toMsg = f
            rt.dispatch(toMsg(dateNow())),
        ms)

proc logLine[Model, M](rt: Runtime[Model, M], msg: string) =
  if rt.log == nil: return
  inc rt.count
  let li = document.createElement("li")
  li.textContent = (msg & "  →  " & $rt.model).cstring
  rt.log.insertBefore(li, rt.log.firstChild)
  while rt.log.childNodes.len > 30: rt.log.removeChild(rt.log.lastChild)
  let total = document.getElementById(($rt.root.id & "-count").cstring)
  if total != nil: total.textContent = ($rt.count & (if rt.count == 1: " message" else: " messages")).cstring

proc render[Model, M](rt: Runtime[Model, M]) =
  let next = rt.program.view(rt.model)
  rt.dom = rt.patch(rt.dom, rt.vdom, next)
  rt.vdom = next

proc dispatch[Model, M](rt: Runtime[Model, M], msg: M) =
  let (model, cmd) = rt.program.update(msg, rt.model)
  rt.model = model
  # the log under each demo
  rt.logLine($msg)
  # view, then patch the DOM where it changed
  rt.render()
  # RandomInt, Now, Batch: their results come back through dispatch
  rt.perform(cmd)
  # start and stop timers to match subscriptions(model)
  rt.syncSubs()

proc mount*[Model, M](id: string, program: Program[Model, M]) =
  ## Run `program` inside the element with this id; messages are listed in `id & "-log"`.
  randomize()
  let rt = Runtime[Model, M](program: program, root: document.getElementById(id.cstring))
  rt.log = document.getElementById((id & "-log").cstring)
  let (model, cmd) = program.init()
  rt.model = model
  rt.vdom = program.view(model)
  rt.dom = rt.create(rt.vdom)
  rt.root.appendChild(rt.dom)
  rt.logLine("init")
  rt.perform(cmd)
  rt.syncSubs()
