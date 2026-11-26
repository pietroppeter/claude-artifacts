## nimforge: turn a packages.json entry into a rattler-build recipe.
##
##   nim r nimforge.nim nimib          # writes recipes/nim-<pkg>/recipe.yaml for nimib and its deps
##
## packages.json only knows name -> git url. Versions come from git tags,
## dependencies from the .nimble file of the tagged checkout. That is the
## whole trick: do the cloning ONCE, at build time, and write the answer
## into conda metadata, so users never have to clone anything.

import std/[json, os, osproc, strutils, sequtils, algorithm, tables, sets, strformat]

type
  Req = object
    name, spec: string           # conda name and conda version spec
  Pkg = object
    name, url, tag, version, srcDir, license, description: string
    nimSpec: string
    hasModule: bool              # is there a <name>.nim we can import in a test?
    requires: seq[Req]

const
  # The only hand-written knowledge: packages whose top module refuses to be imported.
  # (conda-forge has the same thing, as per-feedstock patches; here it is one table.)
  testImport = {"nimsimd": "nimsimd/sse2"}.toTable

proc sh(cmd: string): string =
  let (outp, code) = execCmdEx(cmd)
  if code != 0: quit "failed: " & cmd & "\n" & outp
  outp

proc lookup(pkgs: JsonNode, name: string): JsonNode =
  for p in pkgs:
    if p["name"].getStr.cmpIgnoreStyle(name) == 0:
      if p.hasKey("alias"): return lookup(pkgs, p["alias"].getStr)
      return p
  quit "not in packages.json: " & name

proc cmp(a, b: seq[int]): int =
  for i in 0 ..< max(a.len, b.len):
    let x = if i < a.len: a[i] else: 0
    let y = if i < b.len: b[i] else: 0
    if x != y: return cmp(x, y)

proc versionKey(v: string): seq[int] =
  for part in v.split('.'):
    try: result.add parseInt(part) except ValueError: result.add 0

proc latestTag(url: string): string =
  ## Highest version-looking tag, "" if the repo has no tags.
  var tags: seq[string]
  for line in sh("git ls-remote --tags --refs " & url).splitLines:
    if line.len == 0: continue
    let t = line.split("refs/tags/")[1]
    if t.strip(chars = {'v'}).allIt(it in Digits or it == '.'): tags.add t
  if tags.len == 0: return ""
  tags.sort(proc (a, b: string): int =
    cmp(versionKey(a.strip(chars = {'v'})), versionKey(b.strip(chars = {'v'}))))
  tags[^1]

proc condaName*(nimName: string): string =
  "nim-" & nimName.toLowerAscii.replace("_", "-")

proc toCondaSpec*(nimSpec: string): string =
  ## nimble: ">= 1.2", "^= 0.8", "~= 1.2.3", "== 1.0", ">= 1 & < 2", "#head"
  var parts: seq[string]
  for c in nimSpec.split('&'):
    let c = c.strip
    if c.len == 0 or c.startsWith("#"): continue   # git refs: no conda equivalent
    if c.startsWith("^="):
      let v = c[2..^1].strip
      let p = v.split('.')
      let major = parseInt(p[0])
      parts.add if major > 0: &">={v},<{major+1}" else: &">={v},<0.{parseInt(p[1])+1}"
    elif c.startsWith("~="):
      let v = c[2..^1].strip
      let p = v.split('.')
      parts.add &">={v},<{p[0]}.{parseInt(p[1])+1}"
    else:
      parts.add c.replace(" ", "")
  parts.join(",")

proc parseNimble(path: string, p: var Pkg) =
  ## A tiny "declarative" reader: good enough for most .nimble files.
  for raw in readFile(path).splitLines:
    let line = raw.strip
    template value(): string = line.split('=', 1)[1].strip.strip(chars = {'"'})
    if line.startsWith("version") and '=' in line: p.version = value()
    elif line.startsWith("srcDir") and '=' in line: p.srcDir = value()
    elif line.startsWith("license") and '=' in line: p.license = value()
    elif line.startsWith("description") and '=' in line: p.description = value()
    elif line.startsWith("requires"):
      for item in line["requires".len..^1].split(','):
        let item = item.strip.strip(chars = {'"', ' ', '(', ')'})
        if item.len == 0: continue
        var i = 0
        while i < item.len and item[i] in IdentChars + {'-'}: inc i
        let (name, spec) = (item[0..<i], item[i..^1].strip)
        if name.cmpIgnoreStyle("nim") == 0: p.nimSpec = toCondaSpec(spec)
        else: p.requires.add Req(name: name, spec: toCondaSpec(spec))

