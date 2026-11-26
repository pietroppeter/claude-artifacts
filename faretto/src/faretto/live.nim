## The live part that needs a real machine: hand a module's source to
## Nimony, let it parse and type-check it (`nimony check`), and read back the
## semchecked NIF it writes. faretto never compiles to C: it runs the NIF.
import std/[os, osproc, strutils, times, monotimes]
import nif, vm

type Compiled* = object
  ok*: bool
  errors*: string
  module*: Node
  millis*: float

var nimonyBin* = getEnv("NIMONY", "nimony")

proc compile*(source: string; workdir, name: string): Compiled =
  createDir workdir
  let file = workdir / name & ".nim"
  writeFile(file, source)
  let t0 = getMonoTime()
  let (outp, code) = execCmdEx(quoteShell(nimonyBin) & " check " & quoteShell(name & ".nim"),
                               workingDir = workdir)
  result.millis = (getMonoTime() - t0).inMicroseconds.float / 1000
  if code != 0:
    var keep: seq[string]
    for line in outp.splitLines:
      if line.strip.len > 0 and not line.startsWith("nifmake") and not line.startsWith("FAILURE"):
        keep.add line
    result.errors = keep.join("\n")
    return
  for f in walkFiles(workdir / "nimcache" / "*.s.nif"):
    if not f.endsWith(".idx.nif") and not f.endsWith(".deps.nif"):
      let m = parseNif(readFile(f))
      if m.file.endsWith(name & ".nim"):
        result.module = m
        result.ok = true

type Live* = ref object
  vm*: VM
  workdir*, name*: string
  lastMillis*: float

proc boot*(source, workdir, name: string): Live =
  ## Starts a fresh image from a module: like loading code into a new Pharo image.
  let c = compile(source, workdir, name)
  if not c.ok: raise newException(VMError, c.errors)
  result = Live(vm: newVM(newImage()), workdir: workdir, name: name, lastMillis: c.millis)
  discard result.vm.loadModule(c.module, source, runMain = true)

proc resume*(imageFile, workdir, name: string): Live =
  result = Live(vm: newVM(loadImage(readFile(imageFile))), workdir: workdir, name: name)

proc topLevelChunks(source: string): seq[(string, string)] =
  ## Splits a module into its top-level declarations: ("proc lit", text) ...
  var cur: seq[string]
  var key = ""
  proc flush(res: var seq[(string, string)]) =
    if cur.len > 0: res.add (key, cur.join("\n"))
    cur = @[]
  for line in source.splitLines:
    if line.len > 0 and line[0] notin {' ', '#'}:
      result.flush
      let words = line.split({' ', '(', '*', ':', '='})
      key = if words[0] in ["proc", "func"] and words.len > 1: words[0] & " " & words[1]
            elif words[0] == "type": "type"
            else: line
    cur.add line
  result.flush

proc accept*(live: Live; code: string): LoadReport =
  ## Pharo's "Accept" (Ctrl-S in a code pane): replace one proc (or type) in
  ## the image's module, let Nimony check the whole module, and swap in the
  ## procs whose NIF changed. Nothing is re-run; objects keep their state.
  let newChunks = topLevelChunks(code.strip)
  var chunks = topLevelChunks(live.vm.img.source)
  for (k, text) in newChunks:
    var found = false
    for c in chunks.mitems:
      if c[0] == k: c[1] = text & "\n"; found = true
    if not found:
      # a new proc goes before the first global, so the module still checks
      var at = chunks.len
      for i, c in chunks:
        if c[0].startsWith("var ") or c[0].startsWith("let ") or c[0].startsWith("echo "):
          at = i; break
      chunks.insert((k, text & "\n"), at)
  var src = ""
  for c in chunks: src.add c[1] & "\n"
  let c = compile(src, live.workdir, live.name)
  live.lastMillis = c.millis
  if not c.ok: raise newException(VMError, c.errors)
  result = live.vm.loadModule(c.module, src)
