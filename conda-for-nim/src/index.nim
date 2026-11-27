## Conda, THE package manager for Nim? How Nim's package managers work today (nimble, atlas,
## nimby: all on top of packages.json), modern conda for someone who knows little of it
## (conda-forge, mamba, rattler, pixi, rattler-build, prefix.dev), an interactive on the one
## concept that matters (who knows the dependency graph, and when), a working proof of concept
## (poc/), a survey of the Nim already in conda, and the effort it would take.
## Build: sh deps.sh && nim r -d:nimibQuiet index.nim (from this folder; writes ../index.html).
## The terminals are the files in poc/out, written by poc/run.sh and poc/feedstock.sh.
import std/[os, json, strformat, strutils, sequtils, tables, algorithm]
import nimib
import tabelline except Value
import tabelline/nimib
import lib/[style, blocks]
import review          # tabelline's review mode, from claude-artifacts shared/review (unchanged copy)

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.title = "Conda, THE package manager for Nim?"
nb.useExplainerStyle
nbReview(tpage = "conda-for-nim", tsource = "conda-for-nim/src/index.nim")

const
  srcDir = "https://github.com/pietroppeter/claude-artifacts/tree/main/conda-for-nim/src"
  pkgsJson = "https://github.com/nim-lang/packages"
  nimble = "https://github.com/nim-lang/nimble"
  atlas = "https://github.com/nim-lang/atlas"
  nimby = "https://github.com/treeform/nimby"
  feedstock = "https://github.com/conda-forge/nim-feedstock"
  bioconda = "https://github.com/bioconda/bioconda-recipes"
  pixi = "https://pixi.sh"
  rattlerBuild = "https://rattler.build"
  prefix = "https://prefix.dev"
  ceps = "https://github.com/conda/ceps"
  computeParis = "https://compute-paris.org"

proc term(name: string): string = readFile("poc/out" / name)
proc poc(path: string): string = readFile("poc" / path)
proc between(path, a, b: string): string =
  ## The part of a source file from the line holding `a` up to `b` (or to the end, when `b` is "").
  let s = readFile(path)
  let i = s.find(a)
  let j = if b == "": s.len else: s.find(b, i)
  s[s.rfind('\n', 0, i) + 1 ..< j]

# ------------------------------------------------------------------ data for the race and the survey
proc raceData(roots: openArray[string]): JsonNode =
  ## The dependency graphs of the recipes nimforge wrote (poc/recipes), for the race.
  var deps = initTable[string, seq[string]]()
  var versions = initTable[string, string]()
  for dir in toSeq(walkDirs("poc/recipes/nim-*")) & toSeq(walkDirs("poc/graphs/nim-*")):
    let name = dir.lastPathPart["nim-".len .. ^1]
    if name == "activation": continue
    var inRun = false
    deps[name] = @[]
    for line in readFile(dir / "recipe.yaml").splitLines:
      if line.startsWith("  version: \""): versions[name] = line.split('"')[1]
      if line.strip == "run:": inRun = true; continue
      if inRun:
        if not line.startsWith("    - "): inRun = false; continue
        let d = line.strip[2..^1].split(' ')[0]
        if d.startsWith("nim-") and d != "nim-activation": deps[name].add d["nim-".len .. ^1]
  result = newJObject()
  for root in roots:
    var g = newJObject()
    var v = newJObject()
    var todo = @[root]
    while todo.len > 0:
      let n = todo.pop
      if g.hasKey(n): continue
      g[n] = %deps[n]
      v[n] = %versions[n]
      todo.add deps[n]
    result[root] = %*{"deps": g, "versions": v}

let bio = parseJson(readFile("data/bioconda_nim.json"))

# ============================================================================================ title
nbKicker "So, what about Nim?"
nbText: """# Conda, <span class="mark">THE</span> package manager for Nim?"""

nbPrompt("Pietro", "26 Nov 2026", [
  """Met wolf of prefix.dev at compute Paris. He kind of convincing of making Conda THE package
manager for Nim. Explore this idea, how wild! Explain how currently package management in Nim
works with all the different experiments that people have done (nimble, atlas, solution by
treeform, … they all depend on packages.json) I know very little of conda and I am sure it has
evolved a LOT in the last few years. Write me the best explainer possible. Go wild!""",
  """What would the effort and the critical part? What would be the smallest thing that should be
tried in a few steps? Try to explain a critical concept with an interactive explainer. […] Style
the document inspired by prefix/pixi""",
  """Also wolf told me there are already Nim packages in Conda and I (or other) could be added as
maintainer. A survey of what Nim stuff is there a who has put effort there would be useful""",
  """Look also how zig and R are using Conda (see image). […] Also here I want to know about those
(Wolf's slide: Mojo, Common Lisp, GitHub Releases, ROS & RoboStack)"""])

nbLede: """
Nim has had three package managers in twelve years, and all three read the same file: a list
of about three thousand names and git URLs. Conda comes from the other side: it started as
"the Python package manager that is not pip", and is now a general, language-agnostic way to
ship *files into a folder*, with compilers, C libraries, Rust, R and CUDA in the same
environment. This page explains both, shows the one idea that makes them different, and then
**does it**: nimib and its dependencies built as conda packages, installed with `pixi`, building
a nimib page, with no nimble anywhere.
"""