proc fetch(pkgs: JsonNode, name, work: string): Pkg =
  let entry = lookup(pkgs, name)
  result.name = entry["name"].getStr
  result.url = entry["url"].getStr
  result.license = entry{"license"}.getStr
  result.description = entry{"description"}.getStr
  result.tag = latestTag(result.url)
  let dir = work / result.name
  removeDir dir
  let branch = if result.tag.len > 0: "--branch " & result.tag else: ""
  discard sh(&"git clone -q --depth 1 {branch} {result.url} {dir}")
  let nimble = toSeq(walkFiles(dir / "*.nimble"))
  if nimble.len > 0: parseNimble(nimble[0], result)
  let srcRoot = if result.srcDir.len > 0: dir / result.srcDir else: dir
  result.hasModule = fileExists(srcRoot / result.name & ".nim")
  if result.version.len == 0: result.version = result.tag.strip(chars = {'v'})
  for r in result.requires.mitems: r.name = lookup(pkgs, r.name)["name"].getStr

proc recipe(p: Pkg): string =
  let src = if p.srcDir.len > 0: p.srcDir & "/" else: ""
  let pin = if p.tag.len > 0: "  tag: " & p.tag else: "  branch: HEAD"
  var run = @["nim-activation"]
  for r in p.requires: run.add (condaName(r.name) & " " & r.spec).strip
  let nimc = if p.nimSpec.len > 0: "nim " & p.nimSpec else: "nim"
  let test = if not p.hasModule: "" else: &"""
tests:
  - script:
      # NIMBLE_DIR comes from nim-activation; no --path, no nimble
      - echo 'import {testImport.getOrDefault(p.name, p.name)}' > t.nim
      - nim check --hints:off t.nim
    requirements:
      run:
        - nim
"""
  result = &"""
# generated by nimforge from packages.json + {p.name}.nimble
context:
  name: {p.name}
  version: "{p.version}"

package:
  name: {condaName(p.name)}
  version: ${{{{ version }}}}

source:
  git: {p.url}
{pin}

build:
  number: 0
  noarch: generic
  script:
    # the pkgs2 layout nim's --nimblePath already understands
    - mkdir -p $PREFIX/share/nimble/pkgs2/${{{{ name }}}}-${{{{ version }}}}
    - cp -r {src}. $PREFIX/share/nimble/pkgs2/${{{{ name }}}}-${{{{ version }}}}/
    - rm -rf $PREFIX/share/nimble/pkgs2/${{{{ name }}}}-${{{{ version }}}}/.git

requirements:
  run:
{run.mapIt("    - " & it).join("\n")}
  run_constraints:
    - {nimc}

{test}
about:
  homepage: {p.url}
  license: {p.license}
  summary: {escapeJson(p.description)}
"""

when isMainModule:
  let root = getCurrentDir()
  let pkgs = parseJson(readFile(root / "packages.json"))
  let work = root / ".work" / "nimforge"
  createDir work
  var todo: seq[string]
  var outDir = "recipes"
  for a in commandLineParams():
    if a.startsWith("--out:"): outDir = a[6..^1] else: todo.add a
  var done = initHashSet[string]()
  while todo.len > 0:
    let name = todo.pop
    if name.toLowerAscii in done: continue
    let p = fetch(pkgs, name, work)
    done.incl name.toLowerAscii
    done.incl p.name.toLowerAscii
    let dir = root / outDir / condaName(p.name)
    createDir dir
    writeFile(dir / "recipe.yaml", recipe(p))
    echo &"{condaName(p.name):<16} {p.version:<8} tag={p.tag:<8} requires: ",
      p.requires.mapIt(it.name & " " & it.spec).join(", ")
    for r in p.requires: todo.add r.name
