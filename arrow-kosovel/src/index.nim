## Puščica: Apache Arrow, explained with the poems of Srečko Kosovel. The columnar format byte by
## byte (with a layout explorer to tap), the rest of the Arrow family, who makes it, and Arrow
## in Nim: a dependency-free C Data Interface in Nim (lib/cdata.nim) handing columns to pyarrow,
## Polars and DuckDB, and nanoarrow compiled into the page to read the poems' Arrow file.
## Build: sh deps.sh && nim r -d:release index.nim   (from this folder; writes ../index.html)
## Needs Nim 2.2, libpcre3, python3 with pyarrow, polars and duckdb (for the bridge section).
import std/[strformat, strutils, os, osproc, json, tables, algorithm, unicode, sequtils]
import nimib
import tabelline, tabelline/nimib
import lib/[blocks, corpus, cdata, nanoarrow]
import lib/style as pagestyle   # (as: tabelline exports a `style` too)
import review   # tabelline's review mode, from shared/review at the root of this repository (config.nims)

let here = currentSourcePath().parentDir
let scratch = getTempDir() / "puscica-build"
createDir scratch

nbInit
nb.doc.filename = here.parentDir / "index.html"
nb.title = "Puščica: Apache Arrow, told with Kosovel"
nb.usePuscicaStyle
nbReview(tpage = "arrow-kosovel", tsource = "arrow-kosovel/src/index.nim")

const
  arrowDocs = "https://arrow.apache.org/docs/format/Columnar.html"
  cdataDocs = "https://arrow.apache.org/docs/format/CDataInterface.html"
  nanoarrowUrl = "https://arrow.apache.org/nanoarrow/"
  wikivir = "https://sl.wikisource.org/wiki/Kategorija:Sre%C4%8Dko_Kosovel"
  dumps = "https://dumps.wikimedia.org/slwikisource/latest/"
  whatAboutArrow = "https://pietroppeter.github.io/nanuq/blog/2026-11-09-what-about-arrow.html"
  srcDir = "https://github.com/pietroppeter/claude-artifacts/tree/main/arrow-kosovel/src"
  committers = "https://arrow.apache.org/committers/"

nbThemes()

nbText: """
# Puščica: Apache Arrow, told with <em>Kosovel</em>
"""

nbLede: """
**Apache Arrow** is a promise about memory: *this is exactly how a table of data sits in RAM,
down to the byte.* Keep the promise, and a table made by one program can be read by another,
in another language, without converting or copying a thing. In ten years that promise has
spread to most of the modern data stack.

To see what it means, byte by byte, we need a table. Ours is made of poems by **Srečko
Kosovel** (1904–1926), the poet of the Karst, who died at 22 and left behind hundreds of poems,
from gentle landscapes to the wild, typographic *konsi*. Slovenian is a good test: *č*, *š* and
*ž* each take two bytes, which is exactly where an Arrow string column gets interesting.

*Puščica* is Slovenian for a small arrow.
"""

# ------------------------------------------------------------------ the data
nbText: &"""
## The data: 509 texts, in an Arrow file

Kosovel's poems are on the Slovenian Wikisource, [Wikivir]({wikivir}), all marked
*javna last* (public domain). A script (`data/make_dataset.py`) went through the monthly
[Wikisource dump]({dumps}), kept every page by Kosovel, and wrote one table, one row per text,
three ways: Parquet (to store), an **Arrow IPC stream** (to load), and JSON (for your browser).

This page is a Nim program, and it loads the poems from the Arrow file with
[nanoarrow]({nanoarrowUrl}), Arrow's small C library, compiled into the page itself (more
on that [below](#arrow-in-nim)):
"""

nbCode:
  let poems = loadPoems(here / "data" / "kosovel.arrows")
  var kinds: CountTable[string]
  for p in poems: kinds.inc p.kind
  echo poems.len, " texts: ", kinds
  let bori = poems.filterIt(it.title == "Bori")[0]
  echo bori.title, " (", bori.collection, "): ", bori.lines[0..2].join(" / ")

let pick = poems.filterIt(it.title == "Moj črni tintnik")[0]
nbText: """
*Pesem* is a poem, *kons* one of the constructivist poems (*Kons* from *konstrukcija*, the
collection *Integrali '26* was only published in 1967), *proza* a prose poem. Here is one of the
konsi, which you will meet again below, byte by byte:
"""
nbPoem(pick.title, pick.text, "Srečko Kosovel, from *Integrali '26*. Text: Wikivir, public domain.")