nbTldr: """
- **Nim today**: nimble, atlas and nimby all start from `packages.json`, which knows a package's
  *name and git URL, and nothing else*. Versions are git tags, dependencies are in `.nimble`
  files, so every tool must clone to find out what to clone next.
- **Conda today** is not Anaconda's Python installer any more: conda-forge has about 35,000
  packages, `pixi` is a fast, project-first tool from prefix.dev (Wolf Vollprecht, who started
  mamba), `rattler-build` builds packages from a YAML recipe. Packages carry their metadata, so
  the whole dependency graph is known *before* downloading anything.
- **It already half works**: `pixi add nim` gives you Nim 2.2.6 *with its own gcc* on Linux and
  Intel Macs. The missing bridge is one environment variable: Nim already honours `NIMBLE_DIR`.
- **The PoC**: `nimforge` (under 200 lines of Nim) turns a `packages.json` entry into a recipe; 13
  Nim libraries (and the bridge) built, tested and installed this way, plus treeform's nimby itself as a conda
  package, and Nim 2.4.2 rebuilt with the bridge built in.
- **Nim is already in conda**: one compiler feedstock on conda-forge (stuck at 2.2.6, no Apple
  Silicon) and about twenty genomics tools on bioconda, by Brent Pedersen, Andrea Telatin, PacBio
  and others. Nobody ships Nim *libraries* yet.
- **Others went first**: R (3,844 packages on conda-forge), Zig's compiler, Mojo's and Common
  Lisp's community channels on prefix.dev, RoboStack's ROS packages generated from ROS's own
  registry. Nim can copy the best of each.
- **Smallest next step**: become a maintainer of `nim-feedstock`, merge the waiting 2.4 update,
  add osx-arm64 and the `NIMBLE_DIR` activation. Everything else builds on that.
"""

# ============================================================================================ 1
nbText: &"""
## Nim's package managers, and the phone book they share

Every Nim package manager starts from [nim-lang/packages]({pkgsJson}): one file,
`packages.json`, edited by pull request. This is the whole entry for nimib:
"""
let pj = parseJson(readFile("poc/packages.json"))
var nimibEntry, aliases, hosts: JsonNode
var hostCount = initCountTable[string]()
var nUrl, nAlias = 0
for p in pj:
  if p.hasKey("alias"): inc nAlias; continue
  inc nUrl
  if p["name"].getStr == "nimib": nimibEntry = p
  let u = p["url"].getStr
  hostCount.inc(if "://" in u: u.split('/')[2] else: "other")
nbFile("packages.json (one of " & $(nUrl + nAlias) & " entries)", "json", pretty(nimibEntry))

nbText: &"""
That is all the registry knows: a name, a git URL, a license, some tags. **No versions, no
dependencies, no checksums, no files.** Versions are git tags in nimib's repository, and its
dependencies are in `nimib.nimble`, a NimScript file at each tag. Of the {nUrl} packages,
{hostCount["github.com"]} live on GitHub, the rest on sourcehut, GitLab, Codeberg and friends.
Three tools read this file, each with its own idea of what to do next:
"""

nbCards([
  Card(name: "nimble", who: "dom96 (2014), now nim-lang; 0.28 in Nim's `koch`",
    motto: "the official one",
    text: "Downloads into `~/.nimble/pkgs2/name-version-checksum`. Reads `.nimble` files (now with a *declarative* parser, without running NimScript), solves versions (SAT solver since 0.16, PubGrub the default since 0.28), lock files, `nimble develop`."),
  Card(name: "atlas", who: "Araq (2021, own repo since 2023), ships with Nim 2.0",
    motto: "a workspace, not a store",
    text: "Clones dependencies into the project's `deps/` and writes their paths into `nim.cfg`, so the compiler needs no package manager at all. SAT solver, lazy loading, parallel clones, `--autoenv` to install the right Nim."),
  Card(name: "nimby", who: "treeform (since 2019), now 0.2.4",
    motto: "just git, at HEAD, in parallel",
    text: "Shallow-clones every dependency *at HEAD* into one visible workspace, in parallel, and writes `nim.cfg`. No resolution on purpose. A lock file (name, url, commit) for CI. Also installs Nim. Fidget2's CI went from 2 minutes to 3 seconds."),
  Card(name: "conda / pixi", who: "Continuum (2012) … prefix.dev (2023)", conda: true,
    motto: "the index already knows",
    text: "Installs prebuilt packages into an environment folder. Every package's version, dependencies and hash are in the channel's index (`repodata.json`), so it solves first and downloads once. The rest of this page."),
])

nbText: """
They differ in *where packages go* (a hidden store, a `deps/` folder, a sibling workspace) and
in *how versions are chosen* (a solver, a solver, no solver). They share the same first step:
to learn the dependencies of nimib you must fetch nimib, at a version you chose from its git
tags, and read a file in it. Then do the same for each dependency. treeform's README puts the
cost plainly: nimble took almost two minutes to install Fidget2's dependencies in CI, cloning
everything in parallel took three seconds. Parallelism helps within one level of the tree, but
not across levels: you can't clone the grandchildren before you have read the children.
"""

nbNote(nkNim, """
`packages.json` is a **phone book**, not an index: it tells you where to call, not what you will
hear. Everything else (versions, dependencies, checksums) is discovered by cloning. That is the
one design decision every Nim package manager has inherited.
""")

# ============================================================================================ 2
nbText: &"""
## Conda, for someone who last looked in 2016

Wolf's slide at [Compute Paris]({computeParis}) had this question on it:
*"But I thought Conda is for Python?!"*, and the answer underlined in yellow: conda is a
general-purpose, cross-platform, **language-agnostic** package manager. Here is his wheel,
redrawn, with a spoke left for us:
"""

nbWheel(["Python", "R", "C++", "CUDA", "Fortran", "OpenMP", "OCaml", "Zig", "Rust"],
  "Languages on Wolf Vollprecht's slide at Compute Paris 2026 (prefix.dev talk), redrawn. The dashed spoke is this page.")

nbText: """
The trick is that a conda package knows nothing about languages. It is **a compressed folder of
files** (`bin/nimby`, `lib/libz.so`, `share/nimble/pkgs2/jsony-1.1.6/jsony.nim`, …) plus an
`info/` folder of metadata. Installing it means unpacking those files into an *environment*,
which is just a directory, a *prefix* (hence the company name). A Python package puts files in
`lib/python3.13/site-packages`, an R package in `lib/R/library`, a C library in `lib/` and
`include/`. A Nim package can put its sources wherever the Nim compiler looks. That's it.
"""

