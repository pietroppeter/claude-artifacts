## The Arrow C Data Interface, in plain Nim: two C structs, and a way to fill them.
##
## The whole point of the C Data Interface is that it needs no library: any language that can
## lay out a C struct can hand Arrow data to pyarrow, Polars, DuckDB, R, nanoarrow... without
## copying a byte. This module is that idea in Nim, with no dependency: it builds Arrow
## columns (validity bitmap, offsets, data, dictionary, run ends, string views), exports them
## as `ArrowSchema` / `ArrowArray`, and reads such structs produced by others.
##
## Spec: https://arrow.apache.org/docs/format/CDataInterface.html
import std/[strutils, unicode]
import layout
export layout

type
  ReleaseSchema* = proc (s: ptr ArrowSchema) {.cdecl, gcsafe, raises: [].}
  ReleaseArray* = proc (a: ptr ArrowArray) {.cdecl, gcsafe, raises: [].}

  ArrowSchema* {.bycopy.} = object
    ## The type of a column (72 bytes on 64-bit, as in the spec's C header).
    format*: cstring            ## "u" utf8, "i" int32, "l" int64, "vu" string view, "+s" struct...
    name*: cstring
    metadata*: cstring
    flags*: int64               ## 2 = nullable
    nChildren*: int64
    children*: ptr UncheckedArray[ptr ArrowSchema]
    dictionary*: ptr ArrowSchema
    release*: ReleaseSchema
    privateData*: pointer

  ArrowArray* {.bycopy.} = object
    ## The data of a column (80 bytes): a length, some buffers, maybe children.
    length*, nullCount*, offset*, nBuffers*, nChildren*: int64
    buffers*: ptr UncheckedArray[pointer]
    children*: ptr UncheckedArray[ptr ArrowArray]
    dictionary*: ptr ArrowArray
    release*: ReleaseArray
    privateData*: pointer

const arrowFlagNullable* = 2'i64

static:
  doAssert sizeof(ArrowSchema) == 72 and sizeof(ArrowArray) == 80

# ------------------------------------------------------------------ columns, in Nim

type
  Buffer* = seq[byte]

  Column* = ref object
    ## An Arrow array as plain Nim data: what the C structs will point into.
    name*: string
    format*: string
    length*, nullCount*: int
    buffers*: seq[Buffer]         ## buffers[0] is always the validity bitmap (may be empty)
    children*: seq[Column]
    dictionary*: Column
    # what the exported C structs point to, kept alive with the column
    cFormat, cName: string
    bufPtrs: seq[pointer]
    childSchemas: seq[ArrowSchema]       ## the children's structs live here, freed with the column
    childArrays: seq[ArrowArray]
    childSchemaPtrs: seq[ptr ArrowSchema]
    childArrayPtrs: seq[ptr ArrowArray]
    dictStructs: seq[(ArrowSchema, ArrowArray)]

proc bitmap*(valid: openArray[bool]): Buffer =
  ## The validity bitmap: one bit per value, least significant bit first, 1 = present.
  result = newSeq[byte]((valid.len + 7) div 8)
  for i, v in valid:
    if v: result[i div 8] = result[i div 8] or byte(1 shl (i mod 8))

proc isValid*(bm: Buffer; i: int): bool =
  bm.len == 0 or (bm[i div 8] and byte(1 shl (i mod 8))) != 0

proc put32*(b: var Buffer; v: int32) =
  for k in 0..3: b.add byte((v shr (8 * k)) and 0xff)
proc put64*(b: var Buffer; v: int64) =
  for k in 0..7: b.add byte((v shr (8 * k)) and 0xff)
proc get32*(b: Buffer; i: int): int32 =
  for k in 0..3: result = result or (int32(b[4 * i + k]) shl (8 * k))

proc toBuffer(b: Buf): Buffer =
  for x in b.bytes: result.add byte(x)

proc fromLayout*(name: string; l: Layout): Column =
  ## The buffers layout.nim computed (the same the layout explorer shows), as a Column.
  result = Column(name: name, format: l.format, length: l.length, nullCount: l.nullCount)
  for b in l.buffers: result.buffers.add b.toBuffer
  case l.encoding
  of encDict: result.dictionary = fromLayout("", l.children[0])
  of encRunEnd:
    result.children = @[fromLayout("run_ends", l.children[0]), fromLayout("values", l.children[1])]
  else: discard

proc utf8Column*(name: string; values: openArray[string]; valid: openArray[bool] = []): Column =
  ## A `utf8` ("u") column: offsets (n+1 int32) into one buffer of all the bytes.
  ## A null is an empty slot (two equal offsets) with its validity bit off.
  fromLayout(name, utf8Layout(values, valid))

proc stringViewColumn*(name: string; values: openArray[string]; valid: openArray[bool] = []): Column =
  ## A string view ("vu") column: one 16-byte view per value. Up to 12 bytes the string sits
  ## inside the view itself; longer ones keep a 4-byte prefix and point into a data buffer.
  ## Buffers: validity, views, data buffer(s), and last an int64 per data buffer, its size.
  fromLayout(name, viewLayout(values, valid))

proc dictColumn*(name: string; values: openArray[string]): Column =
  ## Dictionary encoding: each distinct value once (the dictionary, a utf8 column) and an
  ## int32 index per row. The C struct says "i" (the indices) with a dictionary attached.
  fromLayout(name, dictLayout(values))