# ------------------------------------------------------------------ rows and columns
nbText: """
## Rows, or columns

A table can sit in memory in two ways. Row by row, each poem's title, kind and word count
next to each other, the way a CSV file or a list of objects does it. Or column by column:
all the titles, then all the kinds, then all the word counts.
"""

var rowsHtml = """<div class="rc"><div class="box"><b>Row by row (a list of records)</b><div class="strip">"""
var colsHtml = """<div class="box"><b>Column by column (Arrow)</b><div class="strip">"""
let few = poems.filterIt(it.title in ["Bori", "Kons. 5", "Polh v jeseni", "Burja"])
for p in few:
  rowsHtml.add &"""<span class="t">{escHtml(p.title)}</span><span class="k">{p.kind}</span><span class="w">{words(p.text).len}</span>"""
for p in few: colsHtml.add &"""<span class="t">{escHtml(p.title)}</span>"""
for p in few: colsHtml.add &"""<span class="k">{p.kind}</span>"""
for p in few: colsHtml.add &"""<span class="w">{words(p.text).len}</span>"""
nbHtml rowsHtml & "</div></div>" & colsHtml & "</div></div></div>"

nbText: """
Analytics loves columns. "How many words did Kosovel write?" reads one column and nothing
else, in one straight run through memory, which is what CPU caches and SIMD instructions are
built for. Compression likes columns too: a column of *kinds* repeats three values.

Every data system knew this, and each had its own columnar layout: pandas had NumPy arrays and
Python objects, Spark had its own, every database its own. Moving a table from one to the
next meant converting it, value by value, and a lot of time in data pipelines went to exactly
that. Arrow's idea (2016) was to agree, once, on one layout that everyone could use **as their
own memory**, so that handing a table over is handing over a pointer.
"""

# ------------------------------------------------------------------ the layout
nbText: &"""
## A column of strings, byte by byte

Take the first stanza of *Bori* (pines), with the empty line after it, as a column of four
strings. In Arrow ([the spec]({arrowDocs})) a `utf8` column is three buffers:

1. a **validity bitmap**: one bit per value, 1 if the value is there, 0 if it is null;
2. **offsets**: length + 1 integers (int32), where each value starts and ends;
3. **data**: all the bytes of all the strings, end to end, with nothing in between.

The empty line is a *null* here: no value at all (Arrow keeps "missing" apart from
"empty string"). This is `lib/layout.nim`, the same code that draws the explorer below:
"""

nbCode:
  let stanza = bori.lines[0..3]               # three lines, then the blank one
  let l = utf8Layout(stanza, [true, true, true, false])
  for b in l.buffers:
    echo align(b.name, 8), ": ", b.bytes.len, " bytes"
  echo "validity: ", toBin(l.buffers[0].bytes[0], 8), "  (read it right to left: row 0 is the last bit)"
  echo "offsets:  ", offsetsOf(fromLayout("", l))
  let line2 = stanza[2]
  echo "row 2 is data[", offsetsOf(fromLayout("", l))[2], " ..< ", offsetsOf(fromLayout("", l))[3], "]: ", line2

nbText: """
Each value is the slice of the data buffer between two neighbouring offsets. The null has two
equal offsets (it takes no bytes) and a 0 in the bitmap. Reading row *i* is two lookups, no
scanning: Arrow is built for **random access** too.

### Characters are not bytes

The offsets count **bytes**, and Arrow strings are UTF-8. The ASCII letters take one byte each,
but *č*, *š*, *ž* take two (`c4 8d`, `c5 a1`, `c5 be`), and Kons. 5's `∞` takes three:
"""

nbCode:
  for w in ["Kras", "Srečko", "kraška", "čez", "∞"]:
    var b: Buffer
    for c in w: b.add byte(c)
    echo align(w, 7), "  ", runeCount(w), " characters, ", w.len, " bytes: ", hexBytes(b)

var allText = ""
for p in poems: allText.add p.text
var nonAscii: CountTable[string]
for r in allText.runes:
  if r.int > 127: nonAscii.inc $r