nbTable toTableData(@[
  (term: "**package** (`.conda`)", what: "a zip of two zstd tarballs: the files, and `info/` (name, version, build string, dependencies, hashes, tests)", nim: "a `pkgs2/jsony-1.1.6-…` folder, with its metadata outside"),
  (term: "**environment** / prefix", what: "a folder with `bin/`, `lib/`, `include/`, `share/`…; files are hard-linked from a cache, so a second env costs nothing", nim: "`~/.nimble`, `deps/`, a nimby workspace"),
  (term: "**channel**", what: "a static web folder: one `repodata.json` per platform (`linux-64`, `osx-arm64`, `win-64`, `noarch`) listing every package with its dependencies", nim: "`packages.json`, if it had versions and dependencies"),
  (term: "**noarch**", what: "a package for every platform: pure Python, pure R, … and pure Nim sources", nim: "every Nim library"),
  (term: "**solver**", what: "picks versions for everything at once, from the index (SAT: libsolv in mamba, *resolvo* in pixi)", nim: "nimble's PubGrub, atlas's SAT"),
  (term: "**recipe**", what: "a `recipe.yaml`: where the source is, a build script, requirements, tests; `rattler-build` turns it into a package", nim: "the `.nimble` file plus a build"),
  (term: "**build / host / run**", what: "tools that run during the build (gcc, nim) / libraries you link against (zlib) / what users get (libz.so)", nim: "nothing: Nim assumes the C side is your problem"),
  (term: "**run exports**", what: "zlib says *whoever links me needs libzlib >=1.3 at run time*, so recipes don't have to", nim: "nothing"),
  (term: "**activation**", what: "scripts in `etc/conda/activate.d/` that set variables when an env is used (`$CC`, `$LDFLAGS`… and our `NIMBLE_DIR`)", nim: "`nim.cfg` paths"),
  (term: "**virtual packages**", what: "`__glibc`, `__osx`, `__cuda`: facts about the machine the solver must respect", nim: "nothing"),
  (term: "**feedstock**", what: "on conda-forge, one GitHub repo per recipe, built by CI for every platform, updated by a bot", nim: "a GitHub release, if you're lucky"),
]), rownameCol = "term":
  tabHeader "Conda in eleven words"
  colsLabel:
    term: "conda word"
    what: "what it is"
    nim: "nearest thing in Nim"
  fmtMarkdown ["term", "what", "nim"]

nbText: &"""
### What changed since you last looked

The conda you may remember was slow (a Python SAT solver on a huge index) and tied to
Anaconda's `defaults` channel, with its license terms. Most of the work since then happened
around **Wolf Vollprecht**: first at QuantStack, where he started **mamba** (the solver rewritten
in C++ on top of openSUSE's libsolv), then at **prefix.dev**, which rewrote the whole stack in
Rust as a set of libraries called **rattler**.
"""

nbTable toTableData(@[
  (year: "2012", what: "**conda**, at Continuum Analytics (later Anaconda): binary packages, environments, any language"),
  (year: "2015–16", what: "**conda-forge**: a community channel, one GitHub *feedstock* per recipe, CI for every platform, a bot that opens update PRs. Free of Anaconda's terms"),
  (year: "2019", what: "**mamba** (QuantStack): libsolv-based solver, parallel downloads, the `.conda` format (zstd) arrives"),
  (year: "2020–21", what: "**micromamba**: one static binary, no Python (it is how the PoC bootstraps)"),
  (year: "2022", what: "**prefix.dev** founded; **rattler**: conda as Rust libraries; **resolvo**, a SAT solver in Rust"),
  (year: "2023", what: "**pixi**: project-first like cargo (`pixi.toml`, `pixi.lock`, tasks, every platform locked at once). conda itself switches to the libmamba solver by default"),
  (year: "2024–25", what: &"**rattler-build** and the v1 `recipe.yaml` ([CEP 13/14]({ceps})), accepted on conda-forge; **sharded repodata** (CEP 16): fetch only the packages you need"),
  (year: "2026", what: "conda 26.10 itself depends on `conda-rattler-solver`; pixi 0.85, rattler-build 0.81 (what this page used); 50 CEPs, including conditional dependencies and attestations"),
]), rownameCol = "year":
  tabHeader "Conda, a short history"
  colsLabel:
    year: ""
    what: ""
  fmtMarkdown ["what"]
  tabSourceNote "Dates from memory and the CEP repository; the 2026 line from the packages used here."

nbNote(nkConda, &"""
**pixi** is the tool to look at. A `pixi.toml` names channels, platforms, dependencies and
tasks; `pixi run` solves, locks, installs and activates in one go. The lock file pins every
package, with its URL and sha256, *for every platform you list*, solved together. It feels like
cargo or uv, but the packages can be anything: Nim, gcc, zlib, Python, R, CUDA.
[pixi.sh]({pixi}) · [rattler.build]({rattlerBuild}) · [prefix.dev]({prefix})
""")

# ============================================================================================ 3
nbText: """
## The critical concept: who knows the graph, and when?

Here is the difference between the two worlds, slowed down. Pick a package and press
**Next round trip**. Both sides make one network round trip per press (in parallel, when there
are several things to fetch). The graphs are real: they are the `requires` of each package at its
latest tag, as nimforge read them for the PoC below. Try **fidget2**, treeform's UI library and
the project behind nimby's two-minute CI: 22 packages, five levels deep.
"""

nbRace raceData(["nimib", "pixie", "fidget2"])

