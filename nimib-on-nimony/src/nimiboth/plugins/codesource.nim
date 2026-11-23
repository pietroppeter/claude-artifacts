## Template plugin: returns the source text of its (untyped) argument as a string literal,
## the way nimib's getCodeAsInSource does with lineInfoObj + readFile in Nim 2.
import plugins
import std/[syncio, strutils]

proc scan(n: NifCursor; lo, hi: var int; file: var string) =
  let info = n.info
  if info.isValid:
    let p = info.lineCol
    if p.line > 0:
      if file.len == 0: file = info.filePath
      if p.line < lo: lo = p.line
      if p.line > hi: hi = p.line
  for child in n.children:
    scan(child, lo, hi, file)

proc transform(input: NifCursor): NifBuilder =
  var body = callArgs(input)
  var lo = high(int)
  var hi = 0
  var file = ""
  scan(body, lo, hi, file)
  var code = ""
  if file.len > 0 and hi > 0:
    var lines: seq[string] = @[]
    try:
      lines = readFile(file).splitLines()
    except:
      discard
    var indent = high(int)
    for i in lo .. min(hi, lines.len):
      let l = lines[i-1]
      if l.strip.len > 0:
        var k = 0
        while k < l.len and l[k] == ' ': inc k
        if k < indent: indent = k
    for i in lo .. min(hi, lines.len):
      let l = lines[i-1]
      if code.len > 0: code.add "\n"
      if l.len >= indent: code.add l.substr(indent) else: code.add l
  result = createTree()
  result.addStrLit code

saveTree transform(loadPluginInput())
