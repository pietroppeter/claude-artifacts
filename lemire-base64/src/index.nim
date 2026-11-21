## Lemire's MIME base64 decoding ranking, replicated, with Nim added.
## Build: sh deps.sh && nim r index.nim   (writes ../index.html; the numbers come from data/, written by bench/run_cloud.sh)
import std/[strformat, strutils, sequtils, os]
import nimib except md
import tabelline, tabelline/nimib
import lib/[data, blocks]
import lib/style as pagestyle   # (as: tabelline exports a `style` too)
import review   # tabelline's review mode, from shared/review at the root of this repository (config.nims)
import bench/nim/[b64scalar, b64avx2, b64avx512]

nbInit
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.title = "Decoding base64 email attachments, now with Nim"
nb.useExplainerStyle
nb.useSourceFooter
nbReview(tpage = "lemire-base64", tsource = "lemire-base64/src/index.nim")

# ---------------------------------------------------------------- data, at build time
let here = currentSourcePath().parentDir
let ours = readRuns(here / "data", "results_cloud_run")
let his = readRuns(here / "data", "results_big4_run")
let ourHeader = header(here / "data", "results_cloud_run1.txt")
let nRuns = toSeq(walkFiles(here / "data" / "results_cloud_run*.txt")).len
let testLine = readFile(here / "data" / "test_output.txt").strip

proc g(r: Speed): string = formatFloat(r.median, ffDecimal, 1)
let
  nimStd = ours.pick("nim", "std/base64")
  nimScalar = ours.pick("nim", "scalar (4 tables) decode (preallocated)")
  nimAvx2 = ours.pick("nim", "nimsimd AVX2 decode (preallocated)")
  nimAvx512 = ours.pick("nim", "AVX-512 VBMI2 decode (preallocated)")
  nimFfi = ours.pick("nim", "simdutf")
  cpp = ours.pick("c++", "base64_to_binary")
  goPre = ours.pick("go", "preallocated")
  java = ours.pick("java", "Base64")
  php = ours.pick("php", "base64_decode")
  zig = ours.pick("zig", "decoderWithIgnore")

func kindOf(r: Speed): BarKind =
  if not r.isNim: bkOther
  elif "simdutf" in r.function: bkFfi
  else: bkNim

func langName*(r: Speed): string =
  let sys = r.system.split(' ')[0]
  case sys
  of "c++": "C++"
  of "nim": "Nim"
  of "go": "Go"
  of "java": "Java"
  of "php": "PHP"
  of "python": "Python"
  of "node": "Node.js"
  of "bun": "Bun"
  of "zig": "Zig"
  else: sys

func short(r: Speed): string =
  &"**{langName(r)}** `{r.function}`"

# ---------------------------------------------------------------- the page
nbText: """
# Decoding base64 email attachments, **now with Nim**
"""

nbLede: &"""
Daniel Lemire ranked programming languages by how fast their standard base64 decoder
reads an email attachment, line breaks included. We ran his benchmark again and added Nim:
the standard library, a faster plain-Nim decoder, two SIMD decoders written in Nim, and Nim
calling simdutf. Every line of code behind the page, ours and Lemire's, is at the
end of the page, folded file by file.
"""

nbStats(@[
  (value: g(nimStd), label: "GB/s, Nim's std/base64 (about Go and Java)"),
  (value: g(nimScalar), label: "GB/s, plain Nim with lookup tables, no SIMD"),
  (value: g(nimAvx512), label: "GB/s, Nim with AVX-512, about " & $int(100 * nimAvx512.median / cpp.median + 0.5) & "% of simdutf"),
  (value: g(cpp), label: "GB/s, C++ simdutf, the top of the ranking"),
])

nbText: &"""
## The question

[The post](https://lemire.me/blog/2026/11/20/decoding-base64-email-attachments/) (20 November 2026)
makes one megabyte of random bytes, encodes it as base64 with 76-character lines ending in CRLF
(1.37 MB of text, as in an email), and times the standard decoder of each language. The point:
many fast decoders only work on base64 without line breaks, and fall back to a slow path at the
first CRLF. simdutf removes line endings inside its vector loop, so everything built on it
(C++, Node.js, Bun, Deno, PHP with his pull request, Python's fastpybase64) sits at the top,
and the rest sits 10 to 30 times lower.

We used [his code](https://github.com/lemire/Code-used-on-Daniel-Lemire-s-blog/tree/master/2026/11/javashell/mimebench)
unchanged (same input generator, same protocol: check the bytes, warm up 600 calls, keep the best
of 10 batches of 200 calls, median of runs) and wrote a Nim harness that follows the same protocol.

## The ranking, with Nim
"""