nbText: """
Clone-first pays one tag listing and one clone **per level of the tree**, and it runs code (or
parses code) from each package to find out the next level. Index-first pays **one index
fetch** and **one download** however deep the tree is, and the solve, which is the clever
part, happens on your machine with nothing but metadata. That metadata was computed *once, when
the package was built*: someone cloned and read the `.nimble` file, so that nobody else has to.
"""

nbFold("How this interactive is built, with its source", """
It takes three small pieces, and no framework.

1. **The data comes from the PoC's own recipes.** At build time, `raceData` (in `index.nim`)
   walks `poc/recipes/nim-*` and `poc/graphs/nim-*`. Those are the recipes nimforge wrote from
   packages.json and from each package's `.nimble` file. From each `recipe.yaml`, it keeps the
   version and the `nim-*` names listed under `run:`. Then, starting from each root (nimib,
   pixie, fidget2), it collects the graph that can be reached and stores it as JSON:
   `{pkg: {deps: {name: [deps]}, versions: {name: version}}}`.
2. **A custom nimib block puts it on the page.** `nbRace` (in `lib/blocks.nim`) writes the
   empty lanes and the buttons as HTML. It puts the JSON in a `<script type="application/json">`
   tag, and inlines `lib/race.js`, which is read with `staticRead` when the page compiles.
   Nothing is loaded from a CDN, so it works inside a claude.ai artifact too.
3. **The script works out both stories in advance, as frames.**
   - `levels` splits the graph by depth, breadth first.
   - `clonePlan` makes one frame per round trip. The first is GET packages.json. Then, for each
     level of the tree, there is one frame for `git ls-remote --tags` on the frontier, and one
     frame for a clone that reads the `.nimble` files to find the next level.
   - `indexPlan` makes three frames: GET repodata (every edge is known), a local solve, and one
     download of everything.

   Each frame holds the state of every package (unknown, known, busy or got) and the counters.
   **Next round trip** moves both lanes forward by one frame, and `render` redraws them from it.
   **Play** is a timer on the same step.

So the race is a model, not a measurement. One press is one network round trip, and fetches made
in parallel count as one. The measured times are in the bars below.
""")
nbFile("index.nim (the raceData proc)", "nim", between("index.nim", "proc raceData", "\nlet bio"), tfolded = true)
nbFile("lib/blocks.nim (the nbRace block)", "nim", between("lib/blocks.nim", "const raceJs", ""), tfolded = true)
nbFile("lib/race.js", "javascript", readFile("lib/race.js"), tfolded = true)

nbNote(nkCareful, """
Two honest footnotes. A real Nim solver may need *more* clones than this (atlas and nimble read
several tags of a package when constraints conflict). And conda's index is big: modern clients
fetch **sharded repodata** (CEP 16), one small file per package name, so they too walk the
tree name by name, but over cached, compressed, HTTP/2 requests of a few kilobytes, never a
`git clone`.
""")

nbText: "Measured here, for nimib and its four dependencies, on the same machine:"
nbBars([
  ("`nimble install nimib` (0.18.2)", 30.3, false),
  ("`pixi install`, empty cache, **with gcc 16 and Nim**", 8.1, true),
  ("`pixi install`, warm cache", 0.26, true),
], "s", "nimble cloned 5 repositories (a first try took 48 s); pixi's cold run downloaded about 150 MB (the whole gcc toolchain, sysroot and Nim) and still finished first. A warm install only hard-links files. Commands and output in `poc/out/06-timings.txt`.")

# ============================================================================================ 4
nbText: """
## The proof of concept, in eight terminals

Everything below ran in a Linux container on 26 November 2026, with `poc/run.sh`. Every
terminal is that script's output, unedited except for shortened paths.

### 1. Nim is already on conda-forge

`pixi init`, `pixi add nim`, and you have a working Nim, *and the C compiler it needs*:
"""
nbTerm("pixi add nim", term("01-pixi-add-nim.txt"))

nbText: """
Look at the second command: `$GCC` is `x86_64-conda-linux-gnu-cc`, gcc 16 from conda-forge,
with its own sysroot. The `nim` package lists the C and C++ compilers as *run* dependencies,
and its `nim.cfg` reads `$GCC` and `$LDFLAGS`, which conda's compiler activation sets. Nim and
its backend come as one thing, the same on every Linux. There is one catch:
"""
nbTerm("no Apple Silicon", term("02-osx-arm64.txt"))

nbNote(nkCareful, """
conda-forge builds `nim` for linux-64, linux-aarch64 and osx-64 only: **no osx-arm64, no
Windows**. On an M-series Mac `pixi add nim` fails today (Rosetta's osx-64 build is the
workaround). It is the first thing to fix, and bioconda already works around it (below).
""")

nbText: """
### 2. The bridge: one environment variable

How does `nim` find a package that conda installed? It turns out Nim has had the answer for
years. In `compiler/commands.nim`, the `nimblepath` switch (which the default `nim.cfg` uses
for `~/.nimble/pkgs2`) is replaced by `$NIMBLE_DIR/pkgs2` whenever that variable is set:
"""
nbFile("compiler/commands.nim (Nim 2.2.6, as installed by pixi)", "nim", """
  of "nimblepath":
    if pass in {passCmd2, passPP} and optNoNimblePath notin conf.globalOptions:
      expectArg(conf, switch, arg, pass, info)
      var path = processPath(conf, arg, info, notRelativeToProj=true)
      let nimbleDir = AbsoluteDir getEnv("NIMBLE_DIR")
      if not nimbleDir.isEmpty and pass == passPP:
        path = nimbleDir / RelativeDir"pkgs2"
        nimblePath(conf, path, info)
        path = nimbleDir / RelativeDir"pkgs"
      nimblePath(conf, path, info)""")