nonAscii.sort
let topNon = toSeq(nonAscii.pairs)[0..5].mapIt(&"{it[0]} {it[1]}").join(", ")
nbText: &"""
Over the whole corpus, Kosovel's {allText.runeLen} characters take {allText.len} bytes. The most common
characters outside ASCII: {topNon}. So a "string length" in Arrow is a length in bytes,
and an Arrow-speaking library that counts *letters* (Polars' `len_chars`, pyarrow's
`utf8_length`) has to walk the bytes.
"""

nbNote(nkIdea, """
Everything in an Arrow column is a flat buffer of fixed-width things (bits, int32s, bytes), and
buffers are aligned to 8 bytes and padded to 64 in files, so they can be memory-mapped and
fed straight to SIMD. No pointers inside: that is what makes the same bytes valid in C++, Rust,
Java, JavaScript, Python, R... and Nim.
""")

# ------------------------------------------------------------------ the explorer
let picks = ["Bori", "Kons. 5", "Moj črni tintnik", "Jutro na Krasu", "Polh v jeseni",
             "Vrabček zoblje", "Medvedi in medvedki", "Kons: ABC", "Ekstaza smrti"]
var data = newJArray()
for t in picks:
  let p = poems.filterIt(it.title == t)[0]
  data.add %*{"t": p.title, "c": p.collection, "l": p.lines, "w": words(p.text)}

nbText: """
## The layout explorer

Pick a poem, tap a value, and see the bytes it is made of, in four encodings of the same
column. *Lines* makes a column of the poem's lines (blank lines are nulls); *Words* a
column of its words. *Show bytes* adds the raw bytes under every cell; two-byte letters are
dashed. The two sliders take a **slice**: in Arrow a slice is the same buffers with a different
`offset` and `length`, so nothing is copied, and what is outside it is greyed out.
"""

nbExplorer("""Built from `lib/layout.nim` compiled to JavaScript: the same procs that produced the
buffers above, and that `lib/cdata.nim` hands to pyarrow further down. Try *Bori* in *Words*
with *dictionary*, then *run-end*: the bars at the bottom compare the four sizes.""")

nbText: """
### Four ways to write the same strings

**utf8** is the classic, shown above. Its cousin **large_utf8** (`U`) is the same with int64
offsets, for columns over 2 GB.

**Dictionary encoding** stores each distinct value once, in a little utf8 column (the
*dictionary*), and the column itself becomes integers (the *indices*). Great when values repeat,
like words in poems, or the `kind` column. pandas calls this a *categorical*, Polars a `Categorical`
or `Enum`, R a *factor*. Over all of Kosovel:
"""

nbCode:
  var allWords: seq[string]
  for p in poems: allWords.add words(p.text)
  let plain = utf8Layout(allWords)
  let dict = dictLayout(allWords)
  echo allWords.len, " words, ", dict.children[0].length, " distinct"
  echo "utf8:       ", plain.totalBytes, " bytes"
  echo "dictionary: ", dict.totalBytes, " bytes (", dict.buffers[1].bytes.len, " of indices + ",
    dict.children[0].totalBytes, " of dictionary)"

var freq: CountTable[string]
for w in allWords: freq.inc w
freq.sort
let topWords = toSeq(freq.pairs)[0..11].mapIt(&"*{it[0]}* {it[1]}").join(", ")
var longW = toSeq(freq.keys)
longW.sort(proc (a, b: string): int = cmp(b.runeLen, a.runeLen))
nbText: &"""
Saving bytes is half the story. The other half is that the indices are small integers, so
"group by word" or "how often" is integer work on {allWords.len} int32s, not string comparisons.
The most frequent words in the dictionary are the little ones: {topWords}. The longest is
*{longW[0]}*.

**Run-end encoding** (added in 2023) stores *runs*: each run's value once, and where the run
ends. It shines when the same value repeats in a row, like a column with the title of
the poem next to every word:
"""

nbCode:
  var titlePerWord: seq[string]
  for p in poems:
    for w in words(p.text): titlePerWord.add p.title
  echo titlePerWord.len, " rows"
  echo "utf8:       ", utf8Layout(titlePerWord).totalBytes, " bytes"
  echo "dictionary: ", dictLayout(titlePerWord).totalBytes, " bytes"
  echo "run-end:    ", runEndLayout(titlePerWord).totalBytes, " bytes, ",
    runEndLayout(titlePerWord).children[1].length, " runs"