proc runEndColumn*(name: string; values: openArray[string]): Column =
  ## Run-end encoding ("+r"): no buffers, two children: where each run ends (int32) and its value.
  fromLayout(name, runEndLayout(values))

proc int32Column*(name: string; values: openArray[int32]; valid: openArray[bool] = []): Column =
  result = Column(name: name, format: "i", length: values.len)
  var data: Buffer
  for i, v in values:
    data.put32 v
    if valid.len > 0 and not valid[i]: inc result.nullCount
  result.buffers = @[(if result.nullCount > 0: bitmap(valid) else: @[]), data]

proc structColumn*(name: string; children: openArray[Column]): Column =
  ## A struct ("+s"): a row of named children of the same length. A record batch is one.
  result = Column(name: name, format: "+s", length: children[0].length, buffers: @[@[]],
                  children: @children)

# ------------------------------------------------------------------ export to C

proc releaseSchema(s: ptr ArrowSchema) {.cdecl, gcsafe, raises: [].} =
  ## Called by the consumer when done: drop our reference to the column.
  if s.privateData != nil:
    GC_unref cast[Column](s.privateData)
  s.release = nil

proc releaseArray(a: ptr ArrowArray) {.cdecl, gcsafe, raises: [].} =
  if a.privateData != nil:
    GC_unref cast[Column](a.privateData)
  a.release = nil

proc releaseChildSchema(s: ptr ArrowSchema) {.cdecl, gcsafe, raises: [].} = s.release = nil
proc releaseChildArray(a: ptr ArrowArray) {.cdecl, gcsafe, raises: [].} = a.release = nil

proc fill(c: Column; s: ptr ArrowSchema; a: ptr ArrowArray; top: bool) =
  c.cFormat = c.format
  c.cName = c.name
  s[] = ArrowSchema(format: cstring(c.cFormat), name: cstring(c.cName), flags: arrowFlagNullable,
                    nChildren: int64(c.children.len))
  c.bufPtrs.setLen 0
  for b in c.buffers:
    c.bufPtrs.add(if b.len == 0: nil else: b[0].unsafeAddr)
  a[] = ArrowArray(length: int64(c.length), nullCount: int64(c.nullCount),
                   nBuffers: int64(c.buffers.len), nChildren: int64(c.children.len))
  if c.bufPtrs.len > 0: a.buffers = cast[ptr UncheckedArray[pointer]](c.bufPtrs[0].addr)
  if c.children.len > 0:
    c.childSchemas = newSeq[ArrowSchema](c.children.len)
    c.childArrays = newSeq[ArrowArray](c.children.len)
    c.childSchemaPtrs.setLen 0
    c.childArrayPtrs.setLen 0
    for i, ch in c.children:
      ch.fill(c.childSchemas[i].addr, c.childArrays[i].addr, top = false)
      c.childSchemaPtrs.add c.childSchemas[i].addr
      c.childArrayPtrs.add c.childArrays[i].addr
    s.children = cast[ptr UncheckedArray[ptr ArrowSchema]](c.childSchemaPtrs[0].addr)
    a.children = cast[ptr UncheckedArray[ptr ArrowArray]](c.childArrayPtrs[0].addr)
  if c.dictionary != nil:
    c.dictStructs = newSeq[(ArrowSchema, ArrowArray)](1)
    c.dictionary.fill(c.dictStructs[0][0].addr, c.dictStructs[0][1].addr, top = false)
    s.dictionary = c.dictStructs[0][0].addr
    a.dictionary = c.dictStructs[0][1].addr
  if top:
    GC_ref c; GC_ref c          # one reference for the schema, one for the array
    s.privateData = cast[pointer](c)
    a.privateData = cast[pointer](c)
    s.release = releaseSchema
    a.release = releaseArray
  else:
    s.release = releaseChildSchema
    a.release = releaseChildArray

proc exportTo*(c: Column; s: ptr ArrowSchema; a: ptr ArrowArray) =
  ## Fill two caller-owned structs. No byte of data is copied: the buffers stay where they are
  ## (in this Nim column) until the consumer calls `release`.
  c.fill(s, a, top = true)

# ------------------------------------------------------------------ import from C

proc bytesAt(p: pointer; i: int): char {.inline.} = cast[ptr UncheckedArray[char]](p)[i]

proc utf8Values*(s: ptr ArrowSchema; a: ptr ArrowArray): seq[string] =
  ## Read a utf8 column someone else made (pyarrow, Polars...), straight from their memory.
  doAssert $s.format == "u", "expected utf8, got " & $s.format
  let valid = cast[ptr UncheckedArray[byte]](a.buffers[0])
  let offs = cast[ptr UncheckedArray[int32]](a.buffers[1])
  let data = a.buffers[2]
  for j in 0 ..< int(a.length):
    let i = j + int(a.offset)
    if valid != nil and (valid[i div 8] and byte(1 shl (i mod 8))) == 0:
      result.add ""
      continue
    var w = newString(offs[i + 1] - offs[i])
    for k in 0 ..< w.len: w[k] = data.bytesAt(offs[i] + k)
    result.add w

# ------------------------------------------------------------------ looking at buffers

proc hexBytes*(b: Buffer; maxBytes = 48): string =
  for i, x in b:
    if i >= maxBytes:
      result.add "…"
      break
    result.add toHex(x, 2).toLowerAscii & " "

proc offsetsOf*(c: Column): seq[int32] =
  for i in 0 .. c.length: result.add c.buffers[1].get32(i)

proc runeCount*(s: string): int = unicode.runeLen(s)