nbText: """
And nimble reads `NIMBLE_DIR` too. So the convention writes itself: a Nim library package puts
its sources in **`$PREFIX/share/nimble/pkgs2/<name>-<version>/`** (the folder layout nimble
uses, so the compiler picks the highest version), and an activation script sets
**`NIMBLE_DIR=$CONDA_PREFIX/share/nimble`**. For the PoC that script is its own tiny package,
`nim-activation`; in the real thing it belongs in the `nim` package itself (section 8).
"""
nbFile("poc/recipes/nim-activation/recipe.yaml", "yaml", poc("recipes/nim-activation/recipe.yaml"))
nbFile("poc/recipes/nim-activation/activate.sh", "bash", poc("recipes/nim-activation/activate.sh"))

nbText: """
### 3. nimforge: from the phone book to recipes

To package Nim libraries we need recipes. `nimforge.nim` does for `packages.json` what
`rattler-build generate-recipe` does for PyPI and CRAN: look the name up, list the git tags,
pick the highest, clone it, read the `.nimble` file (version, `srcDir`, `requires`), translate
nimble's version operators (`^=`, `~=`, `&`) to conda's, and recurse into the dependencies.
Package names get a `nim-` prefix, like R's `r-`. (Not just for tidiness: `r-nimble`, an R
package for Bayesian models, is already on conda-forge.)
"""
nbFile("poc/nimforge.nim", "nim", poc("nimforge.nim"), tfolded = true)
nbTerm("nim r nimforge.nim nimib pixie", term("03-nimforge.txt"))
nbText: "This is the recipe it wrote for nimib:"
nbFile("poc/recipes/nim-nimib/recipe.yaml", "yaml", poc("recipes/nim-nimib/recipe.yaml"))

nbText: """
Three details carry the design. `noarch: generic`: one package for every platform, since Nim
libraries are sources. `run_constraints: nim >=1.4.0`: nimib's `requires "nim >= 1.4.0"` does
not *pull in* a compiler, it only forbids an old one. And the test: rattler-build creates a fresh
environment with the new package, its dependencies and `nim`, and checks that `import nimib`
compiles, which proves the dependencies *and* the `NIMBLE_DIR` bridge.

### 4. rattler-build: fourteen packages, tested
"""
nbTerm("rattler-build build --recipe-dir recipes", term("04-rattler-build.txt"))

nbText: """
`--recipe-dir` finds every recipe and builds them in dependency order, so each test can already
install the packages it needs from the local channel. The channel is just a folder with a
`repodata.json` per platform: copy it to any static web server, or upload it to prefix.dev.

### 5. A nimib page, built by pixi

A project that uses the channel. Nim comes from conda-forge, nimib and its dependencies from
the local channel, and a pixi task builds the page:
"""
nbFile("poc/demo/hello.nim", "nim", poc("demo/hello.nim"))
nbTerm("pixi run page", term("05-demo.txt"))
nbText: "And this is nimib in `pixi.lock`: a file, a hash, its dependencies, nothing to clone."
nbTerm("pixi.lock", term("05-lock.txt"))

nbText: """
### 6. Nim and a C library, from the same place

This is where conda is better than any language-specific package manager: the C side. Nim
wrappers usually start with *"first, `apt install libfoo-dev` (or brew, or vcpkg)"*. Here zlib
comes from conda-forge, headers and shared library in the environment, and the compiler flags
come from the activation:
"""
nbFile("poc/zdemo/crc.nim", "nim", poc("zdemo/crc.nim"))
nbTerm("pixi run crc", term("07-zlib.txt"))
nbText: """
`ldd` shows the binary links the `libz.so.1` *of the environment* (the env's `lib/` is in its
rpath, from `$LDFLAGS`). The same goes for openssl, pcre, SDL2, SDL3, GLFW, cairo, GTK,
sqlite, libuv, libsodium, ffmpeg, OpenCV, HDF5, Arrow, DuckDB, htslib: all on conda-forge, all
the things Nim wrappers keep telling you to install by hand.

### 7. A Nim app as a conda package: nimby, installed by conda

Compiled programs are the easy case. A recipe for treeform's nimby (`build` requirement: `nim`;
`run`: `git`), built and installed globally with `pixi global`, which puts a small trampoline in
`~/.pixi/bin`:
"""
nbFile("poc/apps/nimby/recipe.yaml", "yaml", poc("apps/nimby/recipe.yaml"))
nbTerm("pixi global install nimby", term("08-nimby.txt"))
nbText: """
Note the `libgcc >=16 (RE of [build: gcc_linux-64])` line: a **run export** of the compiler. The
recipe never mentions libgcc; the compiler package declared that whatever it builds needs it at
run time. Nimby is a nice test case for a different reason: its version 0.2.4 is in
`nimby.nimble` but has no git tag (the latest tag is v0.1.5), so the recipe pins a commit. A
generator can't guess that.

### 8. Nim 2.4.2, with the bridge built in

Last, the conda-forge recipe of `nim` itself, moved to the v1 format, bumped to 2.4.2, with the
activation script added (`poc/feedstock/nim`). Its test checks that `NIMBLE_DIR` points into
the environment, without the `nim-activation` package. Building Nim from source took 21 minutes
here (conda-forge CI does it once per platform), and note the third line: nimble 0.26.2, which
ships inside Nim 2.4.2, sees the variable too:
"""
nbFile("poc/feedstock/nim/recipe.yaml", "yaml", poc("feedstock/nim/recipe.yaml"), tfolded = true)
if fileExists("poc/out/09-feedstock.txt"):
  nbTerm("rattler-build build --recipe-dir feedstock", term("09-feedstock.txt"))

# ============================================================================================ 5
nbText: &"""
## How other languages live in conda

Nim would not be the first. Wolf's next slide was titled *New ecosystems are blooming*, with
Mojo, Common Lisp, GitHub Releases and *ROS & RoboStack, stronger than ever*; his first had Zig
and R on the wheel. Each one found a different answer to the same three questions: where do
library files go, who writes the recipes, and which channel hosts them.
"""