nbBars("MIME base64 decoding, GB/s of input (higher is faster)",
  ours.mapIt((label: short(it), value: it.median, kind: kindOf(it))),
  &"Median of {nRuns} runs on one core of a cloud VM, see below. \"preallocated\" means the output buffer is reused across calls.")
nbText: "The same numbers as a table, made with [tabelline](https://pietroppeter.github.io/tabelline/) from the same rows:"

var ranking: seq[tuple[rank: int, gbps, lo, hi: float, lang, function: string]]
for i, r in ours:
  ranking.add (i + 1, r.median, r.runs.min, r.runs.max, langName(r), "`" & r.function & "`")
let rankTable = tabella(ranking):
  optCssTheme()
  optRowStriping()
  tabHeader "MIME base64 decoding, GB/s", &"median and range of {nRuns} runs, one core"
  colsLabel {"rank": "#", "lang": "Language", "function": "Function", "gbps": "GB/s", "lo": "Runs"}
  fmtMarkdown "function"
  fmtNumber ["gbps", "lo", "hi"], decimals = 1
  colsMergeRange "lo", "hi"
  tabStyle style.text(weight = "bold"), loc.body(rows = where($it["lang"] == "Nim"))
nbTable rankTable
nbFile "index.nim", start = "var ranking:", stop = "nbTable rankTable", folded = true,
  title = "The code of this table ([tabelline](https://pietroppeter.github.io/tabelline/))"

nbNote(nkCareful, &"""
This is not Lemire's machine. It is a shared cloud VM: {ourHeader[1].split(':')[1].strip},
4 vCPUs, which reports CPU model 207, the same Emerald Rapids family as his Xeon Gold 6548N,
but at 2.1 GHz and shared with other machines, so runs vary. The same simdutf code ran at {g(cpp)} GB/s from C++ and
{g(nimFfi)} GB/s from Nim, with runs from {formatFloat(nimFfi.runs.min, ffDecimal, 1)} to
{formatFloat(nimFfi.runs.max, ffDecimal, 1)}: read differences under about 20% as noise.
The versions are the ones this machine has: g++ 13, Node.js 22, Go 1.27.0, Java 21, PHP 8.3,
Python 3.13 with fastpybase64 0.2.1, Bun 1.4.4, and Zig 0.17.1 (the same as Lemire's, from PyPI's
`ziglang` package). No Deno or .NET here.
""")

nbText: """
### Same tools, his machine and ours
"""

var compare: seq[tuple[lang: string, his, here: float, function: string]]
for (sys, fn) in [("c++", "base64_to_binary"), ("python", "fastpybase64"), ("node", "Buffer.from"),
                  ("bun", "Buffer.from"), ("bun", "fromBase64"), ("go", "preallocated"),
                  ("go", "DecodeString"), ("java", "Base64"), ("zig", "decoderWithIgnore"),
                  ("php 8.5", "base64_decode")]:
  let a = his.pick(sys, fn)
  compare.add (langName(a), a.median, ours.pick(sys.split(' ')[0], fn).median, "`" & a.function & "`")
let compareTable = tabella(compare):
  optCssTheme()
  optRowStriping()
  tabHeader "Same tools, two machines", "GB/s, median of runs"
  colsLabel {"lang": "Language", "function": "Function", "his": "Lemire", "here": "Here"}
  fmtMarkdown "function"
  fmtNumber ["his", "here"], decimals = 1
  tabSourceNote md("Lemire: Xeon Gold 6548N, his `results_big4_run*.txt`. Here: a cloud VM, see above.")
nbTable compareTable
nbFile "index.nim", start = "var compare:", stop = "nbTable compareTable", folded = true,
  title = "The code of this table ([tabelline](https://pietroppeter.github.io/tabelline/))"

nbText: """
The order is the same: simdutf-based decoders on top, then Go, Java, Zig and stock PHP an
order of magnitude lower. Our absolute numbers are lower because of the slower clock and the older
versions (Bun moved the most).
"""

