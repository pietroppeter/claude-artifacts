## faretto's VM: a tree-walking interpreter over the semchecked NIF that
## Nimony writes (`.s.nif`), plus the things that make Pharo feel alive:
## an image (procs + objects that outlive a run), late binding (a call
## looks its proc up when it runs, so a redefinition is seen at once),
## an object table (so `become` is one swap), MetaLinks on any node,
## a stack you can look at (thisContext), and a halt/restart debugger.
## No `os`, no `osproc`: this module also compiles to JavaScript.
import std/[tables, strutils]
import nif
export tables, nif

type
  ValKind* = enum vNil, vInt, vBool, vStr, vChar, vFloat, vRef, vLoc
  LocKind = enum lkVar, lkField
  Loc* = ref object
    case kind: LocKind
    of lkVar:
      frame: Frame
      name: string
    of lkField:
      oop: int
      field: string
  Value* = object
    case kind*: ValKind
    of vNil: discard
    of vInt: i*: int64
    of vBool: b*: bool
    of vStr: s*: string
    of vChar: c*: char
    of vFloat: f*: float
    of vRef: oop*: int          ## an index into the object table
    of vLoc: loc*: Loc          ## an address (Nimony's `haddr`)

  Obj* = ref object             ## an object in the heap
    typ*: string
    fields*: OrderedTable[string, Value]

  FieldDef* = object
    name*: string
    typ*: Node

  ProcDef* = ref object         ## one entry of the "method dictionary"
    sym*, name*: string
    params*: seq[string]        ## parameter symbols
    body*: Node                 ## the proc's whole NIF tree
    source*: string             ## its Nim source, as the programmer wrote it
    version*: int

  Change* = object              ## one line of the change log (Pharo's .changes file)
    what*, source*: string

  Image* = ref object
    procs*: OrderedTable[string, ProcDef]           ## by symbol, e.g. "tick.0."
    types*: OrderedTable[string, seq[FieldDef]]     ## "Beacon" -> its fields
    globals*: OrderedTable[string, Value]           ## by symbol, e.g. "capo.0."
    heap*: seq[Obj]                                 ## the object table; oop 0 is unused
    changes*: seq[Change]
    source*: string                                 ## the module's current source text

  Frame* = ref object           ## a "context" in Pharo: one activation of a proc
    procSym*: string
    vars*: OrderedTable[string, Value]
    node*: Node                 ## where it is now
    depth*: int

  Control* = enum ckNone, ckReturn, ckJump, ckContinue

  LinkControl* = enum before, after, instead
  MetaLink* = ref object of RootObj
    ## Denker's MetaLink: "when this node runs, also call that".
    name*: string
    control*: LinkControl
    action*: proc (vm: VM; n: Node; f: Frame): Value
    condition*: proc (vm: VM; n: Node; f: Frame): bool
    hits*: int

  HaltAction* = enum proceed, restart
  VM* = ref object
    img*: Image
    stack*: seq[Frame]
    ctrl: Control
    label: string
    retVal: Value
    output*: string             ## what the program wrote to stdout
    onHalt*: proc (vm: VM; f: Frame): HaltAction
    steps*: int                 ## nodes evaluated (for the curious)

  VMError* = object of CatchableError
  RestartFrame = object of CatchableError
    depth: int

# ------------------------------------------------------------------ values
proc nilV*(): Value = Value(kind: vNil)
proc intV*(i: int64): Value = Value(kind: vInt, i: i)
proc boolV*(b: bool): Value = Value(kind: vBool, b: b)
proc strV*(s: string): Value = Value(kind: vStr, s: s)
proc refV*(oop: int): Value = Value(kind: vRef, oop: oop)

proc `$`*(v: Value): string =
  case v.kind
  of vNil: "nil"
  of vInt: $v.i
  of vBool: $v.b
  of vStr: "\"" & v.s & "\""
  of vChar: "'" & $v.c & "'"
  of vFloat: $v.f
  of vRef: "#" & $v.oop
  of vLoc: "addr"

proc vmError(msg: string) {.noreturn.} = raise newException(VMError, msg)

# ------------------------------------------------------------------ image
proc newImage*(): Image =
  Image(heap: @[nil])