nbTable toTableData(@[
  (eco: "**R**", how: "3,844 `r-*` feedstocks on conda-forge, from CRAN and Bioconductor; packages install into `lib/R/library`, pure-R ones are `noarch: generic`", gen: "`rattler-build generate-recipe cran` (and conda-forge's R team bot)", lesson: "the model for a big library ecosystem: a prefix, a fixed folder, a generator, a team"),
  (eco: "**Zig**", how: "`zig` on conda-forge as a real compiler, with `zig_<platform>` activation packages and cross-compilers; apps built with it (ghostty, ncdu, poop). Zig *libraries* stay with `build.zig.zon`", gen: "hand-written feedstock (maintainers include Tim de Jager of prefix.dev)", lesson: "ship the toolchain everywhere first: `${{ compiler('zig') }}` works in any recipe"),
  (eco: "**Mojo**", how: "Modular ships `mojo`/`max` from its own conda channel and recommends pixi; the community channel `modular-community` on prefix.dev has 85 recipes (libraries precompiled into `lib/mojo`)", gen: "a GitHub repo of `recipe.yaml`s, CI builds them; a `pixi-build-mojo` backend", lesson: "a language's own community channel on prefix.dev, with its own build backend"),
  (eco: "**Common Lisp**", how: "the `common-lisp` channel on prefix.dev (Nov 2026 guest post by Shubhamkar Ayare): `sbcl` plus 100+ libraries in `$PREFIX/common-lisp/<lib>`, C parts compiled per platform; quicklisp still usable alongside", gen: "hand-written recipes and small scripts", lesson: "the closest twin to this PoC: an old ecosystem with its own library managers, adding conda for the C side and cross-platform installs"),
  (eco: "**GitHub Releases**", how: "the `github-releases` channel (1.8 TB, the biggest non-mirror channel on prefix.dev): release binaries repackaged with sigstore attestations, `pixi global install -c https://prefix.dev/github-releases htop-rs`", gen: "**octoconda**: a config list of repos, a GitHub Action", lesson: "Nim CLI tools with release binaries could be there tomorrow, with zero recipes"),
  (eco: "**ROS / RoboStack**", how: "thousands of ROS packages as conda packages in `robostack-*` channels on prefix.dev, for Linux, macOS and Windows", gen: "**vinca**: reads ROS's own registry (rosdistro, `package.xml`) and writes rattler-build recipes", lesson: "the precedent for nimforge: a generator from a language registry, run by CI, feeding a dedicated channel"),
  (eco: "**Lua** (a book)", how: "the *Rattler Book* (April 2026) builds *Moonshot*, a Lua package manager on top of rattler: init, add, lock with resolvo, install, shell, build", gen: "—", lesson: "a third road: a Nim package manager that *is* conda inside, with nimble's commands"),
]), rownameCol = "eco":
  tabHeader "Seven ecosystems in conda, and what each teaches Nim"
  colsLabel:
    eco: ""
    how: "how it lives in conda"
    gen: "who writes the recipes"
    lesson: "the lesson for Nim"
  fmtMarkdown ["eco", "how", "gen", "lesson"]
  tabSourceNote "conda-forge bot data (graph.json) for the counts; the prefix.dev blog posts on Common Lisp, octoconda, ROS 2, channel hosting and the Rattler Book; the repos modular/modular-community, RoboStack/vinca, prefix-dev/pixi-build-backends, conda-forge/zig-feedstock."

nbText: """
Put together, these give Nim a recipe: the **compiler** on conda-forge like Zig's, **libraries**
under a prefix in a fixed folder like R's, generated from the registry like RoboStack's, in a
**community channel** on prefix.dev like Mojo's and Common Lisp's (free accounts get 3 GB of
public storage, a lot of Nim source), with **release binaries** of Nim tools picked up by
octoconda on the side.
"""

var rows: seq[tuple[tool, what, who, nim, how: string]]
for o in bio:
  let maint = o["maintainers"].getElems.mapIt(it.getStr).filterIt(not it.contains(':') and not it.contains('{'))
  let home = o["home"].getStr
  let author = if "github.com/" in home: home.split("github.com/")[1].split('/')[0]
               elif "gitlab" in home: "SVI (GitLab)" else: ""
  var how: seq[string]
  if o["curls_nim"].getBool: how.add "**curls Nim nightlies on osx-arm64**"
  if o["uses_nimble"].getBool: how.add "nimble at build time"
  if o["nim"].getStr.len == 0: how.add "repackages a release binary"
  rows.add (tool: &"[{o[\"name\"].getStr}]({home})", what: o["summary"].getStr.split(". ")[0].strip(chars = {'.', ' '}),
    who: author & (if maint.len > 0: " (maintainer: " & maint.join(", ") & ")" else: ""),
    nim: (o["nim"].getStr & " " & o["nimsel"].getStr).strip, how: how.join("; "))
rows.sort(proc (a, b: auto): int = cmp(a.who.toLowerAscii, b.who.toLowerAscii))

nbText: &"""
## Nim is already in conda: a survey

Wolf was right: there is Nim in conda, in two places.

### conda-forge: the compiler, and nothing else

[conda-forge/nim-feedstock]({feedstock}) has packaged the Nim compiler since **8 November
2019**. Its history is a small relay race: **Christopher Dunn** (`pb-cdunn`, then at PacBio, who
needed Nim for genome assembly tools) created it; **Marcel Bargull** (a conda-forge and bioconda
core member) made it work on macOS in July 2020 and wired Nim to conda's compilers;
**Benjamin Cross** (`btcross26`) kept 1.4.x current in 2021; **Daylin Morgan** (`daylinmorgan`,
well known in the Nim community) brought it to 2.0 in 2023 and moved CI to Azure in 2024. Since
then the bot does the updates: 2.0.2 to 2.2.6 were merged automatically.

Then it stopped. The bot's pull requests for **2.2.10 (April 2026), 2.2.12 (September) and
2.4.0 (October)** are open and unmerged, so conda-forge still ships 2.2.6 while Nim is at 2.4.2.
conda-forge's dependency graph (the bot's `graph.json`) shows **no other feedstock depends on
`nim`**, not even to build. And the name `nim` is in conda-forge's *arm osx addition* migration,
which never landed: hence no osx-arm64.
"""