nbText: &"""
## The Nim decoders

The three decoders we wrote end the same way: `decodeTail` in `b64scalar.nim` handles the last
few characters and the `=` padding, character by character. They differ in the hot loop.
Every one is checked on the benchmark input (length and byte sum, as in the other languages)
and in `bench/nim/test.nim` against `std/base64` on random inputs of every size from 0 to
3,000 bytes, with CRLF, LF, space and no line breaks, and with one corrupted character that
must raise. Result: `{testLine}`.

### 1. `std/base64`: {g(nimStd)} GB/s

The standard library already copes with line breaks: before each group of four characters
it skips `\r`, `\n` and spaces. Each character is then a table lookup, a check and a shift,
written one byte at a time. That is about Go's speed ({g(goPre)} GB/s) and Java's
({g(java)} GB/s), faster than Zig's `decoderWithIgnore` ({g(zig)} GB/s), and twice stock PHP ({g(php)} GB/s).

### 2. Plain Nim, four tables: {g(nimScalar)} GB/s

Base64 packs 3 bytes (24 bits) into 4 characters of 6 bits each. A plain decoder (like
`std/base64`) looks up each character's 6-bit value, checks it, then shifts and ORs the four
values together and writes three bytes one by one.

The trick comes from **modp_b64**, the base64 code of Nick Galbreath's [*stringencoders*](https://github.com/client9/stringencoders) C library,
which Chromium ships as [`third_party/modp_b64`](https://github.com/chromium/chromium/tree/main/third_party/modp_b64) for its own base64 functions. It moves
the shifting into the tables: instead of one table of 6-bit values, four tables `d0`..`d3`, one per
position in the group of four. `d0[c]` holds the value of `c` already shifted to bits 23..18,
`d1[c]` to bits 17..12, and so on, and already in the byte order the CPU stores (little-endian).
Decoding a group is then four loads and three ORs, and one 4-byte store writes the three bytes
(the fourth byte is overwritten by the next group). An invalid character's entry has bits above
the 24 set, so one comparison of the result checks all four characters. With `"TWFu"`, the base64
of `"Man"`:
"""

nbCode:
  let quad = "TWFu"
  let tables = [d0, d1, d2, d3]
  var x = 0'u32
  for k, c in quad:
    echo "d", k, "['", c, "'] = 0x", tables[k][uint8 c].toHex(8)
    x = x or tables[k][uint8 c]
  echo "OR      = 0x", x.toHex(8), "  bytes in memory: ", [char(x and 0xFF), char(x shr 8 and 0xFF), char(x shr 16 and 0xFF)]
  echo "d0['!'] = 0x", d0[uint8 '!'].toHex(8), "  >= bad: invalid"

nbText: &"""
A line ending is skipped when it starts a group, which it always does with 76-character lines
(76 is a multiple of 4). Anywhere else it sends the decoder to the slow path in `decodeTail`
for the rest of the input, the cliff Lemire's post is about: this decoder is fast for email and
PEM (64 is a multiple of 4 too), not for any line length.
"""

nbFile "bench/nim/b64scalar.nim", start = "while i + 4 < n:", stop = "decodeTail(src, i, n, dst, o)"

nbCode:
  # the three decoders on a small MIME input (lines of 8 characters here)
  let mime = "SGVsbG8s\r\nIE5pbSBh\r\nbmQgYmFz\r\nZTY0IQ==\r\n"
  echo decodeScalar(mime)
  echo decodeAvx2(mime)
  echo decodeAvx512(mime)

nbText: &"""
### 3. AVX2 with nimsimd: {g(nimAvx2)} GB/s

[nimsimd](https://github.com/guzba/nimsimd) gives Nim the x86 intrinsics up to AVX2. The decoder
works on a 4 KB buffer in two steps:

1. **compact**: copy the input 32 bytes at a time. A block with no byte at or below `0x20` is
   one load and one store. A block with a line ending is compacted 8 bytes at a time with
   BMI2 `pext`, which keeps the bytes a mask selects.
2. **decode**: the Muła–Lemire AVX2 algorithm: three `pshufb` lookups validate and translate
   32 characters, two multiply-adds and two shuffles pack them into 24 bytes.

"""

nbFile "bench/nim/b64avx2.nim", start = "while b < BufSize and i + 32", stop = "if bad != 0"

nbText: &"""

On the same machine it decodes base64 without line breaks at about 10 GB/s, so the
compaction step costs about a third.

### 4. AVX-512 VBMI2: {g(nimAvx512)} GB/s

nimsimd stops at AVX2, so `b64avx512.nim` imports the dozen AVX-512 intrinsics it needs
with `importc`. Same two steps, 64 bytes at a time, and both get simpler:
`vpcompressb` drops the line endings of a 64-byte block in one instruction (no branch at all),
and one `vpermi2b` translates 64 characters through a 128-entry table, as in Muła and Lemire's
AVX-512 decoder. That is roughly what simdutf does on this CPU (its "icelake" kernel); part of
the gap left ({g(nimAvx512)} vs {g(cpp)} GB/s) is probably that simdutf, as the post says, decodes
clean blocks straight from the input and compacts only the blocks that need it.

"""

nbFile "bench/nim/b64avx512.nim", start = "while b < BufSize and i + 64", stop = "if bad != 0"