proc alloc*(img: Image; typ: string): int =
  img.heap.add Obj(typ: typ)
  img.heap.high

proc obj*(img: Image; v: Value): Obj =
  if v.kind != vRef or v.oop <= 0: vmError("not an object: " & $v)
  img.heap[v.oop]

proc become*(img: Image; a, b: Value) =
  ## Pharo's `a become: b`: every reference to a now sees b, and the other
  ## way round. With an object table (as in Smalltalk-80) it is one swap.
  swap img.heap[a.oop], img.heap[b.oop]

proc becomeForward*(img: Image; a, b: Value) =
  ## `a becomeForward: b`: references to a now see b, and a is gone. In this toy b must be
  ## a fresh object that nothing else refers to yet (its slot in the table is freed).
  img.heap[a.oop] = img.heap[b.oop]
  img.heap[b.oop] = nil

proc typeName(t: Node): string =
  ## (ref Lamp.Obj.0. ...) or Lamp.0. -> "Lamp"
  if t.kind == nkTree and t.len > 0: typeName(t[0])
  elif t.kind == nkSym: baseName(t.text).replace(".Obj", "")
  else: t.text

proc defaultFor*(img: Image; t: Node): Value =
  if t.kind == nkTree:
    case t.text
    of "i", "u": intV(0)
    of "bool": boolV(false)
    of "f": Value(kind: vFloat, f: 0.0)
    of "c": Value(kind: vChar, c: '\0')
    else: nilV()
  elif t.kind == nkSym:
    case baseName(t.text)
    of "string": strV("")
    of "int", "int64": intV(0)
    of "bool": boolV(false)
    of "float", "float64": Value(kind: vFloat, f: 0.0)
    of "char": Value(kind: vChar, c: '\0')
    else: nilV()
  else: nilV()

# ------------------------------------------------------------------ frames, locations
proc frame*(vm: VM): Frame = vm.stack[^1]

proc lookupVar(vm: VM; sym: string): Loc =
  if vm.stack.len > 0 and sym in vm.frame.vars: return Loc(kind: lkVar, frame: vm.frame, name: sym)
  if sym in vm.img.globals: return Loc(kind: lkVar, frame: nil, name: sym)
  vmError("unknown variable " & baseName(sym))

proc load*(vm: VM; l: Loc): Value =
  case l.kind
  of lkVar:
    if l.frame == nil: vm.img.globals[l.name] else: l.frame.vars[l.name]
  of lkField:
    vm.img.heap[l.oop].fields.getOrDefault(l.field)

proc store*(vm: VM; l: Loc; v: Value) =
  case l.kind
  of lkVar:
    if l.frame == nil: vm.img.globals[l.name] = v else: l.frame.vars[l.name] = v
  of lkField:
    vm.img.heap[l.oop].fields[l.field] = v

# ------------------------------------------------------------------ the interpreter
proc eval*(vm: VM; n: Node): Value
proc exec*(vm: VM; n: Node)
proc callProc*(vm: VM; sym: string; args: seq[Value]): Value

proc lvalue(vm: VM; n: Node): Loc =
  case n.kind
  of nkSym: vm.lookupVar(n.text)
  of nkTree:
    case n.text
    of "ddot", "dot":
      let o = vm.eval(n[0])
      if o.kind != vRef: vmError("field access on nil: " & baseName(n[1].text))
      Loc(kind: lkField, oop: o.oop, field: n[1].base)
    of "hderef", "deref":
      let v = vm.eval(n[0])
      if v.kind == vLoc: v.loc else: vm.lvalue(n[0])
    of "haddr", "addr": vm.lvalue(n[0])
    else: vmError("cannot assign to (" & n.text & " ...)")
  else: vmError("cannot assign to " & $n.kind)

proc truthy(v: Value): bool =
  if v.kind != vBool: vmError("expected a bool, got " & $v)
  v.b