nbNote(nkConda, """
**Becoming a maintainer** is a documented, one-issue process: open an issue on the feedstock
titled `@conda-forge-admin, please add user @<github-name>`, and the admin bot opens the pull
request; any current maintainer merges it. With three maintainers who have not merged a bot PR
since 2025, that is the obvious first step, and Wolf's offer to help get you added makes it easy.
A maintainer merges bot PRs, adds platforms in `conda-forge.yml`, and reviews changes to the recipe.
""")

nbText: &"""
### bioconda: about twenty Nim tools for genomics

[bioconda]({bioconda}) is the channel for bioinformatics, built on top of conda-forge. Nim found
a niche there early, thanks to `hts-nim` (Nim bindings to htslib, the C library for sequencing
data): fast single-binary tools that bioinformaticians install with one command. A search of
bioconda's recipes for `nim` as a requirement or `nim c`/`nimble` in a build script finds these:
"""

nbTable toTableData(rows), rownameCol = "tool":
  tabHeader &"Nim on bioconda ({rows.len} recipes, November 2026)"
  colsLabel:
    tool: "package"
    what: "what it does"
    who: "author"
    nim: "nim requirement"
    how: "how it builds"
  fmtMarkdown ["tool", "how"]
  tabSourceNote "From a sparse checkout of bioconda-recipes (recipes/*/meta.yaml and build.sh), 26 Nov 2026; maintainers from recipe-maintainers where listed."

nbText: """
Three things stand out. **Brent Pedersen** (`brentp`: mosdepth, somalier, slivar, duphold,
hts-nim-tools, bigwig-nim) and **Andrea Telatin** (`telatin`, Quadram Institute: seqfu,
bamtocov, qax, porfast, barena, nim-abif) wrote most of them: Nim's quiet success story in
science. **Seven recipes download Nim nightlies with `curl` inside the build on osx-arm64**,
because conda-forge has no osx-arm64 `nim`: the gap above, worked around seven times. And
most run **nimble at build time**, fetching dependencies from GitHub during a conda build;
with Nim libraries as conda packages those would become ordinary `host` requirements, pinned,
cached and reproducible.

Nobody ships Nim *libraries* as conda packages yet: the `nim-` prefix exists only for two tools
(`nim-abif`, `nim-falcon`). The convention is free to set.
"""

# ============================================================================================ 6
nbText: """
## The effort, and the critical parts

What it would take to make conda a real home for Nim, from the cheapest piece to the most
expensive. "Critical" means: without it, the rest doesn't matter.
"""
nbTable toTableData(@[
  (piece: "Revive `nim-feedstock`: become maintainer, merge the 2.4 update", effort: "hours", critical: "**yes**: everything stands on it, and bioconda depends on it today"),
  (piece: "`nim` for **osx-arm64** (and win-64)", effort: "a day or two: cross-compile from osx-64 in conda-forge CI; Windows needs MinGW or MSVC wiring in `nim.cfg`", critical: "**yes**: most Nim users on a Mac can't start without it"),
  (piece: "`NIMBLE_DIR` activation in `nim`", effort: "one file (the PoC's `feedstock/nim`)", critical: "**yes**, the bridge, and no change to Nim or nimble needed"),
  (piece: "A convention: `nim-<name>`, sources in `share/nimble/pkgs2`, `noarch: generic`", effort: "a short write-up, agreed with conda-forge (like R's `r-` and Rust's)", critical: "yes, cheap now, painful to change later"),
  (piece: "A recipe generator (nimforge → `rattler-build generate-recipe nimble`)", effort: "days to weeks: `.nimble` is NimScript (`when` branches, tasks), many packages have no tags or `requires \"foo#head\"`, `installDirs`/`skipDirs`, binaries", critical: "for scale: 3,000 packages won't be written by hand"),
  (piece: "Where the packages live: conda-forge feedstocks, or a `nim-forge` channel on prefix.dev built from `packages.json`", effort: "conda-forge: hours per package, reviewed; own channel: a CI pipeline, weeks", critical: "a strategic choice: start with an own channel, promote popular libraries to conda-forge"),
  (piece: "C libraries: map `{.passL.}`, `dynlib` and `header` pragmas to conda-forge packages", effort: "per wrapper, ongoing", critical: "this is the *payoff*: the reason to do it at all"),
  (piece: "Developer workflow: a pixi build backend for Nim (`pixi-build-nim`), reading `.nimble` like `pixi-build-rust` reads `Cargo.toml`", effort: "weeks, in Rust, best with prefix.dev", critical: "what makes it feel native: `pixi add` a git dependency, `pixi build`, editable local packages"),
  (piece: "Quick win: Nim tools with release binaries in prefix.dev's `github-releases` channel", effort: "a PR to octoconda's config list", critical: "no, but free: `pixi global install` for Nim CLIs today"),
  (piece: "Or the third road: a Nim front end on rattler (nimble's commands, conda inside), as the Rattler Book does for Lua", effort: "months, in Rust (or Nim calling rattler)", critical: "only if Nim wants one tool; pixi already does most of it"),
  (piece: "Culture: versions and tags instead of `#head`", effort: "years, and not code", critical: "the real cost. nimby's README argues the opposite on purpose: in a small community HEAD is what works"),
]), rownameCol = "piece":
  tabHeader "Making conda Nim's package manager: the pieces"
  colsLabel:
    piece: "piece"
    effort: "effort"
    critical: "critical?"
  fmtMarkdown ["piece", "effort", "critical"]