nbText: &"""

### 5. Nim calling simdutf: {g(nimFfi)} GB/s

The same as PHP's pull request or Python's fastpybase64: Nim calls the C++ library. Nim
compiles to C here (the C backend, not `nim cpp`), and C cannot call a C++ function directly, so
`simdutf_wrap.cpp` is a small `extern "C"` wrapper around `simdutf::base64_to_binary`. g++
compiles it and simdutf into object files, `simdutf.nim` declares the wrapper's functions with
`{{.importc.}}` and links the objects with `-lstdc++`. With `nim cpp` one could instead call
simdutf directly with `{{.importcpp.}}` and no wrapper; it would run the same simdutf code.

C++, Python and Nim all run the same simdutf kernel ("icelake", the AVX-512 one), so they should
be equally fast, and they are, within this machine's noise: {g(cpp)}, {g(ours.pick("python", "fastpybase64"))}
and {g(nimFfi)} GB/s. Calling through Python or Nim adds a few nanoseconds per call, nothing
next to the {int(1368424.0 / cpp.median / 1000)} µs a call takes to decode
1.37 MB. The compiler is not it either: the C++ benchmark built with clang 18 instead of g++ 13
ran at the same speed (14.0 to 14.7 GB/s in three runs); the fastpybase64 wheel was built with clang 21.
"""

nbNote(nkReading, """
Three things made the AVX2 decoder slow while we wrote it. All three are fixed in the code on
this page (the numbers are before and after); each was found by reading the generated assembly:

- **`countSetBits` from `std/bitops`** showed up as a function call in the hot loop, where one
  `popcnt` instruction was wanted. Fixed by using `mm_popcnt_u32` from nimsimd, which is the instruction.
- **`copyMem` into a stack array** became `__memcpy_chk`, because Ubuntu's gcc turns on
  `_FORTIFY_SOURCE`. Each call also emitted a `vzeroupper`. Fixed with a plain 8-byte store
  through a `ptr uint64`, which took the AVX2 decoder from 1.6 to 5.5 GB/s.
- **A branch-free compaction was slower** (5.5 GB/s) than branching on "is this block clean?"
  (6.7 GB/s): with 78-byte lines more than half of the 32-byte blocks are clean, and the predictor copes.
  The code keeps the branch.
""")

nbNote(nkNimib, &"""
The cheap win is the scalar decoder: plain Nim, no SIMD, no new dependency, and
{formatFloat(nimScalar.median / nimStd.median, ffDecimal, 1)}x faster than `std/base64` on email
attachments. It could go to the standard library as it is (with `decode` keeping its
signature). The SIMD decoders need a CPU check at run time (nimsimd's `runtimecheck`) before
they could be used anywhere but on a machine you know.
""")

nbText: """
## Run it yourself

Everything is in this page's [`src/` folder](https://github.com/pietroppeter/claude-artifacts/tree/main/lemire-base64/src):

- `bench/`: Lemire's files (commit in `bench/UPSTREAM_COMMIT`; his `zig/main.zig` and `go/`), our
  `run_cloud.sh`, and `bench/nim/` with the decoders, `bench.nim` (the harness) and `test.nim`.
- `data/`: the raw result lines of each run, ours and Lemire's.

From `bench/`, after `python3 gen.py`: build Lemire's programs as in his `run.sh` (Zig with
`python3 -m ziglang build-exe -O ReleaseFast -lc zig/main.zig`), then
`g++ -O3 -c` simdutf and `nim/simdutf_wrap.cpp` into `nim/`, and
`nim c -d:danger nim/bench.nim`. `./run_cloud.sh` prints one run; this page reads all the
`results_cloud_run*.txt` files in `data/` when it is built.
"""

nbText: """
## All the sources

Every file of the benchmark and of this page, as it ran. Tap a name to open it.

### The Nim decoders and their harness
"""

for f in ["bench/nim/b64scalar.nim", "bench/nim/b64avx2.nim", "bench/nim/b64avx512.nim",
          "bench/nim/simdutf.nim", "bench/nim/simdutf_wrap.cpp", "bench/nim/bench.nim", "bench/nim/test.nim"]:
  nbFile f, folded = true

nbText: """
### Lemire's benchmark

Unchanged, from his repository (commit in `bench/UPSTREAM_COMMIT`), except `run_cloud.sh`, our
version of his `run.sh` for the tools of this machine.
"""

for f in ["bench/gen.py", "bench/bench.cpp", "bench/bench.py", "bench/bench.mjs", "bench/go/main.go",
          "bench/zig/main.zig", "bench/Bench.java", "bench/bench.php", "bench/rank.py", "bench/run_cloud.sh"]:
  nbFile f, folded = true, lang = (if f.endsWith(".mjs"): "js" else: "")

nbText: """
### This page

A [nimib](https://github.com/pietroppeter/nimib) document; the tables are made with
[tabelline](https://pietroppeter.github.io/tabelline/).
"""

for f in ["index.nim", "lib/data.nim", "lib/blocks.nim", "lib/style.nim", "config.nims", "deps.sh"]:
  nbFile f, folded = true

nbSave