var inlineW, inlineL, nLines = 0
for w in allWords:
  if w.len <= 12: inc inlineW
for p in poems:
  for ln in p.lines:
    if ln.strip.len > 0:
      inc nLines
      if ln.len <= 12: inc inlineL
nbText: &"""
Kosovel loved repetition (*bori, bori, bori, bori!*), but a poem's words rarely repeat *in a
row*: in the explorer, *Bori* in words makes 80 runs out of 87 words, and run-end costs more
than plain utf8, while the title column above shrinks 67 times. Encodings fit data, not
poets. And to find a row, a run-end reader has to binary-search the run ends:
random access costs log(runs) instead of one lookup.

**String views** (`utf8_view`, also 2023) are the newest, and come from databases: they were
introduced by the Umbra system at TU Munich ("German strings") and adopted by DuckDB, Velox and
Polars. Each value gets a fixed 16-byte *view*: 4 bytes of length, then either the whole string,
if it fits in 12 bytes, or its first 4 bytes, a buffer number and an offset. Short strings never
leave the view, comparisons can often stop at the prefix, and the data buffers can be shared
and appended to in any order. In Kosovel, {100 * inlineW div allWords.len}% of the words fit
in their view, but only {100 * inlineL div nLines}% of the lines.

Arrow has more layouts than strings, all built from the same pieces: fixed-width numbers
(a values buffer and a bitmap), booleans (one bit each), lists (offsets into a child
column), list views, structs (one child per field, so a whole table is a struct column),
unions, maps, decimals, dates, times, timestamps with time zones, durations, intervals, and
*extension types* (a UUID, a tensor, a geometry) that are a storage type plus a name in the
metadata.
"""

var types: seq[tuple[t, code, buffers, use: string]] = @[
  ("Int32, Float64, ...", "`i`, `g`, ...", "validity, values", "numbers, dates, times, timestamps"),
  ("Boolean", "`b`", "validity, bits", "flags, filter masks"),
  ("Utf8 / Binary", "`u` / `z`", "validity, int32 offsets, data", "the classic string"),
  ("LargeUtf8", "`U`", "validity, int64 offsets, data", "columns over 2 GB"),
  ("Utf8View", "`vu`", "validity, 16-byte views, data buffers", "Polars, DuckDB, Velox strings"),
  ("Dictionary", "indices + dictionary", "int indices, and a whole column as dictionary", "categoricals, factors"),
  ("Run-end encoded", "`+r`", "children: run_ends, values", "long runs of the same value"),
  ("List / LargeList", "`+l` / `+L`", "validity, offsets, child column", "a poem as a list of lines"),
  ("ListView", "`+vl`", "validity, offsets, sizes, child", "lists written out of order"),
  ("Struct", "`+s`", "validity, one child per field", "a record; a whole record batch"),
  ("Map, Union", "`+m`, `+us` / `+ud`", "children (and type ids)", "JSON-ish data"),
  ("Extension", "a storage type + metadata", "the storage type's", "UUID, tensors, GeoArrow geometries")]
let typesTable = tabella(types):
  optCssTheme()
  optRowStriping()
  tabHeader "Arrow layouts at a glance", "with their C Data Interface format codes"
  colsLabel {"t": "Type", "code": "Format", "buffers": "Buffers", "use": "For"}
  fmtMarkdown ["code"]
nbTable typesTable