proc arith(op: string; a, b: Value): Value =
  if a.kind == vFloat or b.kind == vFloat:
    let x = (if a.kind == vFloat: a.f else: a.i.float)
    let y = (if b.kind == vFloat: b.f else: b.i.float)
    case op
    of "add": Value(kind: vFloat, f: x + y)
    of "sub": Value(kind: vFloat, f: x - y)
    of "mul": Value(kind: vFloat, f: x * y)
    of "div": Value(kind: vFloat, f: x / y)
    of "lt": boolV(x < y)
    of "le": boolV(x <= y)
    of "eq": boolV(x == y)
    else: vmError("float op " & op)
  elif a.kind == vInt and b.kind == vInt:
    case op
    of "add": intV(a.i + b.i)
    of "sub": intV(a.i - b.i)
    of "mul": intV(a.i * b.i)
    of "div":
      if b.i == 0: vmError("division by zero")
      intV(a.i div b.i)
    of "mod":
      if b.i == 0: vmError("division by zero")
      intV(a.i mod b.i)
    of "lt": boolV(a.i < b.i)
    of "le": boolV(a.i <= b.i)
    of "eq": boolV(a.i == b.i)
    of "shl": intV(a.i shl b.i)
    of "shr": intV(a.i shr b.i)
    of "bitand": intV(a.i and b.i)
    of "bitor": intV(a.i or b.i)
    of "bitxor": intV(a.i xor b.i)
    else: vmError("int op " & op)
  else:
    case op
    of "eq":
      if a.kind != b.kind: boolV(false)
      else:
        case a.kind
        of vBool: boolV(a.b == b.b)
        of vStr: boolV(a.s == b.s)
        of vChar: boolV(a.c == b.c)
        of vRef: boolV(a.oop == b.oop)
        of vNil: boolV(true)
        else: boolV(false)
    of "lt":
      if a.kind == vChar: boolV(a.c < b.c) else: boolV(a.s < b.s)
    of "le":
      if a.kind == vChar: boolV(a.c <= b.c) else: boolV(a.s <= b.s)
    else: vmError("op " & op & " on " & $a.kind)

proc toStr(vm: VM; v: Value): string =
  case v.kind
  of vStr: v.s
  of vChar: $v.c
  of vInt: $v.i
  of vBool: $v.b
  of vFloat: $v.f
  of vNil: "nil"
  of vRef: vm.img.heap[v.oop].typ & "#" & $v.oop
  of vLoc: "addr"

proc primitive(vm: VM; name: string; n: Node; args: seq[Value]): Value =
  ## Procs that live in Nimony's system/syncio modules are not in the image:
  ## the VM implements them, like Pharo's <primitive: 60> methods.
  case name
  of "write": vm.output.add vm.toStr(args[^1]); nilV()
  of "&":
    strV(vm.toStr(args[0]) & vm.toStr(args[1]))
  of "$": strV(vm.toStr(args[0]))
  of "len":
    let v = (if args[0].kind == vLoc: vm.load(args[0].loc) else: args[0])
    intV(vm.toStr(v).len)
  of "newStringOfCap": strV("")
  of "add":
    let l = args[0].loc
    let piece = vm.toStr(args[1])
    template app(v: var Value) =
      if v.kind == vStr: v.s.add piece
      else: v = strV(vm.toStr(v) & piece)
    case l.kind
    of lkVar:
      if l.frame == nil: app(vm.img.globals[l.name]) else: app(l.frame.vars[l.name])
    of lkField: app(vm.img.heap[l.oop].fields[l.field])
    nilV()
  of "==": arith("eq", args[0], args[1])
  of "<": arith("lt", args[0], args[1])
  of "<=": arith("le", args[0], args[1])
  of "repeat":
    strV(vm.toStr(args[0]).repeat(args[1].i))
  of "toUpperAscii": strV(vm.toStr(args[0]).toUpperAscii)
  of "substr":
    let s = vm.toStr(args[0])
    strV(s[args[1].i .. min(args[2].i, s.high)])
  else:
    if name.startsWith("="): nilV()   # ARC hooks: the VM's heap is Nim's own
    else: vmError("doesNotUnderstand: " & name & " (no proc in the image, no primitive)")

proc runLinks(vm: VM; n: Node; ctl: LinkControl): bool =
  ## Runs the links of `n` with the given control; true if one was `instead`.
  for l in n.links:
    let ml = MetaLink(l)
    if ml.control == ctl and (ml.condition == nil or ml.condition(vm, n, vm.frame)):
      inc ml.hits
      if ml.action != nil: discard ml.action(vm, n, vm.frame)
      if ctl == instead: result = true