nbNote(nkCareful, """
The downsides, honestly. A pixi environment with Nim weighs **849 MB** on disk, almost all of
it gcc and its sysroot (shared between environments through hard links, but still a big first
download on a slow line). Nim's own tools (nimble lock files, atlas workspaces) and pixi's lock
would co-exist, and someone has to explain which one wins. conda knows nothing of Nim's
backends: `nim js` needs no C compiler, and a JS-only project would still get gcc unless the
`nim` package splits into `nim` and `nim-c`. And Windows is the platform where conda-forge's
compiler story is the hardest.
""")

# ============================================================================================ 6b
nbText: """
## The third road: build your own, on shared foundations

Late in the talk, Wolf's slide said: *Everyone can build their own package manager with AI.
The new recipe format and our tools make it very easy to build your own ecosystem. Our
advice: build on incredible shared foundations, with best-in-class tools.* prefix.dev means it
literally. In April 2026 they published the **Rattler Book**: a literate, exercise-driven book
that builds *Moonshot*, a working package manager for Lua, on the rattler crates, with a chapter
on adapting it to your own language.

That suggests a learning project for a Nim person, and an answer to "should I port rattler?":
not rattler (a large Rust workspace of solver, networking, archives, auth and activation), but
**Moonshot**, command by command, into a Nim tool that is conda inside:
"""

nbTable toTableData(@[
  (cmd: "`init`", moon: "write a manifest", nim: "a `[package]` in the `.nimble`, or a `nimb.toml`"),
  (cmd: "`search`", moon: "query repodata", nim: "read `repodata.json` (and its shards) of conda-forge + a Nim channel"),
  (cmd: "`add`", moon: "edit the manifest", nim: "`requires \"nimib >= 0.4\"` becomes `nim-nimib >=0.4`"),
  (cmd: "`lock`", moon: "solve with resolvo", nim: "**the part worth porting by hand**: MatchSpec parsing and a SAT solver"),
  (cmd: "`install`", moon: "unpack `.conda` into a prefix", nim: "zip + zstd + tar, hard links from a cache, the `pkgs2` layout"),
  (cmd: "`shell` / `run`", moon: "activation scripts", nim: "set `NIMBLE_DIR`, `$CC`, `$LDFLAGS`, then `nim c`"),
  (cmd: "`build`", moon: "write a `.conda`", nim: "nimforge's recipe, without rattler-build"),
]), rownameCol = "cmd":
  tabHeader "Moonshot, the Rattler Book's package manager, as a Nim tool"
  colsLabel:
    cmd: "command"
    moon: "in the book (Lua)"
    nim: "in Nim"
  fmtMarkdown ["cmd", "moon", "nim"]

nbNote(nkNim, """
A sensible split: call rattler for the boring, hard parts (networking, archive formats, the
cache) and write the **solver** and the **MatchSpec / version** logic in Nim yourself. Those two
are where package management is actually decided, and they are small enough to understand
completely. With an AI doing the first pass of an automatic port, as with nimaki, the book's
tests and exercises become the check that the port is right.
""")

# ============================================================================================ 7
nbText: """
## The smallest thing to try, in four steps

The PoC above proves the mechanics. The smallest real step is about the feedstock, not about
new tools:

<ol class="steps">
<li><strong>Become a maintainer of nim-feedstock.</strong> Open the <code>@conda-forge-admin, please add user</code>
issue, then merge the bot's 2.4.0 pull request (or let it rerun for 2.4.2). An evening, and it
helps every bioconda tool too.</li>
<li><strong>Add osx-arm64 and the activation script.</strong> One PR: <code>build_platform: {osx_arm64: osx_64}</code> in
<code>conda-forge.yml</code>, and the <code>activate.sh</code>/<code>deactivate.sh</code> from <code>poc/feedstock/nim</code>. After
this, <code>pixi add nim</code> works on your Mac and knows where Nim packages go.</li>
<li><strong>Publish the PoC channel on prefix.dev.</strong> Create a channel (say <code>nim-go-wild</code>) and
<code>rattler-build upload prefix</code> the thirteen packages. Then anyone can
<code>pixi add -c https://prefix.dev/nim-go-wild nim-nimib</code> and build a nimib page in seconds.</li>
<li><strong>Ask Wolf two questions.</strong> Would prefix.dev welcome <code>rattler-build generate-recipe nimble</code>
(nimforge, in Rust)? And is a <code>pixi-build-nim</code> backend something they'd help with? Those
are the two pieces that turn a channel into a package manager.</li>
</ol>
"""

nbText: &"""
---

*Sources:* the repositories of [nimble]({nimble}) (changelog to 0.28), [atlas]({atlas})
(0.17.1), [nimby]({nimby}) (README and changelog), [nim-lang/packages]({pkgsJson}) and Nim's
`koch.nim` and `compiler/commands.nim`; conda-forge's [nim-feedstock]({feedstock}) (full
history and its open pull requests), conda-forge's bot data (`graph.json`, `all_feedstocks.json`),
[bioconda-recipes]({bioconda}); pixi and rattler-build docs and the [CEPs]({ceps}). Wolf's slide is
from Pietro's photo of the talk. The terminals were run with pixi 0.85.0, rattler-build 0.81.0,
nimble 0.18.2 and Nim 2.2.6 (conda-forge), in a Linux container. Sources of this page and the
PoC: [`conda-for-nim/src`]({srcDir}). Tables by [tabelline](https://pietroppeter.github.io/tabelline/),
page by [nimib](https://github.com/pietroppeter/nimib).
"""

nbSave