# ------------------------------------------------------------------ the family
let pqSize = getFileSize(here / "data" / "kosovel.parquet")
let ipcSize = getFileSize(here / "data" / "kosovel.arrows")
let jsonSize = getFileSize(here / "data" / "kosovel.json")
nbText: &"""
## The Arrow family

The columnar format is the heart. Around it the project grew a family of specifications,
each one answering "and how do I move it *there*?":

- **The C Data Interface** ([spec]({cdataDocs}), 2020): two C structs, `ArrowSchema` and
  `ArrowArray`, that describe a column and point at its buffers, plus `ArrowArrayStream` for a
  stream of batches. No library needed: anyone who can write a C struct can hand Arrow data
  to anyone else in the same process. Python wraps them in *PyCapsules*
  (`__arrow_c_array__`, `__arrow_c_stream__`), so pyarrow, Polars, DuckDB, pandas and friends
  swap tables without knowing about each other. There is a **C Device** variant for GPU memory.
- **IPC**: the same buffers, written to a file or a socket, with a little
  [FlatBuffers](https://flatbuffers.dev/) metadata in front. Reading it back is mostly a memory
  map, no parsing. The *file* format (with a footer, for random access to batches) is also known
  as **Feather** (v2); the *stream* format is what this page loaded the poems from.
- **Flight**: Arrow over the network, on gRPC: streams of record batches, in parallel, between
  services. **Flight SQL** puts a SQL database behind it.
- **ADBC** (Arrow Database Connectivity): a database API like JDBC or ODBC, but results come
  back as Arrow. Drivers for PostgreSQL, SQLite, Snowflake, BigQuery, Flight SQL, DuckDB...
- **Implementations**: official libraries in C (nanoarrow, GLib), C++, C#, Go, Java, JavaScript,
  Julia, MATLAB, Python (pyarrow), R, Ruby and Rust (arrow-rs), with readers, writers and
  compute functions (C++ even has a query engine, Acero).

### And Parquet?

[Apache Parquet](https://parquet.apache.org/) is Arrow's sibling on disk, and they were born
together (some of Parquet's founders were in the room when Arrow was designed). Parquet is for
**storing**: columns split into pages, encoded (dictionary, run-length, delta, bit packing) and
compressed, with statistics for skipping. Arrow is for **working**: uncompressed (or lightly),
fixed layouts, random access, ready for the CPU. The typical life of data is Parquet on disk,
Arrow in memory. Most Parquet implementations now live inside the Arrow repositories (C++,
Rust, Go). For Kosovel:
"""

var sizes: seq[tuple[f, bytes, what: string]] = @[
  ("kosovel.parquet", $pqSize, "zstd-compressed, dictionary and RLE encoded: to store and ship"),
  ("kosovel.arrows", $ipcSize, "Arrow IPC stream: the memory layout itself, to load"),
  ("kosovel.json", $jsonSize, "text: one object per poem, for the explorer in your browser")]
let sizesTable = tabella(sizes):
  optCssTheme()
  optRowStriping()
  tabHeader "The same 509 texts, three files"
  colsLabel {"f": "File", "bytes": "Bytes", "what": "What for"}
  fmtMarkdown ["f"]
nbTable sizesTable

# ------------------------------------------------------------------ ecosystem
nbText: """
## Who speaks Arrow

The short answer is most of the modern data world. Arrow is rarely the engine itself; it is
the shared memory format at the borders, and, more and more, the memory format inside.
"""

var eco: seq[tuple[name, what, arrow: string]] = @[
  ("pyarrow", "Arrow C++ for Python", "the reference toolkit: Parquet, CSV, datasets, compute, Flight"),
  ("pandas", "Python dataframes", "Arrow-backed dtypes since 2.0; pandas 3 strings use pyarrow when installed"),
  ("Polars", "Rust/Python dataframes", "its memory *is* Arrow (its own polars-arrow crate); strings are views"),
  ("DuckDB", "in-process SQL", "own vectors inside; scans Arrow in place, returns Arrow, speaks ADBC"),
  ("DataFusion", "Rust query engine", "built on arrow-rs; began in Arrow, an Apache top-level project since 2024"),
  ("arrow-rs, arrow-go, arrow-java, Arrow JS", "native Arrows", "full implementations, released on their own"),
  ("nanoarrow", "small C library", "a few C files to vendor: build, read, validate arrays, IPC"),
  ("R arrow, nanoarrow for R", "R", "dplyr on Arrow datasets, zero-copy with DuckDB"),
  ("Spark", "cluster computing", "Arrow to move data to Python (pandas UDFs, toPandas)"),
  ("Velox, cuDF", "engines (Meta; NVIDIA RAPIDS)", "Arrow-compatible layouts, on CPU and on GPU"),
  ("GeoArrow", "geospatial", "geometries as Arrow extension types"),
  ("Lance, Vortex", "new file formats", "columnar files designed around Arrow in memory"),
  ("ADBC drivers, BigQuery, Snowflake", "databases and warehouses", "results delivered as Arrow batches")]