proc callNode(vm: VM; n: Node): Value =
  let callee = n[0].text
  var args: seq[Value]
  for i in 1 ..< n.len: args.add vm.eval(n[i])
  if callee in vm.img.procs:
    if vm.onHalt != nil and n[0].base == "halt":
      let f = vm.frame
      f.node = n
      case vm.onHalt(vm, f)
      of proceed: return nilV()
      of restart: raise (ref RestartFrame)(msg: "restart", depth: f.depth)
    vm.callProc(callee, args)
  else:
    vm.primitive(n[0].base, n, args)

proc evalInner(vm: VM; n: Node): Value =
  inc vm.steps
  case n.kind
  of nkInt: intV(n.intVal)
  of nkStr: strV(n.text)
  of nkChar: Value(kind: vChar, c: (if n.text.len > 0: n.text[0] else: '\0'))
  of nkFloat: Value(kind: vFloat, f: n.floatVal)
  of nkSym:
    if n.base in ["stdout", "stderr"]: strV(n.base)  # syncio's files
    else: vm.load(vm.lookupVar(n.text))
  of nkEmpty: nilV()
  of nkIdent, nkSymDef: vmError("unexpected " & n.text)
  of nkTree:
    case n.text
    of "true": boolV(true)
    of "false": boolV(false)
    of "nil": nilV()
    of "add", "sub", "mul", "div", "mod", "lt", "le", "eq", "shl", "shr",
       "bitand", "bitor", "bitxor":
      arith(n.text, vm.eval(n[1]), vm.eval(n[2]))
    of "neg":
      let v = vm.eval(n[1])
      if v.kind == vFloat: Value(kind: vFloat, f: -v.f) else: intV(-v.i)
    of "not": boolV(not truthy(vm.eval(n[0])))
    of "and": boolV(truthy(vm.eval(n[0])) and truthy(vm.eval(n[1])))
    of "or": boolV(truthy(vm.eval(n[0])) or truthy(vm.eval(n[1])))
    of "ddot", "dot", "hderef", "deref":
      let v = (if n.text in ["hderef", "deref"]: vm.eval(n[0]) else: nilV())
      if v.kind == vRef: v
      else: vm.load(vm.lvalue(n))
    of "haddr", "addr": Value(kind: vLoc, loc: vm.lvalue(n[0]))
    of "call", "cmd", "infix", "prefix": vm.callNode(n)
    of "conv", "hconv", "cast":
      let v = vm.eval(n[1])
      let t = n[0]
      if t.isTag("f") and v.kind == vInt: Value(kind: vFloat, f: v.i.float)
      elif t.isTag("i") and v.kind == vFloat: intV(v.f.int64)
      elif t.isTag("i") and v.kind == vChar: intV(ord(v.c))
      elif t.isTag("c") and v.kind == vInt: Value(kind: vChar, c: chr(v.i))
      else: v
    of "newobj":
      let typ = typeName(n[0])
      let oop = vm.img.alloc(typ)
      for f in vm.img.types.getOrDefault(typ):
        vm.img.heap[oop].fields[f.name] = vm.img.defaultFor(f.typ)
      for i in 1 ..< n.len:
        let kv = n[i]
        vm.img.heap[oop].fields[baseName(kv[0].text)] = vm.eval(kv[1])
      refV(oop)
    of "expr":
      for i in 0 ..< n.len - 1: vm.exec(n[i])
      vm.eval(n[^1])
    of "suf": vm.eval(n[0])
    of "par": vm.eval(n[0])
    else: vmError("faretto cannot evaluate (" & n.text & " ...) yet")

proc eval*(vm: VM; n: Node): Value =
  if n.links.len > 0:
    discard vm.runLinks(n, before)
    if vm.runLinks(n, instead): return nilV()
    result = vm.evalInner(n)
    discard vm.runLinks(n, after)
  else:
    result = vm.evalInner(n)

