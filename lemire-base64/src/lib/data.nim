## The benchmark results, read at build time from the files the runs wrote
## (same line format and the same median as Lemire's rank.py).
import std/[re, algorithm, strutils, tables, os, sequtils]

type Speed* = object
  system*, function*: string
  runs*: seq[float]
  median*: float

func median(v: seq[float]): float =
  let s = v.sorted
  if s.len mod 2 == 1: s[s.len div 2] else: (s[s.len div 2 - 1] + s[s.len div 2]) / 2

proc readRuns*(dir, prefix: string): seq[Speed] =
  ## All `<prefix>*.txt` files in `dir`, one row per (system, function), fastest first.
  let lineRe = re"^(.*?) mime (.*): ([0-9.]+) GB/s$"
  var speeds = initOrderedTable[(string, string), seq[float]]()
  for path in toSeq(walkFiles(dir / prefix & "*.txt")).sorted:
    for line in lines(path):
      var m: array[3, string]
      if line.strip.match(lineRe, m):
        speeds.mgetOrPut((m[0], m[1]), @[]).add parseFloat(m[2])
  for k, v in speeds:
    result.add Speed(system: k[0], function: k[1], runs: v, median: median(v))
  result.sort(proc(a, b: Speed): int = cmp(b.median, a.median))

proc header*(dir, file: string): seq[string] =
  ## The first lines of a results file: kernel, CPU, compiler.
  for line in lines(dir / file):
    if " mime " in line: break
    result.add line

func isNim*(r: Speed): bool = r.system.startsWith("nim ")

proc pick*(rows: seq[Speed], system, function: string): Speed =
  ## The row whose system starts with `system` and whose function contains `function`.
  for r in rows:
    if r.system.startsWith(system) and function in r.function: return r
  raise newException(KeyError, "no result for " & system & " " & function)

func spread*(r: Speed): float =
  ## (max - min) / median, in percent: how noisy the runs were.
  100 * (r.runs.max - r.runs.min) / r.median
