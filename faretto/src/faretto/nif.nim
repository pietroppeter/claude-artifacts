## A small reader and writer for NIF, Nimony's text format for code.
## About 150 lines: enough to read the semchecked `.s.nif` that Nimony writes
## and to write faretto's own image file, which is NIF too.
import std/[strutils]

type
  NodeKind* = enum
    nkTree     ## (tag kid kid ...)
    nkSym      ## a symbol use: name.disamb or name.disamb.module
    nkSymDef   ## a symbol definition, written :name.disamb
    nkIdent    ## a plain identifier, written as is
    nkStr      ## "string"
    nkChar     ## 'c'
    nkInt      ## 42, -3
    nkFloat    ## 2.5
    nkEmpty    ## .
  Node* = ref object
    kind*: NodeKind
    text*: string        ## tag name, symbol, identifier or string value
    intVal*: int64
    floatVal*: float
    kids*: seq[Node]
    line*, col*: int     ## absolute position in the source file (1-based line)
    file*: string
    links*: seq[RootRef] ## MetaLinks attached to this node (see vm.nim)
    base: string         ## cached baseName of a symbol

proc `[]`*(n: Node; i: int): Node {.inline.} = n.kids[i]
proc len*(n: Node): int {.inline.} = n.kids.len
proc `[]`*(n: Node; i: BackwardsIndex): Node {.inline.} = n.kids[n.kids.len - int(i)]
proc isTag*(n: Node; tag: string): bool = n.kind == nkTree and n.text == tag

proc unescape(s: string): string =
  ## NIF escapes a byte as \XX (two hex digits) plus a few shortcuts.
  var i = 0
  while i < s.len:
    if s[i] == '\\' and i + 1 < s.len:
      case s[i+1]
      of 'n': result.add '\n'; inc i, 2
      of 't': result.add '\t'; inc i, 2
      of 'r': result.add '\r'; inc i, 2
      of '|': result.add '\\'; inc i, 2
      of '^': result.add '"'; inc i, 2
      else:
        if i + 2 < s.len:
          result.add chr(parseHexInt(s[i+1 .. i+2])); inc i, 3
        else:
          result.add s[i]; inc i
    else:
      result.add s[i]; inc i

proc b62(c: char): int =
  if c <= '9': ord(c) - ord('0')
  elif c <= 'Z': ord(c) - ord('A') + 10
  else: ord(c) - ord('a') + 36

type Parser = object
  s: string
  i: int

const Delims = {' ', '\t', '\n', '\r', '(', ')', '@', '~', '#'}

proc readB62(p: var Parser): int =
  var neg = false
  if p.i < p.s.len and p.s[p.i] == '~': neg = true; inc p.i
  while p.i < p.s.len and p.s[p.i] in {'0'..'9', 'A'..'Z', 'a'..'z'}:
    result = result * 62 + b62(p.s[p.i]); inc p.i
  if neg: result = -result

proc readInfo(p: var Parser; n, parent: Node) =
  ## Line info suffix: @col,line,file with base-62 numbers, relative to the
  ## parent node unless a file is given; `~` starts a negative number.
  n.line = (if parent != nil: parent.line else: 0)
  n.col = (if parent != nil: parent.col else: 0)
  n.file = (if parent != nil: parent.file else: "")
  if p.i >= p.s.len or p.s[p.i] notin {'@', '~'}: return
  if p.s[p.i] == '@': inc p.i
  let dc = p.readB62
  var dl = 0
  if p.i < p.s.len and p.s[p.i] == ',':
    inc p.i; dl = p.readB62
  if p.i < p.s.len and p.s[p.i] == ',':
    inc p.i
    let start = p.i
    while p.i < p.s.len and p.s[p.i] notin {' ', '\t', '\n', '\r', '(', ')'}: inc p.i
    n.file = unescape(p.s[start ..< p.i]); n.col = dc; n.line = dl
  else:
    n.col += dc; n.line += dl
  if p.i < p.s.len and p.s[p.i] == '#':  # a #comment#
    inc p.i
    while p.i < p.s.len and p.s[p.i] != '#': inc p.i
    inc p.i

proc skipWs(p: var Parser) =
  while p.i < p.s.len and p.s[p.i] in {' ', '\t', '\n', '\r'}: inc p.i