let ecoTable = tabella(eco):
  optCssTheme()
  optRowStriping()
  tabHeader "Arrow around the data world", "a partial map, November 2026"
  colsLabel {"name": "Project", "what": "What", "arrow": "What Arrow is to it"}
  fmtMarkdown ["arrow"]
nbTable ecoTable

# ------------------------------------------------------------------ people
nbText: &"""
## The people

Arrow is an [Apache Software Foundation](https://www.apache.org/) project, so it is run by
its community, not by a company. Contributors who keep showing up become **committers**
(they can merge); some committers join the **PMC**, the Project Management Committee that
votes on releases and new members; one PMC member is the project's **VP**, its contact with
the foundation. Arrow has no roadmap: decisions are by consensus on the mailing list, and
format changes need a vote and two implementations that pass the integration tests.

A short history:

- **2016**: the project starts (first commit 5 February), co-created by people from many data
  projects, among them Wes McKinney (pandas) and Jacques Nadeau (Dremio), with founders of
  Parquet such as Julien Le Dem. 0.1.0 comes out in October, with C++ and Java.
- **2020**: version 1.0.0, and formal stability promises. The C Data Interface is added.
  Since then, the format has had one breaking change (unions lost their validity bitmap,
  in 2020) and nothing since: new types are additions.
- **2023**: string views, list views, run-end encoding.
- **2024**: DataFusion graduates to its own top-level project.
- **2025**: Voltron Data, which had employed many core developers, winds down; the community
  moves its benchmarking and nightly infrastructure to Arrow's own accounts. The first
  **Arrow Summit** is held in Paris in October.
- **2026**: ten years old in February. Version 26.0.1 in November; nanoarrow 0.9, ADBC 25,
  arrow-rs 60, arrow-go 18.9, arrow-java 20 along the way.

The [committer list]({committers}) has {62} PMC members (with the VP, Antoine Pitrou) and {59}
more committers.
"""

nbNote(nkPeople, """
**Raúl Cumplido** (`raulcd`, QuantStack) has been on the PMC since early 2024. He is one of the
people who make Arrow ship: release management, packaging and CI across a huge matrix of
platforms. The project's 2025 review thanks him and `kou` (Sutou Kouhei) for "devoting countless
hours so that everything runs smoothly", credits him with moving many compute kernels into
an optional package (a smaller Arrow C++ when you don't need them), and with organizing Arrow
Summit 25 in Paris with Antoine Pitrou.

**Rok Mihevc** (`rok`) became a committer in 2022 and joined the PMC in 2025. When Voltron Data
wound down, he drove the migration of Arrow's benchmarking infrastructure and nightly reports
to an Arrow-managed AWS account (and moved arrow-go's benchmarks over too).

Rok is not the only Slovenian name on the list: **Alenka Frim** is on the PMC, and **Tadeja Kadunc** became a committer in October 2026. For a format so careful
about *č*, it seems fair.
""")

# ------------------------------------------------------------------ Arrow in Nim
nbText: &"""
## Arrow in Nim

Nim's Arrow story was mapped in November 2026 by
[*What about Arrow?*]({whatAboutArrow}), on the Nanuq blog: who in Nim already speaks Arrow, and
five scenarios for what a shared Arrow layer could change. In short:
"""

var nimLibs: seq[tuple[name, how, state: string]] = @[
  ("[narrow](https://github.com/BontaVlad/narrow)", "wraps Arrow C++ through its GLib C API: arrays, tables, compute, Acero, Parquet, CSV, IPC, datasets", "active (last commit August 2026), 0.0.1; needs libarrow-glib ≥ 24"),
  ("[NimDrake](https://github.com/BontaVlad/NimDrake)", "DuckDB bindings, Arrow export through narrow", "pre-alpha"),
  ("[nimarrow](https://github.com/emef/nimarrow), [nimarrow_glib](https://github.com/emef/nimarrow_glib)", "the first GLib bindings: arrays, tables, Parquet", "last commit July 2021"),
  ("[Nanuq](https://github.com/pietroppeter/nanuq)", "Polars for Nim; C Data Interface both ways, zero-copy views", "0.6.1, active"),
  ("[duckdb-nim](https://github.com/nimbase/duckdb-nim)", "DuckDB bindings, including DuckDB's Arrow C API", "active (October 2026)"),
  ("this page: `cdata.nim` + nanoarrow", "pure-Nim C Data Interface with builders; nanoarrow compiled in for IPC", "a sketch, below")]