proc declare(vm: VM; n: Node) =
  ## (var :x . . T init), (let ...), (result :r . . T .)
  let sym = n[0].text
  let v = if n.len > 4 and n[4].kind != nkEmpty: vm.eval(n[4]) else: vm.img.defaultFor(n[3])
  vm.frame.vars[sym] = v

proc execBlock(vm: VM; n: Node) =
  var i = 0
  while i < n.len:
    vm.exec(n[i])
    case vm.ctrl
    of ckNone: inc i
    of ckJump:
      var j = i + 1
      while j < n.len and not (n[j].isTag("lab") and n[j][0].text == vm.label): inc j
      if j < n.len:
        vm.ctrl = ckNone
        i = j + 1
      else: return
    else: return

proc execInner(vm: VM; n: Node) =
  if vm.stack.len > 0: vm.frame.node = n
  case n.kind
  of nkTree:
    case n.text
    of "stmts", "scope": vm.execBlock(n)
    of "var", "let", "cursor", "result", "const", "gvar", "glet", "tvar": vm.declare(n)
    of "asgn": vm.store(vm.lvalue(n[0]), vm.eval(n[1]))
    of "inc", "dec":
      let l = vm.lvalue(n[1])
      let d = if n.len > 2: vm.eval(n[2]).i else: 1
      let cur = vm.load(l)
      vm.store(l, intV(if n.text == "inc": cur.i + d else: cur.i - d))
    of "ite", "if":
      if truthy(vm.eval(n[0])): vm.exec(n[1])
      elif n.len > 2 and n[2].kind != nkEmpty: vm.exec(n[2])
    of "loop":
      while true:
        vm.exec(n[0])
        if vm.ctrl == ckContinue: vm.ctrl = ckNone
        elif vm.ctrl != ckNone: return
    of "while":
      while truthy(vm.eval(n[0])):
        vm.exec(n[1])
        if vm.ctrl == ckContinue: vm.ctrl = ckNone
        elif vm.ctrl != ckNone: return
    of "for":
      # only `for i in a ..< b` and `for i in a .. b`: the iterator is inlined here
      let it = n[0]
      let op = baseName(it[0].text)
      if op notin ["..<", ".."]: vmError("faretto only runs for loops over ranges, not " & op)
      let lo = vm.eval(it[1]).i
      let hi = vm.eval(it[2]).i - (if op == "..<": 1 else: 0)
      let v = n[1][0][0].text
      var i = lo
      while i <= hi:
        vm.frame.vars[v] = intV(i)
        vm.exec(n[2])
        if vm.ctrl == ckContinue: vm.ctrl = ckNone
        elif vm.ctrl != ckNone: return
        inc i
    of "ret":
      vm.retVal = if n[0].kind == nkEmpty: nilV() else: vm.eval(n[0])
      vm.ctrl = ckReturn
    of "jmp": vm.ctrl = ckJump; vm.label = n[0].text
    of "continue": vm.ctrl = ckContinue
    of "brk", "break": vm.ctrl = ckJump; vm.label = ""
    of "lab", "assume", "assert", "comment", "pragmas", "type", "proc", "func",
       "iterator", "template", "import", "emit", "discard" :
      if n.text == "discard" and n[0].kind != nkEmpty: discard vm.eval(n[0])
    else: discard vm.eval(n)
  else: discard vm.eval(n)

proc exec*(vm: VM; n: Node) =
  if n.links.len > 0:
    discard vm.runLinks(n, before)
    if vm.runLinks(n, instead): return
    vm.execInner(n)
    discard vm.runLinks(n, after)
  else:
    vm.execInner(n)

proc procBodyIndex*(p: Node): int = p.len - 1

proc callProc*(vm: VM; sym: string; args: seq[Value]): Value =
  ## Late binding: the proc is looked up by name every time it is called,
  ## so a proc redefined a moment ago runs its new body on the next call.
  while true:
    let p = vm.img.procs.getOrDefault(sym)
    if p == nil: vmError("doesNotUnderstand: " & baseName(sym))
    let f = Frame(procSym: sym, depth: vm.stack.len)
    for i, a in args:
      if i < p.params.len: f.vars[p.params[i]] = a
    vm.stack.add f
    try:
      vm.exec(p.body[p.body.procBodyIndex])
      result = if vm.ctrl == ckReturn: vm.retVal else: f.vars.getOrDefault("result")
      vm.ctrl = ckNone
      discard vm.stack.pop
      return
    except RestartFrame as e:
      # the debugger's "Restart": drop this activation and run it again,
      # with the same arguments, and with whatever body the proc has now
      vm.stack.setLen f.depth
      vm.ctrl = ckNone
      if e.depth != f.depth: raise
    except VMError:
      vm.stack.setLen f.depth
      raise