proc parseNode(p: var Parser; parent: Node): Node =
  p.skipWs
  let c = p.s[p.i]
  result = Node()
  case c
  of '(':
    inc p.i
    let start = p.i
    while p.s[p.i] notin Delims: inc p.i
    result.kind = nkTree
    result.text = p.s[start ..< p.i]
    p.readInfo(result, parent)
    while true:
      p.skipWs
      if p.s[p.i] == ')': inc p.i; break
      result.kids.add p.parseNode(result)
    return
  of '"':
    inc p.i
    let start = p.i
    while p.s[p.i] != '"': inc p.i
    result.kind = nkStr
    result.text = unescape(p.s[start ..< p.i])
    inc p.i
  of '\'':
    inc p.i
    let start = p.i
    while p.s[p.i] != '\'': inc p.i
    result.kind = nkChar
    result.text = unescape(p.s[start ..< p.i])
    inc p.i
  else:
    let start = p.i
    while p.i < p.s.len and p.s[p.i] notin Delims: inc p.i
    let tok = p.s[start ..< p.i]
    if tok == ".": result.kind = nkEmpty
    elif tok[0] == ':': result.kind = nkSymDef; result.text = tok[1..^1]
    elif tok[0] in {'0'..'9'} or (tok[0] in {'-', '+'} and tok.len > 1 and tok[1] in {'0'..'9'}):
      if '.' in tok or 'E' in tok:
        result.kind = nkFloat; result.floatVal = parseFloat(tok)
      else:
        result.kind = nkInt
        result.intVal = parseBiggestInt(tok.strip(leading = false, chars = {'u'}))
    elif '.' in tok: result.kind = nkSym; result.text = tok
    else: result.kind = nkIdent; result.text = unescape(tok)
  p.readInfo(result, parent)

proc parseNif*(s: string): Node =
  ## Parses a whole NIF file and returns its top-level tree (skipping the
  ## `(.nif27)`-style directives at the start).
  var p = Parser(s: s)
  while true:
    p.skipWs
    if p.s.continuesWith("(.", p.i):
      while p.s[p.i] != ')': inc p.i
      inc p.i
    else: break
  result = p.parseNode(nil)

proc baseName*(sym: string): string =
  ## The name part of a symbol `name.disamb[.dedup][.module]`:
  ## `tick.0.` -> `tick`, `\2E.<.0.Inpqkww1.` -> `..<`. The name may hold
  ## dots itself, so it ends at the first all-digits part.
  let parts = sym.split('.')
  var i = 1
  while i < parts.len and not (parts[i].len > 0 and parts[i].allCharsInSet({'0'..'9'})): inc i
  result = unescape(parts[0 ..< min(i, parts.len)].join("."))

proc base*(n: Node): string =
  ## baseName of a symbol node, computed once.
  if n.base.len == 0: n.base = baseName(n.text)
  n.base

proc isGlobalSym*(sym: string): bool =
  ## Locals are `name.disamb`; module-level symbols have a third part.
  sym.count('.') >= 2

# ---------------------------------------------------------------- writing
proc escape(s: string; quote: char): string =
  for ch in s:
    if ch in {'\\', '"', '\'', '(', ')', '\n', '\r', '\t'} or ch < ' ':
      result.add '\\' & toHex(ord(ch), 2)
    else: result.add ch

proc toNif*(n: Node; indent = 0): string =
  ## Writes a tree back as NIF text (without line info).
  case n.kind
  of nkTree:
    result = "(" & n.text
    var short = true
    for k in n.kids:
      if k.kind == nkTree: short = false
    for k in n.kids:
      if short: result.add " " & toNif(k, indent + 1)
      else: result.add "\n" & spaces(indent + 1) & toNif(k, indent + 1)
    result.add ")"
  of nkSym: result = n.text
  of nkSymDef: result = ":" & n.text
  of nkIdent: result = escape(n.text, ' ')
  of nkStr: result = "\"" & escape(n.text, '"') & "\""
  of nkChar: result = "'" & escape(n.text, '\'') & "'"
  of nkInt: result = $n.intVal
  of nkFloat: result = $n.floatVal
  of nkEmpty: result = "."

proc tree*(tag: string; kids: varargs[Node]): Node =
  Node(kind: nkTree, text: tag, kids: @kids)
proc str*(s: string): Node = Node(kind: nkStr, text: s)
proc ident*(s: string): Node = Node(kind: nkIdent, text: s)
proc intLit*(i: int64): Node = Node(kind: nkInt, intVal: i)