let nimTable = tabella(nimLibs):
  optCssTheme()
  optRowStriping()
  tabHeader "Arrow in Nim", "November 2026"
  colsLabel {"name": "Project", "how": "What it does", "state": "State"}
  fmtMarkdown ["name", "how", "state"]
nbTable nimTable

nbText: """
The post's scenario 1 is "one shared package for the C Data Interface": the structs, their
release rules, typed readers, pure Nim, no dependencies. Scenario 2 adds **builders**, Arrow
arrays written from Nim with a release callback that frees Nim memory. This page carries a
small sketch of both, `lib/cdata.nim`, about 200 lines. The structs are the spec's, checked
at compile time:
"""

nbFile "lib/cdata.nim", start = "type\n  ReleaseSchema*", stop = "const arrowFlagNullable*",
  title = "`lib/cdata.nim`: the two structs"

nbText: """
A `Column` holds its buffers as Nim seqs. `exportTo` fills two structs owned by the caller with
pointers into them, and keeps the column alive (a `GC_ref`) until the consumer calls
`release`. Nothing is copied. To prove it works with real consumers, `poc/libkosovel.nim`
builds a shared library around it, and a 30-line Python script loads it with `ctypes` and hands
the record batch to pyarrow, Polars and DuckDB. This ran when the page was built, on the words
of *Bori*:
"""

# build the bridge and run it, for real
let soPath = scratch / "libkosovel.so"
block:
  let (o, code) = execCmdEx("nim c --app:lib -d:release --hints:off --warnings:off -o:" & quoteShell(soPath) & " " &
                            quoteShell(here / "poc" / "libkosovel.nim"))
  doAssert code == 0, o
let wordsFile = scratch / "bori.txt"
writeFile(wordsFile, words(bori.text).join("\n"))
let (bridgeOut, bridgeCode) = execCmdEx("python3 " & quoteShell(here / "poc" / "bridge.py") & " " &
                                        quoteShell(soPath) & " " & quoteShell(wordsFile))
doAssert bridgeCode == 0, bridgeOut

nbFile "poc/libkosovel.nim", title = "`poc/libkosovel.nim`: Nim exports a record batch, and reads pyarrow's"
nbText: "```python\n" & readFile(here / "poc" / "bridge.py").strip & "\n```"
nbHtml "<pre class=\"nb-output\">" & escHtml(bridgeOut.strip) & "</pre>"

nbText: """
Four things to notice. pyarrow's `validate(full=True)` accepted every buffer Nim made,
including the views and the run-end column. Polars refused the run-end column (*"+r" is still
not supported*): every consumer implements a subset of the types, and the newest ones arrive
last. DuckDB took it. And the last line goes the other way: pyarrow exports a column, and Nim
reads its UTF-8 in place to count *č*, *š*, *ž* (there are three, in Srečko, Sežana and žalost).

### nanoarrow, compiled in

For everything beyond the C Data Interface (reading IPC files, validating arrays, streams)
there is no need for a system library either. [nanoarrow]({nanoarrowUrl}) ships as a few
C files, and Nim can compile C files right into a program with `{.compile.}`.
`lib/nanoarrow.nim` does that, declares the handful of functions it needs, and gives an
iterator over the record batches of an IPC stream. That is how this page read the poems at the
top: nanoarrow parsed the file, and handed each batch back as the same `ArrowArray` struct
`cdata.nim` knows, so `utf8Values` read the strings straight out of nanoarrow's buffers.
"""

nbFile "lib/nanoarrow.nim", start = "const puscicaDeps", title = "`lib/nanoarrow.nim`: nanoarrow 0.9 inside a Nim program"

nbCode:
  echo "nanoarrow ", ArrowNanoarrowVersion()
  var sch: ArrowSchema
  for batch in ipcBatches(here / "data" / "kosovel.arrows", sch):
    echo batch.length, " rows: ", sch.addr
    break

nbNote(nkNim, &"""
Vendoring nanoarrow is a middle road between the post's scenarios: no system dependency (unlike
the GLib route), a few C files that any Nim package can carry, the spec's own validation and
IPC for free, and Nim on top. A Nim Arrow package could start as pure-Nim structs and builders
(`cdata.nim`) with nanoarrow behind an import, for the parts where writing Nim would only redo
nanoarrow's work.
""")