proc call*(vm: VM; name: string; args: varargs[Value]): Value =
  ## Calls a proc of the image by its plain name ("tick").
  for sym, p in vm.img.procs:
    if p.name == name: return vm.callProc(sym, @args)
  vmError("doesNotUnderstand: " & name)

proc global*(vm: VM; name: string): Value =
  for sym, v in vm.img.globals:
    if baseName(sym) == name: return v
  vmError("no global " & name)

proc newVM*(img: Image): VM =
  VM(img: img, stack: @[Frame(procSym: "(image)", depth: 0)])

# ------------------------------------------------------------------ loading NIF into the image
proc paramsOf(p: Node): seq[string] =
  for k in p.kids:
    if k.isTag("params"):
      for prm in k.kids: result.add prm[0].text
      return

proc procSource(src: string; line: int; nextLine: int): string =
  let lines = src.splitLines
  var hi = min(nextLine - 1, lines.len) - 1
  while hi >= line and lines[hi].strip == "": dec hi
  lines[line - 1 .. hi].join("\n")

proc canonical*(n: Node): string =
  ## A proc's NIF with its local symbols renumbered in order of appearance.
  ## Nimony numbers locals per module (`result.3`), so a change in one proc
  ## renumbers the next ones; this is what "did this proc change?" compares.
  var names: Table[string, string]
  proc rec(x: Node): Node =
    if x.kind in {nkSym, nkSymDef} and x.text.count('.') == 1:
      if x.text notin names: names[x.text] = baseName(x.text) & "." & $names.len
      Node(kind: x.kind, text: names[x.text])
    elif x.kind == nkTree:
      var t = Node(kind: nkTree, text: x.text)
      for k in x.kids: t.kids.add rec(k)
      t
    else: x
  rec(n).toNif

proc sameFields(a, b: seq[FieldDef]): bool =
  if a.len != b.len: return false
  for i in 0 ..< a.len:
    if a[i].name != b[i].name or a[i].typ.toNif != b[i].typ.toNif: return false
  true

type LoadReport* = object
  added*, changed*, reshaped*: seq[string]

proc loadModule*(vm: VM; module: Node; source: string; runMain = false): LoadReport =
  ## Puts the types, procs and globals of a `.s.nif` module into the image.
  ## Globals that already live in the image keep their value (nothing is
  ## re-run); a proc whose tree changed gets a new version.
  let img = vm.img
  img.source = source
  var tops: seq[int]
  let own = module.file    # nodes from other files (system, generic instances) have their own
  for k in module.kids:
    if k.kind == nkTree and k.line > 0 and k.file == own: tops.add k.line
  for k in module.kids:
    if k.kind != nkTree: continue
    case k.text
    of "type":
      let name = baseName(k[0].text).replace(".Obj", "")
      var body = k[^1]
      if body.isTag("object"):
        var fields: seq[FieldDef]
        for f in body.kids:
          if f.isTag("fld"): fields.add FieldDef(name: baseName(f[0].text), typ: f[3])
        let old = img.types.getOrDefault(name)
        img.types[name] = fields
        if old.len > 0 and not sameFields(old, fields):
          result.reshaped.add name
          # instance mutation, as Pharo's class builder does it: make a new
          # object of the new shape for each old one, then becomeForward
          for oop in 1 ..< img.heap.len:
            let o = img.heap[oop]
            if o == nil: continue
            if o != nil and o.typ == name:
              let fresh = img.alloc(name)
              for f in fields:
                img.heap[fresh].fields[f.name] = o.fields.getOrDefault(f.name, img.defaultFor(f.typ))
              img.becomeForward(refV(oop), refV(fresh))
    of "proc", "func":
      let sym = k[0].text
      let name = baseName(sym)
      if name.startsWith("="): continue
      var nextLine = int.high
      for t in tops:
        if t > k.line and t < nextLine: nextLine = t
      let src = if k.file == own: procSource(source, k.line, nextLine) else: "(generic instance from " & k.file & ")"
      let old = img.procs.getOrDefault(sym)
      if old == nil:
        img.procs[sym] = ProcDef(sym: sym, name: name, params: paramsOf(k), body: k, source: src, version: 1)
        result.added.add name
      elif canonical(old.body) != canonical(k):
        img.procs[sym] = ProcDef(sym: sym, name: name, params: paramsOf(k), body: k, source: src,
                                 version: old.version + 1)
        result.changed.add name
        img.changes.add Change(what: "accepted " & name & " v" & $(old.version + 1), source: src)
      else:
        old.source = src
    of "gvar", "glet":
      let sym = k[0].text
      if sym notin img.globals:
        img.globals[sym] = if k.len > 4 and k[4].kind != nkEmpty: vm.eval(k[4]) else: img.defaultFor(k[3])
    else: discard
  if runMain:
    for k in module.kids:
      if k.isTag("stmts"): vm.exec(k)

