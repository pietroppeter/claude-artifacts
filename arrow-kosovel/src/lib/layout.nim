## How Arrow lays out a column of strings, byte by byte: the buffers of each encoding, and,
## for every byte, which value it belongs to. Pure Nim (no pointers), so the same procs run
## when the page is built (the code blocks, cdata.nim's exports) and in your browser
## (the layout explorer, widgets.nim compiled with `nim js`).

import std/tables

type
  Encoding* = enum
    encUtf8 = "utf8"            ## offsets + data
    encView = "string view"     ## 16-byte views, short strings inline
    encDict = "dictionary"      ## int32 indices + a utf8 dictionary
    encRunEnd = "run-end"       ## run ends + a utf8 column of the run values

  Buf* = object
    name*: string
    bytes*: seq[int]       ## 0..255 (ints, so JS has no trouble)
    width*: int            ## how many bytes make one slot: 1 (bits, data), 4 (offsets), 16 (views)
    owner*: seq[int]       ## for each byte, the value (row) it belongs to; -1 none, -2 padding
    text*: bool            ## data bytes: show them as text, too

  Layout* = object
    encoding*: Encoding
    length*, nullCount*: int
    format*: string        ## the C Data Interface format string
    buffers*: seq[Buf]     ## in the order the spec gives them
    children*: seq[Layout] ## run-end: run_ends, values. dictionary: the dictionary
    childNames*: seq[string]
    note*: string          ## one line on what is going on
    childIndex*: seq[int]  ## for each row, its entry in the children (dictionary entry, or run)

proc le32(b: var seq[int]; v: int) =
  for k in 0..3: b.add (v shr (8 * k)) and 0xff
proc le64(b: var seq[int]; v: int) =
  for k in 0..7: b.add (if k < 4: (v shr (8 * k)) and 0xff else: 0)

proc validity(valid: openArray[bool]): Buf =
  ## One bit per value, least significant bit first. Absent when there are no nulls.
  result = Buf(name: "validity", width: 1)
  var nulls = 0
  for v in valid:
    if not v: inc nulls
  if nulls == 0: return
  result.bytes = newSeq[int]((valid.len + 7) div 8)
  result.owner = newSeq[int](result.bytes.len)
  for i, v in valid:
    if v: result.bytes[i div 8] = result.bytes[i div 8] or (1 shl (i mod 8))
  for i in 0 ..< result.bytes.len: result.owner[i] = -1

proc utf8Layout*(values: openArray[string]; valid: openArray[bool] = []): Layout =
  ## Offsets (length + 1 int32) into a single buffer holding every string's bytes, end to end.
  result = Layout(encoding: encUtf8, length: values.len, format: "u")
  var ok = newSeq[bool](values.len)
  for i in 0 ..< values.len: ok[i] = valid.len == 0 or valid[i]
  for v in ok:
    if not v: inc result.nullCount
  var offs = Buf(name: "offsets", width: 4)
  var data = Buf(name: "data", width: 1, text: true)
  offs.bytes.le32 0
  for k in 0..3: offs.owner.add -1
  for i, v in values:
    if ok[i]:
      for c in v:
        data.bytes.add ord(c)
        data.owner.add i
    offs.bytes.le32 data.bytes.len
    for k in 0..3: offs.owner.add i         # offset i+1 is where value i ends
  result.buffers = @[validity(ok), offs, data]
  result.note = "value i is data[offsets[i] ..< offsets[i+1]]"

proc viewLayout*(values: openArray[string]; valid: openArray[bool] = []): Layout =
  ## One 16-byte view per value: length (4 bytes), then either the string itself (up to 12
  ## bytes, padded with zeros) or a 4-byte prefix, a buffer index and an offset.
  result = Layout(encoding: encView, length: values.len, format: "vu")
  var ok = newSeq[bool](values.len)
  for i in 0 ..< values.len: ok[i] = valid.len == 0 or valid[i]
  for v in ok:
    if not v: inc result.nullCount
  var views = Buf(name: "views", width: 16)
  var data = Buf(name: "data 0", width: 1, text: true)
  var inline = 0
  for i, v0 in values:
    let v = if ok[i]: v0 else: ""
    views.bytes.le32 v.len
    if v.len <= 12:
      inc inline
      for k in 0 ..< 12: views.bytes.add(if k < v.len: ord(v[k]) else: 0)
    else:
      for k in 0 ..< 4: views.bytes.add ord(v[k])
      views.bytes.le32 0
      views.bytes.le32 data.bytes.len
      for c in v:
        data.bytes.add ord(c)
        data.owner.add i
    for k in 0 ..< 16: views.owner.add i
  var sizes = Buf(name: "sizes", width: 8)
  sizes.bytes.le64 data.bytes.len
  for k in 0 ..< 8: sizes.owner.add -1
  result.buffers = @[validity(ok), views, data, sizes]
  result.note = $inline & " of " & $values.len & " values fit inside their view (12 bytes or less)"

proc dictLayout*(values: openArray[string]): Layout =
  ## Every distinct value once, in a utf8 dictionary; the column itself is int32 indices.
  var dict: seq[string]
  var seen = initTable[string, int]()
  var idx = Buf(name: "indices", width: 4)
  for i, v in values:
    let k = seen.mgetOrPut(v, dict.len)
    if k == dict.len: dict.add v
    idx.bytes.le32 k
    for j in 0..3: idx.owner.add i
    result.childIndex.add k
  result = Layout(encoding: encDict, length: values.len, format: "i",
                  buffers: @[Buf(name: "validity", width: 1), idx],
                  children: @[utf8Layout(dict)], childNames: @["dictionary"],
                  childIndex: result.childIndex)
  result.note = $values.len & " values, " & $dict.len & " distinct"

proc runEndLayout*(values: openArray[string]): Layout =
  ## Runs of equal neighbours: where each run ends (int32), and each run's value (utf8).
  var ends = Buf(name: "run_ends", width: 4)
  var vals: seq[string]
  var runOf: seq[int]
  for i, v in values:
    if vals.len > 0 and vals[^1] == v:
      ends.bytes.setLen ends.bytes.len - 4
      ends.owner.setLen ends.owner.len - 4
    else:
      vals.add v
    ends.bytes.le32 i + 1
    for j in 0..3: ends.owner.add vals.len - 1
    runOf.add vals.len - 1
  result = Layout(childIndex: runOf, encoding: encRunEnd, length: values.len, format: "+r",
                  children: @[Layout(encoding: encUtf8, length: vals.len, format: "i", buffers: @[Buf(name: "validity", width: 1), ends]),
                              utf8Layout(vals)],
                  childNames: @["run_ends", "values"])
  result.note = $values.len & " values in " & $vals.len & " runs"

proc layout*(e: Encoding; values: openArray[string]; valid: openArray[bool] = []): Layout =
  case e
  of encUtf8: utf8Layout(values, valid)
  of encView: viewLayout(values, valid)
  of encDict: dictLayout(values)
  of encRunEnd: runEndLayout(values)

proc totalBytes*(l: Layout): int =
  for b in l.buffers: result += b.bytes.len
  for c in l.children: result += c.totalBytes

