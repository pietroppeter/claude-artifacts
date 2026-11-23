## Everything that differs between Nim 2 and Nimony, in one module. The rest of nimiboth is
## written in what both compilers accept, without `when defined(nimony)`.
import std/strutils
when defined(nimony):
  import std/syncio
  export syncio   # echo, readFile, writeFile: in Nim 2 they are in system
  template codeSource*(body: untyped): string {.plugin: "plugins/codesource".}
    ## the source lines of `body`: a template plugin (a program the compiler runs), since
    ## Nimony's std/macros has no `lineInfoObj`
  template cstr(s: var string): cstring = toCString(s)
  import std/osproc
  const jsCommand* = "nimony j --browser -o:"
    ## compiles a JS block with the page's own compiler: Nimony's JS back end (jorogumo)
else:
  import std/[macros, osproc]
  const jsCommand* = "nim js -d:release --hints:off -o:"
  macro codeSource*(body: untyped): string =
    ## the source lines of `body`, read back from the file, as nimib's sources.nim does
    let first = body.lineInfoObj
    var last = first.line
    proc walk(n: NimNode) =
      if n.lineInfoObj.line > last: last = n.lineInfoObj.line
      for c in n: walk(c)
    walk(body)
    let lines = staticRead(first.filename).splitLines
    var code: seq[string]
    var indent = high(int)
    for i in first.line .. last:
      let l = lines[i-1]
      if l.strip.len > 0: indent = min(indent, l.len - l.strip(trailing = false).len)
    for i in first.line .. last: code.add lines[i-1].substr(indent)
    result = newLit(code.join("\n"))
  template cstr(s: var string): cstring = cstring(s)

const compilerName* = when defined(nimony): "Nimony" else: "Nim " & NimVersion

# File I/O raises in Nimony (an ErrorCode, and every caller must say `.raises` or catch it).
# nimiboth catches it here, once, so no other proc needs an annotation.
proc readText*(path: string): string =
  ## the file's contents, or "" when it cannot be read
  try:
    result = readFile(path)
  except:
    result = ""

proc writeText*(path, content: string): bool =
  ## writes the file; false when it cannot
  try:
    writeFile(path, content)
    result = true
  except:
    result = false

proc runCommand*(cmd: string): int =
  ## runs `cmd` in a shell; its exit code, or -1 when it cannot run
  try:
    result = execCmd(cmd)
  except:
    result = -1

# stdout capture by file descriptor, as nimib's capture.nim does with fusion/ioutils
proc c_dup(fd: cint): cint {.importc: "dup", header: "<unistd.h>".}
proc c_dup2(a, b: cint): cint {.importc: "dup2", header: "<unistd.h>".}
proc c_open(p: cstring; flags: cint; mode: cint): cint {.importc: "open", header: "<fcntl.h>".}
proc c_close(fd: cint): cint {.importc: "close", header: "<unistd.h>".}
let O_WRONLY {.importc, header: "<fcntl.h>".}: cint
let O_CREAT {.importc, header: "<fcntl.h>".}: cint
let O_TRUNC {.importc, header: "<fcntl.h>".}: cint
  # `let`, not `var`: Nimony refuses a proc that reads a global `var` without `.sync`

type Capture* = object
  saved, fd: cint
  path: string

proc startCapture*(path: string): Capture =
  ## sends stdout to the file `path` until `stopCapture`
  flushFile(stdout)
  var p = path
  result = Capture(saved: c_dup(1), fd: c_open(cstr(p), O_WRONLY or O_CREAT or O_TRUNC, 0o644), path: path)
  discard c_dup2(result.fd, 1)

proc stopCapture*(c: Capture): string =
  ## restores stdout and returns what was written
  flushFile(stdout)
  discard c_dup2(c.saved, 1)
  discard c_close(c.fd)
  discard c_close(c.saved)
  result = readText(c.path)