# ------------------------------------------------------------------ the inspector
proc inspect*(vm: VM; v: Value; indent = 0; seen: seq[int] = @[]): string =
  ## A text inspector: an object, its identity, its fields, recursively.
  if v.kind != vRef: return $v
  let o = vm.img.heap[v.oop]
  result = o.typ & " #" & $v.oop
  if v.oop in seen: return result & " (seen)"
  for k, f in o.fields:
    result.add "\n" & spaces(indent + 2) & k & ": " & vm.inspect(f, indent + 2, seen & v.oop)

proc thisContext*(vm: VM): string =
  ## The stack, innermost first, the way Pharo's debugger lists it.
  for i in countdown(vm.stack.high, 1):
    let f = vm.stack[i]
    let p = vm.img.procs.getOrDefault(f.procSym)
    result.add baseName(f.procSym)
    if p != nil: result.add " v" & $p.version
    if f.node != nil: result.add "  line " & $f.node.line
    var vs: seq[string]
    for k, v in f.vars:
      if not k.startsWith("`"): vs.add baseName(k) & "=" & $v
    if vs.len > 0: result.add "  (" & vs.join(", ") & ")"
    result.add "\n"

# ------------------------------------------------------------------ MetaLinks
proc install*(n: Node; link: MetaLink) = n.links.add link
proc uninstall*(n: Node; link: MetaLink) =
  var i = 0
  while i < n.links.len:
    if n.links[i] == link: n.links.delete i else: inc i

iterator walk*(n: Node): Node =
  var stack = @[n]
  while stack.len > 0:
    let x = stack.pop
    yield x
    for i in countdown(x.kids.high, 0): stack.add x.kids[i]

proc procNode*(vm: VM; name: string): Node =
  for sym, p in vm.img.procs:
    if p.name == name: return p.body
  vmError("no proc " & name)

proc bodyOf*(vm: VM; name: string): Node =
  let p = vm.procNode(name)
  p[p.procBodyIndex]

proc nodesAtLine*(vm: VM; name: string; line: int): seq[Node] =
  ## The statements of proc `name` that start on source line `line`.
  for x in walk(vm.bodyOf(name)):
    if x.kind == nkTree and x.line == line and
       x.text in ["asgn", "inc", "dec", "let", "var", "ite", "call", "cmd", "infix", "ret"]:
      result.add x

proc assignmentsTo*(vm: VM; field: string): seq[Node] =
  ## Every node, in every proc, that writes `field`: a watchpoint's targets.
  for sym, p in vm.img.procs:
    for x in walk(p.body):
      if x.kind == nkTree and x.text in ["asgn", "inc", "dec"]:
        let target = if x.text == "asgn": x[0] else: x[1]
        var t = target
        if t.isTag("haddr"): t = t[0]
        if t.kind == nkTree and t.text in ["ddot", "dot"] and baseName(t[1].text) == field:
          result.add x
      elif x.isTag("infix") and x.len > 1 and x[1].isTag("haddr"):
        let t = x[1][0]
        if t.kind == nkTree and t.text in ["ddot", "dot"] and baseName(t[1].text) == field:
          result.add x

