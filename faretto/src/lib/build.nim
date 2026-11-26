## Build-time helpers of the page: Nimony on the PATH (or $NIMONY), the lit variants of the
## playground, the boot image, the JavaScript build, the command line VM and a speed test.
import std/[os, osproc, strutils, strformat]
import nimib
import ../faretto/[vm, live]

let here* = currentSourcePath().parentDir.parentDir
let scratch* = getTempDir() / "faretto-page"

proc sh*(cmd: string; dir = here): string =
  let (o, code) = execCmdEx(cmd, workingDir = dir)
  doAssert code == 0, cmd & "\n" & o
  o.strip

proc nimonyVersion*(): string =
  sh(quoteShell(nimonyBin) & " --version").splitLines[0]

proc nimonyCommit*(): string =
  let d = findExe(nimonyBin).parentDir.parentDir
  sh("git log -1 --format='%h, %cs'", d)

const litVariants* = [
  ("Fl(2) 6s", """
proc lit(t: int): bool =
  ## the light's character, Fl(2) 6s: two flashes, then dark
  let p = t mod 6
  p == 0 or p == 2"""),
  ("Fl(3) 10s", """
proc lit(t: int): bool =
  ## Fl(3) 10s: three flashes, then dark
  let p = t mod 10
  p == 0 or p == 2 or p == 4"""),
  ("Oc 4s", """
proc lit(t: int): bool =
  ## Oc 4s, occulting: mostly light, one dark second
  t mod 4 != 3"""),
  ("Iso 4s", """
proc lit(t: int): bool =
  ## Iso 4s, isophase: as long light as dark
  t mod 4 < 2"""),
  ("Mo(U) 12s", """
proc lit(t: int): bool =
  ## Mo(U) 12s: the letter U in Morse, dot dot dash
  let p = t mod 12
  p == 0 or p == 2 or (p >= 4 and p <= 6)"""),
]

proc playgroundVariants*(): seq[(string, string, string)] =
  ## For each version of lit: its label, its source highlighted, and the NIF of the proc
  ## that `nimony check` wrote, as the playground will swap it in.
  let l = boot(readFile(here / "examples" / "lanterna.nim"), scratch / "variants", "lanterna")
  for (label, src) in litVariants:
    discard l.accept(src)
    result.add (label, highlightNim(src.strip), l.vm.procNode("lit").toNif)

proc bootImage*(): string =
  let l = boot(readFile(here / "examples" / "lanterna.nim"), scratch / "boot", "lanterna")
  saveImage(l.vm.img)

proc playgroundJs*(): string =
  let outp = scratch / "playground.js"
  discard sh("nim js -d:release --hints:off --warnings:off -o:" & quoteShell(outp) & " lib/playground.nim")
  readFile(outp)

proc buildCli*(): string =
  result = scratch / "bin" / "faretto"
  discard sh("nim c -d:release --hints:off --warnings:off -o:" & quoteShell(result) & " faretto.nim")

proc term*(cli, imageFile: string; args: varargs[string]): string =
  ## Runs the command line VM in its own process; returns the prompt line and its output.
  let shown = "$ faretto " & imageFile.extractFilename & " " & args.join(" ")
  let (o, code) = execCmdEx(quoteShell(cli) & " " & quoteShell(imageFile) & " " & args.join(" "),
                            workingDir = imageFile.parentDir)
  doAssert code == 0, o
  var lines: seq[string]
  for l in o.strip.splitLines:
    lines.add(if l.startsWith("faretto: "): l.split(" nodes in ")[0] & " nodes evaluated" else: l)
  shown & "\n" & lines.join("\n")

proc nativeNight*(n: int): float =
  ## night(capo, n) compiled by Nimony to native code, in ms.
  let d = scratch / "native"
  createDir d
  var src = readFile(here / "examples" / "lanterna.nim").replace("import std/syncio", "import std/[syncio, monotimes, times]")
  var keep: seq[string]
  for l in src.splitLines:
    if not l.startsWith("echo"): keep.add l
  keep.add &"""
let t0 = getMonoTime()
let s = night(capo, {n})
let us = inMicroseconds(getMonoTime() - t0)
echo s.len
echo us"""
  writeFile(d / "lanterna.nim", keep.join("\n"))
  let r = sh(quoteShell(nimonyBin) & " c -r -d:release lanterna.nim", d).splitLines
  parseFloat(r[^1]) / 1000

proc benchCli*(cli, imageFile: string; n: int): float =
  ## night(capo, n) in the command line VM (built with -d:release), in ms, as it reports it.
  let (o, code) = execCmdEx(quoteShell(cli) & " " & quoteShell(imageFile) & " night capo " & $n & " >/dev/null")
  doAssert code == 0, o
  for l in o.splitLines:
    if l.startsWith("faretto: "): return parseFloat(l.split(" nodes in ")[1].split(" ")[0])