# ------------------------------------------------------------------ Kosovel
nbText: &"""
## Back to Kosovel

Srečko Kosovel was born in Sežana in 1904 and grew up in Tomaj, on the Karst, and studied in
Ljubljana, where he edited student magazines, organized readings, and wrote at a furious pace.
He died of meningitis in 1926, at 22. Little was published in his lifetime: the first book of
his poems came out in 1927, the constructivist *Integrali '26* only in 1967, and with them he
became one of the great European avant-garde poets.

He moves from impressionist Karst landscapes (the pines, the bora wind, the juniper) to
expressionist visions of a dying Europe (*Ekstaza smrti*) and to the konsi: poems as
constructions of words, numbers, signs and typography, close to the constructivists of
Moscow and the artists in Trieste around Avgust Černigoj. He also wrote for children, which is
why the looks of this page come from Slovenian picture books: *Naša bela mačica* (our white
kitten), the bear cubs, the sparrow and the dormouse are all in the explorer's list.
"""

nbPoem("Iz zapisov", """Rad bi povedal ljudem lepo, dobro besedo, svetlo besedo, kakor je svetlo novembrsko sonce na Krasu.
Toda moja beseda je težka in molčeča, grenka kakor je brinova jagoda s Krasa.""",
  "Srečko Kosovel, from *Pesmi* (1927), quoted on the Slovenian Wikipedia. *I would like to tell people a beautiful, good word, a bright word, as bright as the November sun on the Karst. But my word is heavy and silent, bitter as a juniper berry from the Karst.*")

nbText: """
## Glossary, for the next conversation with an Arrow committer

- **Array / column**: one typed column, a few buffers. **Chunked array**: a column made of
  several arrays. **Record batch**: equal-length arrays with a schema (a struct column).
  **Table**: a schema and chunked arrays.
- **Schema / field**: names, types, nullability, key-value metadata.
- **Validity bitmap**: one bit per value, LSB first; absent when nothing is null.
- **Offsets**: where variable-length values start; int32 (`utf8`, `list`) or int64 (`large_*`).
- **Views**: 16 bytes per value: length, prefix or inline bytes, buffer index, offset.
- **Dictionary, run-end encoding**: repeated values stored once, as indices or as runs.
- **Zero-copy**: handing over pointers to the same buffers, never converting.
- **Slice**: same buffers, a different offset and length.
- **C Data Interface / C Stream / C Device**: the structs for passing arrays, streams, and GPU arrays.
- **IPC / Feather**: the in-memory layout, framed for files and sockets.
- **Flight / Flight SQL / ADBC**: over the network, and the database API.
- **Extension type**: a storage type plus a name (`arrow.uuid`, `arrow.fixed_shape_tensor`, GeoArrow).
- **Canonical extension**: an extension type the project itself standardised.
- **PMC, committer, VP**: the Apache way of running a project.
"""

nbText: &"""
## How this page is made

A [nimib](https://github.com/pietroppeter/nimib) document. The poems come from the Slovenian
Wikisource dump (`data/make_dataset.py`, with pyarrow), and are loaded by the page through
nanoarrow (`lib/nanoarrow.nim`, `lib/corpus.nim`). The buffers in the code blocks and in the
explorer come from one module, `lib/layout.nim`, compiled with the page and again to
JavaScript (`lib/widgets.nim`); `lib/cdata.nim` turns them into C Data Interface structs for
the bridge to pyarrow, Polars and DuckDB, which ran while the page was built. Tables are made with
[tabelline](https://pietroppeter.github.io/tabelline/). The six looks are CSS only
(`lib/style.nim`), after the palettes of Jelka Reichman, Marlenka Stupica, Lila Prap, Maksim
Gaspari, Marjan Manček and Avgust Černigoj, without any of their pictures. The sources are
[on GitHub]({srcDir}).
"""

for f in ["lib/layout.nim", "lib/cdata.nim", "lib/corpus.nim", "lib/widgets.nim", "data/make_dataset.py",
          "index.nim", "lib/blocks.nim", "lib/style.nim", "config.nims", "deps.sh"]:
  nbFile f, folded = true

nbScript "const KOSOVEL = " & $data & ";"
nbScript compileWidgets(here / "lib" / "widgets.nim", scratch)

nbSave