# ------------------------------------------------------------------ the image file (NIF too)
proc valueNif(v: Value): Node =
  case v.kind
  of vNil: tree("nil")
  of vInt: intLit(v.i)
  of vBool: tree(if v.b: "true" else: "false")
  of vStr: str(v.s)
  of vChar: Node(kind: nkChar, text: $v.c)
  of vFloat: Node(kind: nkFloat, floatVal: v.f)
  of vRef: tree("oop", intLit(v.oop))
  of vLoc: tree("nil")

proc nifValue(n: Node): Value =
  case n.kind
  of nkInt: intV(n.intVal)
  of nkStr: strV(n.text)
  of nkChar: Value(kind: vChar, c: n.text[0])
  of nkFloat: Value(kind: vFloat, f: n.floatVal)
  else:
    case n.text
    of "true": boolV(true)
    of "false": boolV(false)
    of "oop": refV(n[0].intVal.int)
    else: nilV()

proc saveImage*(img: Image): string =
  ## The whole image as one NIF file: the procs as Nimony wrote them, the
  ## object table, the globals, the change log and the source.
  var root = tree("image", tree("format", str("faretto"), intLit(1)))
  var types = tree("types")
  for name, fs in img.types:
    var t = tree("type", ident(name))
    for f in fs: t.kids.add tree("fld", ident(f.name), f.typ)
    types.kids.add t
  root.kids.add types
  var procs = tree("procs")
  for sym, p in img.procs:
    procs.kids.add tree("method", intLit(p.version), str(p.source), p.body)
  root.kids.add procs
  var heap = tree("heap")
  for oop in 1 ..< img.heap.len:
    let o = img.heap[oop]
    if o == nil: continue
    var on = tree("obj", intLit(oop), ident(o.typ))
    for k, v in o.fields: on.kids.add tree("kv", ident(k), valueNif(v))
    heap.kids.add on
  root.kids.add heap
  var globals = tree("globals")
  for sym, v in img.globals:
    globals.kids.add tree("kv", Node(kind: nkSym, text: sym), valueNif(v))
  root.kids.add globals
  var changes = tree("changes")
  for c in img.changes: changes.kids.add tree("change", str(c.what), str(c.source))
  root.kids.add changes
  root.kids.add tree("source", str(img.source))
  "(.nif27)\n" & root.toNif & "\n"

proc loadImage*(text: string): Image =
  let root = parseNif(text)
  result = newImage()
  for sec in root.kids:
    case sec.text
    of "types":
      for t in sec.kids:
        var fs: seq[FieldDef]
        for i in 1 ..< t.len: fs.add FieldDef(name: t[i][0].text, typ: t[i][1])
        result.types[t[0].text] = fs
    of "procs":
      for m in sec.kids:
        let body = m[2]
        let sym = body[0].text
        result.procs[sym] = ProcDef(sym: sym, name: baseName(sym), params: paramsOf(body),
                                    body: body, source: m[1].text, version: m[0].intVal.int)
    of "heap":
      for o in sec.kids:
        let oop = o[0].intVal.int
        while result.heap.len <= oop: result.heap.add nil
        var obj = Obj(typ: o[1].text)
        for i in 2 ..< o.len: obj.fields[o[i][0].text] = nifValue(o[i][1])
        result.heap[oop] = obj
    of "globals":
      for kv in sec.kids: result.globals[kv[0].text] = nifValue(kv[1])
    of "changes":
      for c in sec.kids: result.changes.add Change(what: c[0].text, source: c[1].text)
    of "source": result.source = sec[0].text
    else: discard

proc field*(vm: VM; v: Value; name: string): Value =
  vm.img.obj(v).fields.getOrDefault(name)

proc local*(f: Frame; name: string): Value =
  ## A frame's variable by its plain name ("b"), as a debugger shows it.
  for k, v in f.vars:
    if baseName(k) == name: return v
  vmError("no local " & name)

proc setField*(vm: VM; v: Value; name: string; x: Value) =
  vm.img.obj(v).fields[name] = x
